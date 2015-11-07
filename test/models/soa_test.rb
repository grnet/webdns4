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

  test 'drop privileges' do
    @record.contact = 'admin@example.com'
    @record.drop_privileges = true
    assert_not @record.editable?

    @record.save
    assert_not_empty @record.errors[:type]
  end

  class DateSerialTests < ActiveSupport::TestCase
    setup do
      domain = create(:date_domain)
      @record = domain.soa
    end

    test 'last bump of the day' do
      assert_equal Strategies::Date, @record.domain.serial_strategy

      freeze_time do
        last_for_day = Time.now.strftime('%Y%m%d99').to_i
        @record.serial = last_for_day
        @record.save!

        assert_serial_update @record do
          @record.bump_serial!
        end
      end
    end

    test 'existing serial points to a future date' do
      assert_equal Strategies::Date, @record.domain.serial_strategy

      freeze_time do
        future_day = (Time.now + 1.week).strftime('%Y%m%d00').to_i
        @record.serial = future_day
        @record.save!

        assert_serial_update @record do
          @record.bump_serial!
        end
      end
    end
  end
end
