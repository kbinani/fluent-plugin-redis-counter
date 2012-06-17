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
    redis.quit
  end

  def create_driver(conf = CONFIG)
    Fluent::Test::BufferedOutputTestDriver.new(Fluent::RedisCounterOutput).configure(conf)
  end

  def test_configure
    assert_equal 'localhost', @d.instance.host
    assert_equal 6379, @d.instance.port
    assert_equal 1, @d.instance.db_number
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
    @d.emit({"a" => -1})
    @d.run

    assert_equal "4", @d.instance.redis.get("a")
  end

  def test_write_with_float
    @d.emit({"a" => "1.1"})
    @d.emit({"a" => "2"})
    @d.run

    assert_equal "2", @d.instance.redis.get("a")
  end
end
