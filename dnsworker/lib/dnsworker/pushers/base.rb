module DNSWorker
  module Pushers
    class Base
      attr_reader :cfg

      def initialize(cfg, debug=false)
        @cfg = cfg
        @debug = @debug
      end
      
      def log(this)
        $stderr.puts(this) if debug?
      end

      def debug?
        @debug
      end

      def replace_ds(parent, zone, dss)
        raise NotImplementedError
      end
    end
  end
end
