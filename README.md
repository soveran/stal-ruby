Stal
====

Set algebra solver for Redis.

Description
-----------

`Stal` receives an array with an s-expression composed of commands
and key names and resolves the set operations in [Redis][redis].

Community
---------

Meet us on IRC: [#lesscode](irc://chat.freenode.net/#lesscode) on
[freenode.net](http://freenode.net/).

Getting started
---------------

Install [Redis][redis]. On most platforms it's as easy as grabbing
the sources, running make and then putting the `redis-server` binary
in the PATH.

Once you have it installed, you can execute `redis-server` and it
will run on `localhost:6379` by default. Check the `redis.conf`
file that comes with the sources if you want to change some settings.

Usage
-----

`Stal` requires a [Redic][redic] compatible client. To make things
easier, `redic` is listed as a runtime dependency so the examples
in this document will work.

```ruby
require "stal"

# Connect the client to the default host
redis = Redic.new

# Use the Redis client to populate some sets
redis.call("SADD", "foo", "a", "b", "c")
redis.call("SADD", "bar", "b", "c", "d")
redis.call("SADD", "baz", "c", "d", "e")
redis.call("SADD", "qux", "x", "y", "z")
```

Now we can perform some set operations with `Stal`:

```ruby
expr = [:SUNION, "qux", [:SDIFF, [:SINTER, "foo", "bar"], "baz"]]

Stal.solve(redis, expr)
#=> ["b", "x", "y", "z"]
```

`Stal` translates the internal calls to  `:SUNION`, `:SDIFF` and
`:SINTER` into `SDIFFSTORE`, `SINTERSTORE` and `SUNIONSTORE` to
perform the underlying operations, and it takes care of generating
and deleting any temporary keys.

Note that the only valid names for the internal commands are
`:SUNION`, `:SDIFF` and `:SINTER`. Any other internal command will
raise an error. The outmost command can be any set operation, for
example:

```ruby
expr = [:SCARD, [:SINTER, "foo", "bar"]]

Stal.solve(redis, expr)
#=> 2
```

If you want to preview the commands `Stal` will send to generate
the results, you can use `Stal.explain`:

```ruby
Stal.explain([:SINTER, [:SUNION, "foo", "bar"], "baz"])
#  [["SUNIONSTORE", "stal:0", "foo", "bar"],
#   [:SINTER, "stal:0", "baz"]]
```

All commands are pipelined and wrapped in a `MULTI/EXEC` transaction.

Installation
------------

```
$ gem install stal
```

[redis]: http://redis.io
[redic]: https://github.com/amakawa/redic
