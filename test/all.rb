require_relative "helper"

setup do
  Redic.new.tap do |c|
    c.call("FLUSHDB")
    c.call("SADD", "foo", "a", "b", "c")
    c.call("SADD", "bar", "b", "c", "d")
    c.call("SADD", "baz", "c", "d", "e")
    c.call("SADD", "qux", "x", "y", "z")
  end
end

test do |c|

  # Example expression
  expr = ["SUNION", "qux", [:SDIFF, [:SINTER, "foo", "bar"], "baz"]]

  assert_equal ["b", "x", "y", "z"], Stal.solve(c, expr).sort

  # Commands in sub expressions must be symbols
  expr = ["SUNION", "qux", ["SDIFF", ["SINTER", "foo", "bar"], "baz"]]

  assert_raise(Stal::InvalidCommand) do
    Stal.solve(c, expr)
  end

  # Commands without sub expressions also work
  expr = ["SINTER", "foo", "bar"]

  assert_equal ["b", "c"], Stal.solve(c, expr).sort

  # Only :SUNION, :SDIFF and :SINTER are supported in sub expressions
  expr = ["SUNION", ["DEL", "foo"]]

  assert_raise(Stal::InvalidCommand) do
    Stal.solve(c, expr)
  end

  # Verify there's no keyspace pollution
  assert_equal ["bar", "baz", "foo", "qux"], c.call("KEYS", "*").sort

  expr = ["SCARD", [:SINTER, "foo", "bar"]]

  # Explain returns an array of Redis commands
  expected = [["SINTERSTORE", "stal:0", "foo", "bar"], ["SCARD", "stal:0"]]

  assert_equal expected, Stal.explain(expr)
end
