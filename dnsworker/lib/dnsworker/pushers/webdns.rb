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

    Net::HTTP.start(uri.host, uri.port) do |http|
      resp = http.request Net::HTTP::Put.new(uri.request_uri)

      return false if resp.code != '200'
    end

    true
  end
end
