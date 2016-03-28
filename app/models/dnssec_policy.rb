class DnssecPolicy < ActiveRecord::Base

  ATTRIBUTES = {
    'KSK rollover' => {
      css: 'Keys KSK Lifetime',
      type: :iso8601
    },
    'ZSK rollover' => {
      css: 'Keys ZSK Lifetime',
      type: :iso8601
    }
  }

  def info
    hash = {}
    xml = Nokogiri::XML(policy)

    ATTRIBUTES.each { |name, attr|
      hash[name] = xml.at_css(attr[:css]).content
      hash[name] = Iso8601Duration.to_seconds(hash[name]) if attr[:type] == :iso8601
    }

    hash
  end
end
