require 'application_helper'

module Iso8601Duration
  extend self

  TIME_PERIODS = ApplicationHelper::TIME_PERIODS.invert
  def to_seconds(duration)
    total = 0

    atomize(duration).each { |k, val|
      next unless secs = TIME_PERIODS[k.to_s]
      total += secs.to_i * val
    }

    total
  end

  def atomize(input)
    duration = parse(input)

    components = parse_tokens(duration)
    components.delete(:time) # clean time capture

    components
  end

  def parse_tokens(tokens)
    components = tokens.names.zip(tokens.captures).map! do |k, v|
      value = v.nil? ? v : v.tr(',', '.')
      [k.to_sym, value.to_i]
    end

    Hash[components]
  end

  def parse(input)
    input.match(/^
        (?<sign>\+|-)?
        P(?:
          (?:
            (?:(?<year>\d+(?:[,.]\d+)?)Y)?
            (?:(?<month>\d+(?:[.,]\d+)?)M)?
            (?:(?<day>\d+(?:[.,]\d+)?)D)?
            (?<time>T
              (?:(?<hour>\d+(?:[.,]\d+)?)H)?
              (?:(?<minute>\d+(?:[.,]\d+)?)M)?
              (?:(?<second>\d+(?:[.,]\d+)?)S)?
            )?
          ) |
          (?<week>\d+(?:[.,]\d+)?W)
        ) # Duration
      $/x)
  end
end
