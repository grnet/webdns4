#!/usr/bin/env ruby
require 'json'
require 'rack/utils'

class DNSWorker::Pushers::Webdns < DNSWorker::Pushers::Base
  def replace_ds(parent, zone, dss)
    query = Rack::Utils.build_nested_query(
      child: zone,
      parent: parent,
      ds: dss,
    )

    uri = URI(cfg.values_at('webdns_base', 'webdns_replace_ds').join % { query: query })

    Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == 'https') do |http|
      resp = http.request Net::HTTP::Put.new(uri.request_uri)

      if resp.code != '200'
        $stderr.puts "WebDNS returned #{resp.code}"
        return false
      end

      body = JSON.parse(resp.body)
      return true if body['ok']

      $stderr.puts "WebDNS returned error '#{body['msg']}'"
    end

    true
  end
end
