# Redis counter plugin for fluent [![Build Status](https://secure.travis-ci.org/kbinani/fluent-plugin-redis-counter.png)](http://travis-ci.org/kbinani/fluent-plugin-redis-counter)

fluent-plugin-redis-counter is a fluent plugin to count-up/down redis keys.

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
    $redis-cli
    redis 127.0.0.1:6379>del foo
    (integer) 0
    redis 127.0.0.1:6379>exit
    $fluentd -c ./fluent.conf 2>&1 >/dev/null &
    [2] 889
    $echo {\"foo\":5} | fluent-cat debug
    $echo {\"foo\":-2} | fluent-cat debug
    $kill 889
    $redis-cli
    redis 127.0.0.1:6379>get foo
    "3"
    redis 127.0.0.1:6379>

# Copyright
- Copyright(C) 2012 Buntaro Okada
- Copyright(C) 2011-2012 Yuki Nishijima

# License
- Apache License, Version 2.0
