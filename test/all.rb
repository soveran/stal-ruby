require_relative "helper"

setup do
  Redic.new.tap do |c|
    c.call("FLUSHDB")
    c.call("SCRIPT", "FLUSH")
    c.call("SADD", "foo", "a", "b", "c")
    c.call("SADD", "bar", "b", "c", "d")
    c.call("SADD", "baz", "c", "d", "e")
    c.call("SADD", "qux", "x", "y", "z")
  end
end

test do |c|

  # Example expression
  expr = ["SUNION", "qux", ["SDIFF", ["SINTER", "foo", "bar"], "baz"]]

  assert_equal ["b", "x", "y", "z"], Stal.solve(c, expr).sort

  # Commands without sub expressions also work
  expr = ["SINTER", "foo", "bar"]

  assert_equal ["b", "c"], Stal.solve(c, expr).sort

  # Verify there's no keyspace pollution
  assert_equal ["bar", "baz", "foo", "qux"], c.call("KEYS", "*").sort

  expr = ["SCARD", ["SINTER", "foo", "bar"]]
end
