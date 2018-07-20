set :rails_env, :production

server 'webdns4.test.grnet.gr', user: 'deployer', roles: %w(web app db)

set :ssh_options, forward_agent: false, port: 29

#Override rm and ln commands with sudo, for use with jenkins deployer
SSHKit.config.command_map[:rm] = 'sudo rm'
SSHKit.config.command_map[:ln] = 'sudo ln'

