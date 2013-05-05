require 'fluent/test'
require 'benchmark'

$LOAD_PATH.unshift(File.expand_path(File.join(File.dirname(__FILE__), "..", "lib")))
require 'fluent/plugin/out_redis_counter'

Fluent::Test.setup
fluent = Fluent::Test::BufferedOutputTestDriver.new(Fluent::RedisCounterOutput).configure(%[
    host localhost
    port 6379
    db_number 1
    <pattern>
      match_status ^2[0-9]{2}$
      count_key_format status-normal:item_id:%_{item_id}
      count_value 1
    </pattern>
])

10_0000.times do
  item_id = ( rand * 10_0000 ).to_i
  fluent.emit({ "status" => "200", "item_id" => item_id })
end

result = nil
Benchmark.bm do |x|
  result = x.report {
    fluent.run
  }
end

$log.info("benchmark result: #{result}")

