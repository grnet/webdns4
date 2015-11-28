module Bean
  class Client

    # Initialize a new Bean::Client.
    #
    # host - The host to connect to.
    #
    def initialize(host)
      @host = host
    end

    # Put a job in the default beanstalk tube.
    def put(body)
      client.tubes['default'].put(body)
    rescue Beaneater::NotConnected
      reconnect!
    end

    # Get a job from the dafault beanstalk tube.
    def reserve(*args)
      client.tubes.reserve(*args)
    end

    # Reconnect to the beanstalk server.
    #
    # retries - Number of retries before failing.
    # sleep_time - Time between retries.
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
