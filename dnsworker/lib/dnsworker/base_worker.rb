require 'json'
require 'mysql2'
require 'open3'

module DNSWorker::BaseWorker
  class JobFailed < StandardError; end
  class Retry < StandardError; end
  class CmdFailed < StandardError; end

  attr_reader :client
  attr_reader :cfg
  attr_reader :dry_run
  attr_accessor :working

  # Start consuming jobs.
  #
  # Handles reconnects.
  def work(opts = {})
    @dry_run = opts[:dry_run]

    register_signals
    opts[:once] ? run : watch
  end

  # Graceful stop the worker.
  #
  # If no job is running stops immediately.
  def stop
    if working
      @stop = true
    else
      exit
    end
  end

  private

  def stop?
    @stop
  end

  def system(cmd)
    p [:cmd, cmd]
    Kernel.system(cmd)
  end

  def register_signals
    trap('INT') { stop }
    trap('TERM') { stop }
  end

  def watch
    loop do
      procline('watching')
      break if stop?

      run

      sleep(cfg['timeout'])
    end
  end

  def run
    self.working = true
    jobs = client.query('select * from jobs where status in (0, 2) order by id asc').to_a
    jobs.group_by { |j| j[:domain_id] }.each { |domain_id, jobs|
      process_jobs(domain_id, jobs)
    }
    self.working = false
  end

  def process_jobs(domain_id, jobs)
    catch(:stop_process) do
      jobs.each { |job|
        if job[:status] == 2 # Stop on processing zone on failed jobs
          $stderr.puts "Not processing domain=#{domain_id} because a failed job exists jobid=#{job[:id]} |#{job}|"
          throw :stop_process
        end
        dispatch(job)
      }
    end
  end

  def procline(line)
    $0 = "dnsworker-#{line}"
  end

  def initialize(mysql_cfg)
    my_cfg = mysql_cfg.merge(reconnect: true, symbolize_keys: true)
    @client = Mysql2::Client.new(my_cfg)
  end

  def dispatch(job)
    id, jtype, jargs = job.values_at(:id, :job_type, :args)
    jargs = JSON.parse(jargs, symbolize_names: true)

    procline("working on jobid=#{id} #{jtype} #{jargs}")
    $stderr.puts "working on jobid=#{id} #{jtype} #{jargs}"
    send(jtype, jargs) unless dry_run
    mark_done(id)

  rescue Retry
    mark_retry(id)
    throw :stop_process
  rescue CmdFailed
    mark_fail(id)
    throw :stop_process
  rescue JobFailed
    mark_fail(id)
    throw :stop_process
  end

  def mark_done(id)
    $stderr.puts :done
    client.query("update jobs set status=1 where id=#{id}") unless dry_run
  end

  def mark_fail(id)
    $stderr.puts :fail
    client.query("update jobs set status=2 where id=#{id}") unless dry_run
  end

  def mark_retry(id)
    $stderr.puts :retry
    client.query("update jobs set retries = retries + 1 where id=#{id}") unless dry_run
  end

  def cmd(command)
    out, err, status = Open3.capture3(command)
    raise CmdFailed if !status.success?

    [out, err]
  end
end
