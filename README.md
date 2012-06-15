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

# Copyright
- Copyright(C) 2012 Buntaro Okada
- Copyright(C) 2011-2012 Yuki Nishijima

# License
- Apache License, Version 2.0
