# Redis counter plugin for fluent [![Build Status](https://secure.travis-ci.org/kbinani/fluent-plugin-redis-counter.png)](http://travis-ci.org/kbinani/fluent-plugin-redis-counter)

fluent-plugin-redis-counter is a fluent plugin to count-up/down redis keys.

# Installation

fluent-plugin-redis-counter is hosted by [RubyGems.org](https://rubygems.org/).

    $fluent-gem install fluent-plugin-redis-counter

# Configuration

    <match redis_counter.**>
      type redis_counter

      host localhost
      port 6379

      # database number is optional.
      db_number 0        # 0 is default
    </match>

# Example

prepare a conf file ("fluent.conf") in current directory like this:

    <source>
      type forward
    </source>
    <match debug.**>
      type redis_counter
      host localhost
      port 6379
      db_number 0
    </match>

run commands for test:

    $redis-server 2>&1 >/dev/null &
    [1] 879
    $echo del foo | redis-cli -h localhost -p 6379 -n 0
    (integer) 0
    $fluentd -c ./fluent.conf 2>&1 >/dev/null &
    [2] 889
    $echo {\"foo\":5} | fluent-cat debug
    $echo {\"foo\":-2} | fluent-cat debug
    $kill -s HUP 889
    $echo get foo | redis-cli -h localhost -p 6379 -n 0
    "3"

# Copyright
- Copyright © 2012 Buntaro Okada
- Copyright © 2011-2012 Yuki Nishijima

# License
- Apache License, Version 2.0
