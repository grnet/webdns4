Beaneater.configure do |config|
  config.default_put_ttr = 10.minutes

  config.job_parser      = ->(body) { ActiveSupport::JSON.decode(body).symbolize_keys! }
  config.job_serializer  = ->(body) { ActiveSupport::JSON.encode(body) }
end

