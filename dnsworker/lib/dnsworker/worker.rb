require 'json'
require 'net/http'
require 'uri'
require 'pp'

require 'rack/utils'

require 'dnsworker'
require 'dnsworker/base_worker'
require 'dnsworker/pushers/base'
require 'dnsworker/pushers/papaki'
require 'dnsworker/pushers/webdns'

class DNSWorker::Worker
  include DNSWorker::BaseWorker

  Pushers = Hash[
    :papaki, DNSWorker::Pushers::Papaki,
    :webdns, DNSWorker::Pushers::Webdns,
  ]

  def initialize(cfg)
    @cfg = cfg
    super(cfg['mysql'])
  end

  def add_domain(params)
    params[:master] = cfg['hidden_master']
    cmd(cfg['bind_add'] % params)
  end

  def remove_domain(params)
    cmd(cfg['bind_del'] % params)
  end

  def opendnssec_add(params)
    cmd(cfg['ods_add'] % params)
  end

  def opendnssec_remove(params)
    cmd(cfg['ods_del'] % params)
  end

  def bind_convert_to_dnssec(params)
    fail Retry if !File.exist? File.join(cfg['zone_root'], 'signed', params[:zone])

    # Remove zone and re-add it as a master zone
    remove_domain(params)
    cmd(cfg['bind_add_dnssec'] % params)
  end

  # The zone is signed, waiting for the ksk to become ready
  def wait_for_ready_to_push_ds(params)
    out, _err = cmd(cfg['ready_to_push_ds'] % params)
    
    fail Retry unless out['ds-seen']
  end

  def publish_ds(params)
    pub_cls = Pushers[params[:dnssec_parent_authority].to_sym]
    fail JobFailed unless pub_cls

    pub = pub_cls.new(cfg)

    fail JobFailed unless pub.replace_ds(params[:dnssec_parent], params[:zone], params[:dss])
  end

  def wait_for_active(params)
    keytag = params[:keytag]
    out, _err = cmd(cfg['key_activated'] % params)
    key_lines = out.each_line.select { |line| line.start_with?(params[:zone]) }

    # Check if the key is activated
    return if key_lines.any? {|kl|
      # example
      # <domain> KSK active 2016-12-12 18:41:33 (retire) 2048 8 b70042f966e5f01deb2e988607ad67ba  SoftHSM 60076

      kl.strip!
      _domain, _type, status, _rest = kl.split(/\s+/, 4)
      
      status == 'active' and _rest.end_with?(keytag)
    }

    fail Retry
  end

  def trigger_event(params)
    query = Rack::Utils.build_query(domain: params[:zone], event: params[:event])
    uri = URI(cfg.values_at('webdns_base', 'update_state').join % { query: query })

    Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == 'https') do |http|
      resp = http.request Net::HTTP::Put.new(uri.request_uri)

      fail JobFailed if resp.code != '200'
      ok = JSON.parse(resp.body)['ok']
      fail JobFailed if !ok
    end
  end

  private

  def cmdline(jtype, jargs)
    if jargs
      send(jtype, jargs)
    else
      send(jtype)
    end
  end
end
