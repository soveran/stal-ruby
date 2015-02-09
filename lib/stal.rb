# encoding: UTF-8

require "redic"

module Stal
  class InvalidCommand < ArgumentError; end

  COMMANDS = {
    :SDIFF  => 'SDIFFSTORE',
    :SINTER => 'SINTERSTORE',
    :SUNION => 'SUNIONSTORE',
  }

  def self.command(term)
    COMMANDS.fetch(term) do
      raise(InvalidCommand, term)
    end
  end

  # Compile expression into Redis commands
  def self.compile(expr, ids, ops)
    expr.map do |item|
      if Array === item
        convert(item, ids, ops)
      else
        item
      end
    end
  end

  # Transform :SDIFF, :SINTER and :SUNION commands
  # into SDIFFSTORE, SINTERSTORE and SUNIONSTORE.
  def self.convert(expr, ids, ops)
    head, *tail = expr

    # Key where partial results will be stored
    id = sprintf("stal:%s", ids.size)

    # Keep a reference to clean it up later
    ids.push(id)

    # Translate into command and destination key
    op = [command(head), id]

    # Compile the rest recursively
    op.concat(compile(tail, ids, ops))

    # Append the outermost operation
    ops.push(op)

    return id
  end

  # Return commands without any wrapping added by `solve`
  def self.explain(expr)
    ids = []
    ops = []

    ops.push(compile(expr, ids, ops))

    return ops
  end

  # Evaluate expression `expr` in the Redis client `c`.
  def self.solve(c, expr)
    ids = []
    ops = []

    ops.push(compile(expr, ids, ops))

    if ops.one?
      c.call(*ops[0])
    else
      c.queue("MULTI")

      ops.each do |op|
        c.queue(*op)
      end

      c.queue("DEL", *ids)
      c.queue("EXEC")
      c.commit[-1][-2]
    end
  end
end
