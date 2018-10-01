set :rails_env, :production

server 'webdns4.staging.grnet.gr', user: 'deployer', roles: %w(web app db)

set :branch, ENV['BRANCH'] if ENV['BRANCH']

set :ssh_options, forward_agent: false, port: 29
