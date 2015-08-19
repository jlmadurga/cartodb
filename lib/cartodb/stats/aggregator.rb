require 'statsd'

module CartoDB
  module Stats

    class Aggregator

      private_class_method :new

      attr_reader :fully_qualified_prefix

      def self.instance(prefix, config=[], host_info = Socket.gethostname)
        if config.nil? || config['host'].nil? || config['port'].nil?
          NullAggregator.new
        else
          Statsd.host = config['host']
          Statsd.port = config['port']
          return new(prefix, host_info)
        end
      end

      def initialize(prefix, host_info)
        @fully_qualified_prefix = "#{prefix}.#{host_info}"
        @timing_stack = [fully_qualified_prefix]
      end

      def timing(key)
        return_value = nil
        @timing_stack.push(key)
        Statsd.timing(timing_chain) do
          begin
            return_value = yield
          rescue => e
            @timing_stack.pop
            raise e
          end
        end
        @timing_stack.pop
        return_value
      end

      def timing_chain
        @timing_stack.join('.')
      end

      def gauge(key, value)
        Statsd.gauge("#{fully_qualified_prefix}.#{key}", value)
      end

      def increment(key)
        Statsd.increment("#{fully_qualified_prefix}.#{key}")
      end

    end

    class NullAggregator
      def timing(key)
        yield
      end

      def gauge(key, value)
      end

      def increment(key)
      end
    end

  end
end
