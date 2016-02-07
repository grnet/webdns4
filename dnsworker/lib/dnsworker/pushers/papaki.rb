#!/usr/bin/env ruby
require 'json'
require 'faraday_middleware'

class DNSWorker::Pushers::Papaki < DNSWorker::Pushers::Base

  def replace_ds(_parent, domain, dss)
    dss = prepare_dss(dss)
    current = current_ds(domain)

    # Papaki needs an empty publicKey attribute
    to_add = (dss - current).map { |ds| ds['publicKey'] = ''; ds }
    to_remove = (current - dss).map { |ds| ds['publicKey'] = ''; ds }
    
    p [:add, to_add]
    p [:rem, to_remove]
    return true if to_add.empty? && to_remove.empty?

    req = {
      type: 'managednssec',
      domainname: domain,
    }
    
    req['dnssectoadd'] = { ds: dss } if dss.any?
    req['dnssectoremove'] = { ds: current } if current.any?
    request(req)

    true
  end

  def current_ds(domain)
    resp = request(type: 'dnssecinfo', domainname: domain)

    # Remove unessesary keys
    resp['dsrecords'].map { |ds|
      key, alg, digest = ds.values_at('keyTag', 'alg', 'digest')
      Hash['keyTag', key, 'alg', alg, 'digest', digest.downcase]
    }
  end

  private

  def client
    @client ||= client!
  end

  def client!
    api = Faraday.new cfg['papaki_host'] do |conn|
      conn.response :json
      
      #conn.response :logger  
      conn.adapter Faraday.default_adapter
    end
  end


  def prepare_dss(dss)
    # Papaki seems to accept specific digest_algorithms based on the DNSKEY algo
    # This map will guide that through this.
    #
    alg_digest_map = {
      '5' => '1',  # RSA/SHA-1 => SHA1
      '7' => '1',  # RSASHA1-NSEC3-SHA1 => SHA1
      '8' => '2',  # RSA/SHA-256 => SHA-256
      '10' => '2', # RSA/SHA-512 => SHA-256
    }
    ds_for_papaki = []
    
    dss.each { |ds_line|
      # 11845 8 1 f781fc2422bf265b5606d7dc095d15183014ee6a'
      key, alg, digest_type, digest = ds_line.split

      # Send only digest types supported by papaki
      next if digest_type != alg_digest_map[alg]

      ds_for_papaki << Hash['keyTag', key, 'alg', alg, 'digest', digest.downcase]
    }

    ds_for_papaki
  end

  def ds_info(domain)
    request(type: 'dnssecinfo', domainname: domain)
  end

  def request(data)
    resp = client.post cfg['papaki_endpoint'] do |r|
      r.headers['Content-Type'] = 'application/x-www-form-urlencoded'
      data_with_key = data.merge(apiKey: cfg['papaki_key'])
      r.body = JSON.dump({request: data_with_key})
    end

    puts "\n* Request #{data[:do] || data[:type]} for #{data[:domainname]}"
    data.each { |k,v|
      puts "#{k}: #{v}"
    }
    puts "\n* Response #{data[:do] || data[:type]} for #{data[:domainname]}"
    resp.body['response'].tap { |r|
      raise "#{r['code']}: #{r['message']}" if r['code'] != '1000'
      r.to_a.sort.each { |k, v|
        puts "#{k}: #{v}"
      }
    }
  end
end
