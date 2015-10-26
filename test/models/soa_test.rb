require 'test_helper'

class SOATest < ActiveSupport::TestCase
  def setup
    domain = create(:domain)
    @record = domain.soa
  end

  test 'bump_serial!' do
    @record.save!

    assert_serial_update @record do
      @record.bump_serial!
    end
  end

  test 'updating attributes bumps serial' do
    @record.save!

    assert_serial_update @record do
      @record.contact = 'admin@example.com'
      @record.save!
    end
  end
end
