# Add rules to decide the Redis key-name

## current rule

    {"foo": 1, "bar":2}
        => incrby foo 1
           incrby bar 2

## proposal rule A

    {"status": "200", "url": "http://example.com/foo"} with tag "redis_counter.access"
    {"status": "500", "url": "http://example.com/foo"} with tag "redis_counter.access"
    {"status": "304", "url": "http://example.com/bar"} with tag "redis_counter.access"
        => incrby status-5xx 1
        => incrby status-normal 1

conf file:

    <match redis_counter.access>
        type redis_counter
        <pattern>
            match status=/^5[0-9][0-9]$/,page=/^http:\/\/example\.com\/foo$/
            key_name status-5xx
        </pattern>
        <pattern>
            match status=/^(2|3)[0-9][0-9]$/,page=/^http:\/\/example\.com\/foo$/
            key_name status-normal
        </pattern>
        ...
    </match>

## proposal rule B

    {"foo": "value-of-foo", "bar": "value-of-bar"} with tag "redis_counter_a"
    {"baz": "value-of-baz", "piyo": "value-of-piyo"} with tag "redis_counter_b"
        => incrby key-name-a 1
        => incrby key-name-b 1

conf file:

    <match redis_counter_a>
        type redis_counter
        key_name key-name-a
        ...
    </match>
    <match redis_counter_b>
        type redis_counter
        key_name key-name-b
        ...
    </match>
