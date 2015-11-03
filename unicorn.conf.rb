listen ENV['UNICORN_LISTEN']
working_directory ENV['APP_ROOT']
worker_processes ENV['UNICORN_WORKERS'].to_i
pid ENV['UNICORN_PIDFILE']

preload_app true

before_fork do |server, worker|
  ActiveRecord::Base.connection.disconnect!

  old_pid = "#{server.config[:pid]}.oldbin"
  if old_pid != server.pid
    begin
      sig = (worker.nr + 1) >= server.worker_processes ? :QUIT : :TTOU
      Process.kill(sig, File.read(old_pid).to_i)
    rescue Errno::ENOENT, Errno::ESRCH
    end
  end

  sleep 1
end

after_fork do |server, worker|
  ActiveRecord::Base.establish_connection
end
