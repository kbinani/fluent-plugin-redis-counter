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
        match_status /^2[0-9]{2}$/
        match_url /^https/
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

    assert_equal 2, driver.instance.patterns[0]['matches'].size
    assert_equal '/^2[0-9]{2}$/', driver.instance.patterns[0]['matches']['status']
    assert_equal '/^https/', driver.instance.patterns[0]['matches']['url']
    assert_equal 'status-normal', driver.instance.patterns[0]['count_key']
    assert_equal 1, driver.instance.patterns[0]['count_value']

    assert_equal 0, driver.instance.patterns[1]['matches'].size
    assert_equal 'foo', driver.instance.patterns[1]['count_key']
    assert_equal 2, driver.instance.patterns[1]['count_value']
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
      assert_equal '"count_key" is required.', e.message
    end
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

  def test_format
    @d.emit({"a" => 1})
    @d.expect_format({"a" => 1}.to_msgpack)
    @d.run
  end

  def test_write
    @d.emit({"a" => 2})
    @d.emit({"a" => 3})
    @d.emit({"a" => "foo"})
    @d.emit({"a" => -1, "b" => 1})
    @d.run

    assert_equal "4", @d.instance.redis.get("a")
    assert_equal "1", @d.instance.redis.get("b")
  end

  def test_write_with_float
    @d.emit({"a" => "1.1"})
    @d.emit({"a" => "2"})
    @d.run

    assert_equal "2", @d.instance.redis.get("a")
  end

  def test_write_with_object
    @d.emit({"a" => 1})
    @d.emit({"a" => {"foo" => 1}})
    @d.run

    assert_equal "1", @d.instance.redis.get("a")
  end

end
