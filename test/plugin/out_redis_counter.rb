require 'fluent/test'

class RedisCounterTest < Test::Unit::TestCase
  def setup
    Fluent::Test.setup
    require 'fluent/plugin/out_redis_counter'

    @d = create_driver %[
      host localhost
      port 6379
      db_number 1
    ]
    redis = Redis.new(
      :host => "localhost", :port => 6379,
      :thread_safe => true, :db => 1
    )
    redis.del("a")
    redis.del("b")
    redis.del("foo-2012-06-21")
    redis.quit
  end

  def create_driver(conf = CONFIG)
    Fluent::Test::BufferedOutputTestDriver.new(Fluent::RedisCounterOutput).configure(conf)
  end

  def test_configure
    assert_equal 'localhost', @d.instance.host
    assert_equal 6379, @d.instance.port
    assert_equal 1, @d.instance.db_number
    assert_equal 0, @d.instance.patterns.size
  end

  def test_configure_pattern
    driver = create_driver %[
      host localhost
      port 6379
      db_number 1
      <pattern>
        match_status ^2[0-9]{2}$
        match_url ^https
        count_key status-normal
      </pattern>
      <pattern>
        count_key foo
        count_value 2
      </pattern>
    ]
    assert_equal 'localhost', driver.instance.host
    assert_equal 6379, driver.instance.port
    assert_equal 1, driver.instance.db_number
    assert_equal 2, driver.instance.patterns.size

    assert_equal 2, driver.instance.patterns[0].matches.size
    assert_equal Regexp.new('^2[0-9]{2}$'), driver.instance.patterns[0].matches['status']
    assert_equal Regexp.new('^https'), driver.instance.patterns[0].matches['url']
    assert_equal 'status-normal', driver.instance.patterns[0].get_count_key(Time.now.to_i, {})
    assert_equal 1, driver.instance.patterns[0].count_value

    assert_equal 0, driver.instance.patterns[1].matches.size
    assert_equal 'foo', driver.instance.patterns[1].get_count_key(Time.now.to_i, {})
    assert_equal 2, driver.instance.patterns[1].count_value
  end

  def test_configure_count_key_required
    begin
      create_driver %[
        <pattern>
          count_value 1
        </pattern>
      ]
      flunk
    rescue Fluent::ConfigError => e
      assert_equal '"count_key" or "count_key_format" is required.', e.message
    end
  end

  def test_configure_count_key_duplicated
    begin
      create_driver %[
        <pattern>
          count_key foo
          count_key_format foo-%Y
        </pattern>
      ]
      flunk
    rescue Fluent::ConfigError => e
      assert_equal 'both "count_key" and "count_key_format" are specified.', e.message
    end
  end

  def test_configure_count_key_format_utc
    driver = create_driver %[
      <pattern>
        count_key_format foo-%Y-%m-%d-%H-%M-%S
        utc
      </pattern>
    ]
    time = Time.parse('2011-06-21 03:12:01 UTC').to_i
    assert_equal 'foo-2011-06-21-03-12-01', driver.instance.patterns[0].get_count_key(time, {})
  end

  def test_configure_count_key_format_localtime
    driver = create_driver %[
      <pattern>
        count_key_format foo-%Y-%m-%d-%H-%M-%S
        localtime
      </pattern>
    ]
    local_time = Time.parse('2012-06-21 03:12:00').to_i
    assert_equal 'foo-2012-06-21-03-12-00', driver.instance.patterns[0].get_count_key(local_time, {})
  end

  def test_configure_duplicated_timezone
    begin
      create_driver %[
        <pattern>
          count_key_format foo%Y
          localtime
          utc
        </pattern>
      ]
      flunk
    rescue Fluent::ConfigError => e
      assert_equal 'both "localtime" and "utc" are specified.', e.message
    end
  end

  def test_configure_count_key_format_with_record_value_formatter
    driver = create_driver %[
      <pattern>
        count_key_format %_{prefix}-foo-%Y-%m-%_{type}-%_{customer_id}
        localtime
      </pattern>
    ]
    local_time = Time.parse('2012-06-21 03:12:00').to_i
    record = {'prefix' => 'pre', 'type' => 'bar', 'customer_id' => 321}
    assert_equal 'pre-foo-2012-06-bar-321', driver.instance.patterns[0].get_count_key(local_time, record)
  end

  def test_configure_invalid_count_value
    begin
      create_driver %[
        <pattern>
          count_key foo
          count_value a
        </pattern>
      ]
      flunk
    rescue Fluent::ConfigError => e
      assert_equal 'invalid "count_value", integer required.', e.message
    end
  end

  def test_get_count_value_with_count_value_key
    driver = create_driver %[
      <pattern>
        count_key_format %_{customer_id}
        count_value_key count
      </pattern>
    ]
    record = {'count' => 123, 'customer_id' => 321}
    assert_equal 123, driver.instance.patterns[0].get_count_value(record)
  end

  def test_get_count_value_without_count_value_key
    driver = create_driver %[
      <pattern>
        count_key_format %_{customer_id}
      </pattern>
    ]
    record = {'count' => 123, 'customer_id' => 321}
    assert_equal 1, driver.instance.patterns[0].get_count_value(record)
  end

  def test_format
    time = Time.parse('2012-06-21 01:55:00 UTC').to_i
    @d.emit({"a" => 1}, time)
    @d.expect_format(['test', time, {"a" => 1}].to_msgpack)
    @d.run
  end

  def test_write
    driver = create_driver %[
      db_number 1
      <pattern>
        match_a ^2[0-9][0-9]$
        count_key a
        count_value 2
      </pattern>
    ]
    driver.emit({"a" => "value-of-a"})
    driver.emit({"a" => "200"})
    driver.emit({"b" => "200"})
    driver.emit({"aa" => "200"})
    driver.emit({"a" => "2000"})
    driver.run

    assert_equal '2', driver.instance.redis.get("a")
    assert_nil driver.instance.redis.get("b")
  end

  def test_write_with_timeformat
    driver = create_driver %[
      db_number 1
      <pattern>
        match_a ^2[0-9][0-9]$
        count_key_format foo-%Y-%m-%d
        count_value 2
      </pattern>
    ]
    time = Time.parse('2012-06-21 03:01:00 UTC').to_i
    driver.emit({"a" => "200"}, time)
    driver.run

    assert_equal '2', driver.instance.redis.get("foo-2012-06-21")
  end

  def test_write_with_count_value_key
    driver = create_driver %[
      db_number 1
      <pattern>
        count_key_format item_sum_count:%_{item_id}
        count_value_key count
      </pattern>
    ]

    time = Time.parse('2012-06-21 03:01:00 UTC').to_i
    driver.emit({"item_id" => 200, "count" => 123}, time)
    driver.run

    assert_equal '123', driver.instance.redis.get("item_sum_count:200")
  end

end
