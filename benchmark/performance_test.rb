require 'fluent/test'
require 'benchmark'

if ENV["PROFILE"]
require 'ruby-prof'
end

$LOAD_PATH.unshift(File.expand_path(File.join(File.dirname(__FILE__), "..", "lib")))
require 'fluent/plugin/out_redis_counter'

module PerformanceTestApp
  class Benchmarker
    def initialize
      Fluent::Test.setup
      @fluent = Fluent::Test::BufferedOutputTestDriver.new(Fluent::RedisCounterOutput).configure(%[
          host localhost
          port 6379
          db_number 1
          <pattern>
            match_status ^2[0-9]{2}$
            count_key_format status-normal:item_id:%_{item_id}
            count_value 1
          </pattern>
      ])
    end

    def prepare
      10_0000.times do
        item_id = ( rand * 10_0000 ).to_i
        @fluent.emit({ "status" => "200", "item_id" => item_id })
      end
    end

    def run
      result = nil
      profile = nil
      Benchmark.bm do |x|
        result = x.report {
          if ENV["PROFILE"]
            profile = RubyProf.profile do
              @fluent.run
            end
          else
              @fluent.run
          end
        }
      end

      if ENV["PROFILE"]
        profile_printer = RubyProf::GraphPrinter.new(profile)
        profile_printer.print(STDOUT, {})
      end
      $log.info("benchmark result: #{result}")
    end
  end

  class MemoryWatcher
    def initialize
    end

    def run(&block)
      start_memory = get_memory(Process.pid)
      pid = Process.fork do
        block.call
      end
      @max_memory = 0
      th = Thread.new do
        begin
          loop do
            sleep(0.01)
            msize = get_memory(pid)
            if msize > @max_memory
              @max_memory = msize
            end
          end
        ensure
          $log.info("start memory size:\t#{sprintf("%#10d", start_memory / 1024)}KB")
          $log.info("max memory size:\t#{sprintf("%#10d", @max_memory / 1024)}KB")
        end
      end
      Process.waitall
      th.kill
    end

    def get_memory(pid)
      `ps -h -o rss= -p #{pid}`.to_i * 1024
    end
  end
end

if $0 == __FILE__
  parent = PerformanceTestApp::MemoryWatcher.new
  app = PerformanceTestApp::Benchmarker.new
  parent.run do
    app.prepare
    app.run
  end
end

