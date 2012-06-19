module Fluent
  class RedisCounterOutput < BufferedOutput
    Fluent::Plugin.register_output('redis_counter', self)
    attr_reader :host, :port, :db_number, :redis, :patterns

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
      @patterns = []
      conf.elements.select { |e|
        e.name == 'pattern'
      }.each { |e|
        begin
          @patterns << Pattern.new(e)
        rescue RedisCounterException => e
          raise Fluent::ConfigError, e.message
        end
      }
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
            @patterns.select { |pattern|
              pattern.is_match?(record)
            }.each{ |pattern|
              table[pattern.count_key] += pattern.count_value
            }
          }
        rescue EOFError
          # EOFError always occured when reached end of chunk.
        end
      }
      table.each_pair.select { |key, value|
        value != 0
      }.each { |key, value|
        @redis.incrby(key, value)
      }
    end

    class RedisCounterException < Exception
    end

    class Pattern
      attr_reader :matches, :count_key, :count_value

      def initialize(conf_element)
        if conf_element.has_key?('count_key') == false
          raise RedisCounterException, '"count_key" is required.'
        end
        @count_key = conf_element['count_key']

        @count_value = 1
        if conf_element.has_key?('count_value')
          begin
            @count_value = Integer(conf_element['count_value'])
          rescue
            raise RedisCounterException, 'invalid "count_value", integer required.'
          end
        end

        @matches = {}
        conf_element.each_pair.select { |key, value|
          key =~ /^match_/
        }.each { |key, value|
          name = key['match_'.size .. key.size]
          @matches[name] = Regexp.new(value)
        }
      end

      def is_match?(record)
        @matches.each_pair{ |key, value|
          if !record.has_key?(key) || !(record[key] =~ value)
            return false
          end
        }
        return true
      end
    end
  end
end
