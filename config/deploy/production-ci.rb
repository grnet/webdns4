set :rails_env, :production

server 'webdns4.grnet.gr', user: 'deployer', roles: %w(web app db)

set :ssh_options, forward_agent: false, port: 29

#Override commands with sudo, for use with jenkins deployer
#SSHKit.config.command_map = Hash.new do |hash, command|
#  hash[command] = "sudo -u webdns #{command}"
#end

