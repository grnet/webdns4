module Bean
  class Client
    def initialize(host)
      @host = host
    end

    def put(body)
      client.tubes['default'].put(body)
    rescue Beaneater::NotConnected
      reconnect!
    end

    def reserve(*args)
      client.tubes.reserve(*args)
    end

    def reconnect!(retries = 3, sleep_time = 0.5)
      client!
    rescue Beaneater::NotConnected => exception
      retries -= 1
      raise exception if retries.zero?
      sleep(sleep_time)
      retry
    end

    private

    def client
      @client ||= client!
    end

    def client!
      @client.close if @client # rescue nil
      @client = connect
    end

    def connect
      Beaneater.new(@host)
    end
  end
end
