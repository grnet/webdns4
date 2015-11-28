require 'singleton'

module Bean
  class Worker
    include Singleton

    TIMEOUT = 5

    attr_accessor :job

    def self.work
      instance.work
    end

    def work
      register_signals
      watch
    rescue Beaneater::NotConnected
      Base.beanstalk_reconnect!
    end

    def stop
      if job.nil?
        exit
      else
        @stop = true
      end
    end

    private

    def stop? # rubocop:disable Style/TrivialAccessors
      @stop
    end

    def register_signals
      trap('INT') { stop }
      trap('TERM') { stop }
    end

    def watch
      loop do
        procline('watching')
        break if stop?

        process_job
      end
    rescue Beaneater::TimedOutError
      retry
    end

    def process_job
      self.job = Base.bean.reserve(TIMEOUT)
      log_job

      job.delete
    ensure
      self.job = nil
    end

    def log_job
      procline("working on jobid=#{job.id} #{job.body}")
      Rails.logger.warn(job_id: job.id, job_body: job.body.to_s)
    end

    def procline(line)
      $0 = "bean-#{line}"
    end
  end
end
