# encoding: UTF-8

require "redic"
require "securerandom"

module Stal
  ALIASES = {
    :diff        => "SDIFFSTORE",
    :inter       => "SINTERSTORE",
    :union       => "SUNIONSTORE",
  }

  def self.tr(term)
    ALIASES.fetch(term, term)
  end

  def self.compute(expr, ids, acc)
    id = sprintf("stal:%s", SecureRandom.uuid)

    # Keys we need to clean up later
    ids.push(id)

    # Add command with destination key
    cmd = [tr(expr[0]), id]

    expr[1..-1].each do |item|
      if Array === item
        cmd.push(compute(item, ids, acc))
      else
        cmd.push(item)
      end
    end

    acc.push(cmd)

    return id
  end

  def self.compile(expr)

    # Commands to process
    acc = []

    # Keys to cleanup
    ids = []

    id = compute(expr, ids, acc)

    acc.push([:SMEMBERS, id])
    acc.push([:DEL, *ids])
    acc
  end

  # Evaluate expression `expr` in the Redis client `c`.
  def self.solve(c, expr)
    operations = compile(expr)

    c.queue("MULTI")

    operations.each do |op|
      c.queue(*op)
    end

    c.queue("EXEC")

    # Return the result of SMEMBERS
    c.commit[-1][-2]
  end
end
