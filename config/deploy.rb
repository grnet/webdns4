# config valid only for Capistrano 3.1
lock '3.2.1'

set :application, 'webdns'
set :repo_url, 'git@bitbucket.org:xlembouras/webns.git'

set :deploy_to, '/srv/webdns'

set :linked_files, %w(config/database.yml config/secrets.yml)
set :linked_dirs, %w(log tmp/pids tmp/cache tmp/sockets)

set :keep_releases, 5

namespace :deploy do
  desc 'Restart application'
  task :restart do
    on roles(:app), in: :sequence, wait: 5 do
      # Your restart mechanism here, for example:
      # execute :touch, release_path.join('tmp/restart.txt')
    end
  end

  after :publishing, :restart

  after :restart, :clear_cache do
    on roles(:web), in: :groups, limit: 3, wait: 10 do
      # Here we can do anything such as:
      # within release_path do
      #   execute :rake, 'cache:clear'
      # end
    end
  end
end
