module Fluent
  class RedisCounterOutput < BufferedOutput
    Fluent::Plugin.register_output('redis_counter', self)
    attr_reader :host, :port, :db_number, :redis

    def initialize
      super
      require 'redis'
      require 'msgpack'
    end

    def configure(conf)
      super
      @host = conf.has_key?('host') ? conf['host'] : 'localhost'
      @port = conf.has_key?('port') ? conf['port'].to_i : 6379
      @db_number = conf.has_key?('db_number') ? conf['db_number'].to_i : nil
    end

    def start
      super
      @redis = Redis.new(
        :host => @host, :port => @port,
        :thread_safe => true, :db => @db_number
      )
    end

    def shutdown
      @redis.quit
    end

    def format(tag, time, record)
      record.to_msgpack
    end

    def write(chunk)
      table = {}
      table.default = 0
      chunk.open { |io|
        begin
          MessagePack::Unpacker.new(io).each { |record|
            record.each_key { |key|
              if (value = record[key].to_i) != 0
                table[key] += value
              end
            }
          }
        rescue EOFError
          # EOFError always occured when reached end of chunk.
        end
      }
      table.each_key { |key|
        @redis.incrby(key, table[key])
      }
    end
  end
end
