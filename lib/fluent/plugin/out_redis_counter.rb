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
      conf.elements.select { |element|
        element.name == 'pattern'
      }.each { |element|
        begin
          @patterns << Pattern.new(element)
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
      [tag, time, record].to_msgpack
    end

    def write(chunk)
      table = {}
      table.default = 0
      chunk.open { |io|
        begin
          MessagePack::Unpacker.new(io).each { |message|
            (tag, time, record) = message
            @patterns.select { |pattern|
              pattern.is_match?(record)
            }.each{ |pattern|
              table[pattern.get_count_key(time, record)] += pattern.get_count_value(record)
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

    class RecordValueFormatter
      attr_reader :format
      def initialize(format)
        @format = format
      end

      def key(record)
        @format.gsub(/(%_\{[^\}]+\})/) do |s|
          key = s.match(/\{([^\}]+)\}/)[1]
          record[key]
        end
      end
    end

    class Pattern
      attr_reader :matches, :count_value, :count_value_key

      def initialize(conf_element)
        if !conf_element.has_key?('count_key') && !conf_element.has_key?('count_key_format')
          raise RedisCounterException, '"count_key" or "count_key_format" is required.'
        end
        if conf_element.has_key?('count_key') && conf_element.has_key?('count_key_format')
          raise RedisCounterException, 'both "count_key" and "count_key_format" are specified.'
        end

        if conf_element.has_key?('count_key')
          @count_key = conf_element['count_key']
        else
          if conf_element.has_key?('localtime') && conf_element.has_key?('utc')
            raise RedisCounterException, 'both "localtime" and "utc" are specified.'
          end
          is_localtime = true
          if conf_element.has_key?('utc')
            is_localtime = false
          end
          @count_key_format = [conf_element['count_key_format'], is_localtime]
        end

        if conf_element.has_key?('count_value_key')
          @count_value_key = conf_element['count_value_key']
        else
          @count_value = 1
          if conf_element.has_key?('count_value')
            begin
              @count_value = Integer(conf_element['count_value'])
            rescue
              raise RedisCounterException, 'invalid "count_value", integer required.'
            end
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

      def get_count_key(time, record)
        if @count_key_format == nil
          @count_key
        else
          count_key = RecordValueFormatter.new(@count_key_format[0]).key(record)
          formatter = TimeFormatter.new(count_key, @count_key_format[1])
          formatter.format(time)
        end
      end

      def get_count_value(record)
        if @count_value_key
          ret = record[@count_value_key] || 0
          return ret.kind_of?(Integer) ? ret : 0
        else
          if @count_value
            return @count_value
          end
        end
      end
    end
  end
end
