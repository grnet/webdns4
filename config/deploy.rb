set :application, 'webdns'
set :repo_url, 'https://github.com/grnet/webdns4'

set :deploy_to, '/srv/webdns'

set :linked_files, %w(config/database.yml config/secrets.yml config/local_settings.rb)
set :linked_dirs, %w(log tmp/pids tmp/cache tmp/sockets)

set :keep_releases, 5
set :log_level, :info

namespace :deploy do
  desc 'Restart application'
  task :restart do
    on roles(:app), in: :sequence, wait: 5 do
      execute 'sudo unicornctl restart'
    end
  end

  after :publishing, :restart
end
