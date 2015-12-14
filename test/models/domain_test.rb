require 'test_helper'

class DomainTest < ActiveSupport::TestCase
  def setup
    @domain = build(:domain)
  end

  test 'automatic SOA creation' do
    @domain.save!
    @domain.reload
    assert_not_nil @domain.soa
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

  test 'automatic NS creation' do
    @domain.save!
    @domain.reload
    assert_equal WebDNS.settings[:default_ns].sort,
                 @domain.records.where(type: 'NS').pluck(:content).sort
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

  class StatesDomainTest < ActiveSupport::TestCase
    def setup
      @domain = build(:domain)
    end

    test 'domain lifetime' do
      assert_equal 'initial', @domain.state

      # Create
      assert_jobs do
        @domain.save! # user triggered
        assert_equal 'pending_install', @domain.state
      end
      @domain.installed # job triggered
      assert_equal 'operational', @domain.state

      # Convert to dnssec (sign)
      assert_jobs do
        assert @domain.dnssec_sign # user triggered
        assert_equal 'pending_signing', @domain.state
      end

      assert_jobs do
        assert @domain.signed # job triggered
        assert_equal 'wait_for_ready', @domain.state
      end

      # Convert to dnssec (publish ds)
      assert_jobs do
        assert @domain.push_ds([:dss1, :dss2]) # DS script triggered
        assert_equal 'pending_ds', @domain.state
      end
      assert @domain.converted # job triggered
      assert_equal 'operational', @domain.state

      # Convert to plain
      assert_jobs do
        assert @domain.plain_convert # user triggered
        assert_equal 'pending_plain', @domain.state
      end
      assert @domain.converted # job triggered
      assert_equal 'operational', @domain.state

      # Remove
      assert_jobs do
        assert @domain.remove # user triggered
        assert_equal 'pending_remove', @domain.state
      end
      assert @domain.cleaned_up # job triggered
      assert_equal 'destroy', @domain.state
    end
  end

  class DsDomainTest < ActiveSupport::TestCase
    def setup
      @domain = create(:domain)
      @ds = [
        '31406 8 1 189968811e6eba862dd6c209f75623d8d9ed9142',
        '31406 8 2 f78cf3344f72137235098ecbbd08947c2c9001c7f6a085a17f518b5d8f6b916d',
      ]
      @child = "dnssec.#{@domain.name}"
      @extra = DS.create(domain: @domain, name: @child, content: 'other')
    end

    test 'add ds records' do
      Domain.replace_ds(@domain.name, @child, @ds)
      @extra.save! # Should be deleted

      assert_equal @ds.size, DS.where(name: "dnssec.#{@domain.name}").count
      @ds.each { |ds|
        assert_equal 1, DS.where(name: "dnssec.#{@domain.name}", content: ds).count
      }
    end

    test 'check if child is a valid subdomain' do
      assert_raise Domain::NotAChild do
        Domain.replace_ds(@domain.name, 'dnssec.example.net', @ds)
      end
    end

  end
end
