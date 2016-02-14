from fabric.api import env, cd
from fabric.operations import run, put, sudo

def setup():
    put('dnsworker.service', '/etc/systemd/system/', use_sudo=True)
    sudo('systemctl daemon-reload')
    sudo('systemctl enable dnsworker.service')

def check():
    run('test -d /run/systemd/system')
    run('test -f /etc/dnsworker/cfg.yml')
    run('systemctl is-enabled dnsworker.service')

def restart():
    sudo('systemctl restart dnsworker.service')

def install_cron():
    put('cron', '/etc/cron.d/dnsworker', use_sudo=True)
    sudo('chown root:root /etc/cron.d/dnsworker')

def copy():
    sudo('mkdir -p /srv/dnsworker')
    with cd('/srv/dnsworker'):
        put('lib', '.', use_sudo=True)
        put('bin', '.', use_sudo=True, mode=0755)
    sudo('chown -R root:root /srv/dnsworker')

def deploy():
    check()
    restart()
    install_cron()

