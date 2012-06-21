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

      # match condition
      # this pattern matches {"status": "200", "url": "http://foo.example.com"} and then,
      # increment Redis key "foo-status2xx" by calling Redis::incrby( "foo-status2xx", 1 ).
      <pattern>
        match_status ^2[0-9][0-9]$        # matches with {"status": "200", ...
        match_url ^http:\/\/foo\.         # matches with {"url": "http://foo.example.com", ...
        count_key foo-status2xx           # key-name for Redis
        count_value 1                     # count-up amount(default: 1, negative value is allowed)
      </pattern>

      # time-dependent redis keyname
      # for example, "foo-status2xx-%Y-%m-%d" will be formatted to "foo-status2xx-2012-06-21".
      # rules for placeholder(%Y, etc.) is similar to out_file plugin.
      <pattern>
        match_status ^2[0-9][0-9]$
        count_key_format foo-statux2xx-%d
        localtime                          # time-zone(default: localtime, it can be "utc" or "localtime")
      </pattern>
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
      <pattern>
        match_status ^2[0-9][0-9]$
        match_url ^http:\/\/foo\.
        count_key foo
      </pattern>
    </match>

run commands for test:

    $redis-server 2>&1 >/dev/null &
    [1] 879
    $echo del foo | redis-cli -h localhost -p 6379 -n 0
    (integer) 0
    $fluentd -c ./fluent.conf 2>&1 >/dev/null &
    [2] 889
    $echo {\"status\": \"200\", \"url\": \"http://foo.example.com\"} | fluent-cat debug
    $echo {\"status\": \"500\", \"url\": \"http://foo.example.com\"} | fluent-cat debug
    $kill -s HUP 889
    $echo get foo | redis-cli -h localhost -p 6379 -n 0
    "1"

# Copyright
- Copyright © 2012 Buntaro Okada
- Copyright © 2011-2012 Yuki Nishijima

# License
- Apache License, Version 2.0
