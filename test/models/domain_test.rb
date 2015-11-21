require 'test_helper'

class DomainTest < ActiveSupport::TestCase
  def setup
    @domain = build(:domain)
  end

  test 'automatic SOA creation' do
    @domain.save!
    @domain.reload
    assert_not_nil @domain.soa
    assert_equal 1, @domain.soa.serial
  end

  test 'increment serial on new record' do
    @domain.save!
    soa = @domain.soa

    assert_serial_update soa do
      www = A.new(name: 'www', domain: @domain, content: '1.2.3.4')
      www.save!
    end
  end

  test 'increment serial on record update' do
    @domain.save!
    www = A.new(name: 'www', domain: @domain, content: '1.2.3.4')
    www.save!
    soa = @domain.soa.reload

    assert_serial_update soa do
      www.content = '1.2.3.5'
      www.save!
    end
  end

  test 'increment serial on record destroy' do
    @domain.save!
    www = A.new(name: 'www', domain: @domain, content: '1.2.3.4')
    www.save!
    soa = @domain.soa.reload

    assert_serial_update soa do
      www.destroy!
    end
  end

  class SlaveDomainTest < ActiveSupport::TestCase
    def setup
      @domain = build(:slave)
    end

    test 'saves' do
      @domain.save

      assert_empty @domain.errors
    end

    test 'automatic SOA creation' do
      @domain.save!
      @domain.reload
      assert_not_nil @domain.soa
      assert_equal 1, @domain.soa.serial
    end

    test 'validates master' do
      @domain.master = 'not-an-ip'
      @domain.save

      assert_not_empty @domain.errors['master']
    end

    test 'no records are allowed for users' do
      @domain.save!
      rec = build(:a, domain_id: @domain.id)

      assert_not rec.valid?
      assert_not_empty rec.errors[:type]
    end
  end
end
