# encoding: UTF-8

require "json"
require "redic"

module Stal
  LUA = File.expand_path("../../data/stal.lua", __FILE__)
  SHA = "4bd605bfee5f1e809089c5f98d10fab8aec38bd3"

  # Evaluate expression `expr` in the Redis client `c`.
  def self.solve(c, expr)
    begin
      c.call!("EVALSHA", SHA, 0, JSON.dump(expr))
    rescue RuntimeError
      if $!.message["NOSCRIPT"]
        c.call!("SCRIPT", "LOAD", File.read(LUA))
        c.call!("EVALSHA", SHA, 0, JSON.dump(expr))
      else
        raise $!
      end
    end
  end
end
