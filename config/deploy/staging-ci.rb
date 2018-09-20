set :rails_env, :production

server 'webdns4.staging.grnet.gr', user: 'deployer', roles: %w(web app db)

set :ssh_options, forward_agent: false
