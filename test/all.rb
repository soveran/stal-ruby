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

  # Shortcut syntax
  expr = [:union, "qux", [:diff, [:inter, "foo", "bar"], "baz"]]

  # Explicit syntax
  expr = [:SUNIONSTORE, "qux", [:SDIFFSTORE, [:SINTERSTORE, "foo", "bar"], "baz"]]

  assert_equal ["b", "x", "y", "z"], Stal.solve(c, expr).sort

  # Explicit syntax with strings
  expr = ["SUNIONSTORE", "qux", ["SDIFFSTORE", ["SINTERSTORE", "foo", "bar"], "baz"]]

  assert_equal ["b", "x", "y", "z"], Stal.solve(c, expr).sort

  # Explicit syntax with lowercase strings
  expr = ["sunionstore", "qux", ["sdiffstore", ["sinterstore", "foo", "bar"], "baz"]]

  assert_equal ["b", "x", "y", "z"], Stal.solve(c, expr).sort

  assert_equal ["b", "x", "y", "z"], Stal.solve(c, expr).sort

  # Verify there's no pollution
  assert_equal ["bar", "baz", "foo", "qux"], c.call("KEYS", "*").sort
end
