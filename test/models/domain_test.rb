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

  test 'uniqueness of records' do
    @domain.save!
    rec = Record.new(type: 'A', name: 'www', domain: @domain, content: '1.2.3.4')
    rec.save!
    assert_empty rec.errors

    rec2 = Record.new(type: 'A', name: 'www', domain: @domain, content: '1.2.3.4')
    assert_raises(ActiveRecord::RecordInvalid) { rec2.save! }
    assert_not_empty rec2.errors[:name]

    rec3 = Record.new(type: 'A', name: 'www2', domain: @domain, content: '1.2.3.4')
    rec3.save!
    assert_empty rec3.errors

    rec4 = Record.new(type: 'A', name: 'www', domain: @domain, content: '1.2.3.5')
    rec4.save!
    assert_empty rec4.errors

    rec5 = Record.new(type: 'AAAA', name: 'www', domain: @domain, content: '2001:0db8:85a3:0000:0000:8a2e:0370:7334')
    rec5.save!
    assert_empty rec5.errors
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

  test 'do not allow other record types when there is a cname' do
    @domain.save!
    name = 'mysupername'

    cname = CNAME.new(name: name, domain: @domain, content: 'whocares')
    cname.save!
    assert_empty cname.errors

    www = A.new(name: name, domain: @domain, content: '1.2.3.4')
    assert_raises(ActiveRecord::RecordNotSaved) { www.save! }
    assert_not_empty www.errors[:name]
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
      @policy = DnssecPolicy.all[0]
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
        @domain.dnssec = true
        @domain.dnssec_policy = @policy
        @domain.dnssec_parent = @domain.name.split('.', 2).last
        @domain.dnssec_parent_authority = 'test_authority'
        @domain.save!

        # After commit is not triggered in tests,
        # so we have to trigger it manually
        @domain.send(:after_commit_event)

        assert_equal 'pending_signing', @domain.state
      end

      assert_jobs do
        assert @domain.signed # job triggered
        assert_equal 'wait_for_ready', @domain.state
      end

      # Convert to dnssec (publish ds)
      assert_jobs do
        assert @domain.push_ds(['dss1', 'dss2']) # triggered by ds-schedule script
        assert_equal 'pending_ds', @domain.state
      end
      assert @domain.converted # job triggered
      assert_equal 'operational', @domain.state

      # KSK rollover
      assert_jobs do
        assert @domain.push_ds(['dss3', 'dss4']) # triggered by ds-schedule script
        assert_equal 'pending_ds_rollover', @domain.state
      end
      assert @domain.complete_rollover # job triggered
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

    test 'domain lifetime #full-destroy' do
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
        @domain.dnssec = true
        @domain.dnssec_policy = @policy
        @domain.dnssec_parent = @domain.name.split('.', 2).last
        @domain.dnssec_parent_authority = 'test_authority'
        @domain.save!

        # After commit is not triggered in tests,
        # so we have to trigger it manually
        @domain.send(:after_commit_event)

        assert_equal 'pending_signing', @domain.state
      end

      assert_jobs do
        assert @domain.signed # job triggered
        assert_equal 'wait_for_ready', @domain.state
      end

      # Convert to dnssec (publish ds)
      assert_jobs do
        assert @domain.push_ds(['dss1', 'dss2']) # triggered by ds-schedule script
        assert_equal 'pending_ds', @domain.state
      end
      assert @domain.converted # job triggered
      assert_equal 'operational', @domain.state

      # KSK rollover
      assert_jobs do
        assert @domain.push_ds(['dss3', 'dss4']) # triggered by ds-schedule script
        assert_equal 'pending_ds_rollover', @domain.state
      end
      assert @domain.complete_rollover # job triggered
      assert_equal 'operational', @domain.state

      # Full Remove (Drops DS records)
      assert_jobs do
        assert @domain.full_remove # user triggered
        assert_equal 'pending_ds_removal', @domain.state
      end

      assert_jobs do
        assert @domain.remove # job triggered
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

    test 'remove ds records' do
      Domain.replace_ds(@domain.name, @child, [])

      assert_equal 0, DS.where(name: "dnssec.#{@domain.name}").count
    end

    test 'check if child is a valid subdomain' do
      assert_raise Domain::NotAChild do
        Domain.replace_ds(@domain.name, 'dnssec.example.net', @ds)
      end
    end

  end

  class BulkTest < ActiveSupport::TestCase
    def setup
      @domain = create(:domain)
      @a = create(:a, domain: @domain)
      @aaaa = create(:aaaa, domain: @domain)
      @new = build(:mx, domain: @domain)

    end

    def valid_changes
      @valid_changes ||= begin
                           {}.tap { |c|
                             c[:deletes] = [@a.id]
                             c[:changes] = { @aaaa.id => { content: '::42' }}
                             c[:additions] = { 1 => @new.as_bulky_json }
                           }
                         end
    end

    def invalid_changes
      @invalid_changes ||= begin
                             {}.tap { |c|
                               c[:deletes] = [Record.maximum(:id) + 1]
                               c[:changes] = { @aaaa.id => { content: '1.2.3.4' }}
                               c[:additions] = { 1 => @new.as_bulky_json.update(prio: -1) }
                             }
                           end
    end

    test 'apply changes not' do
      ops, err = @domain.bulk invalid_changes

      assert_not_empty err
      assert_includes err[:deletes][Record.maximum(:id) + 1], 'record not found'
      assert_includes err[:changes][@aaaa.id], 'not a valid IPv6'
      assert_includes err[:additions][1], 'not a valid DNS priority'
    end

    test 'apply changes' do
      ops, err = @domain.bulk valid_changes

      @domain.reload
      @aaaa.reload

      assert_empty err
      assert_empty @domain.records.where(id: @a.id)
      assert_equal '::42', @aaaa.content
      assert_equal 1, @domain.records.where(type: :mx).count
      assert_equal 1, ops[:additions].size
      assert_equal 1, ops[:changes].size
      assert_equal 1, ops[:deletes].size
    end
  end

  class ApiBulkTest < ActiveSupport::TestCase
    def setup
      @domain = create(:domain)
      @a = create(:a, domain: @domain)
      @aaaa = create(:aaaa, domain: @domain, content: '::42')
      @new = build(:mx, domain: @domain)
      @upsert_txt = build(:txt, domain: @domain)

    end

    def valid_changes
      @valid_changes ||= begin
                           {}.tap { |c|
                             c[:deletes] = [@a.to_api]
                             c[:additions] = [@new.to_api]
                             c[:upserts] = [@upsert_txt.to_api]
                           }
                         end
    end

    test 'apply changes' do
      ops, err = @domain.api_bulk valid_changes

      @domain.reload
      @aaaa.reload

      assert_empty err
      assert_empty @domain.records.where(id: @a.id)
      assert_equal '::42', @aaaa.content
      assert_equal 1, @domain.records.where(type: :mx).count
      assert_equal 2, ops[:additions].size # upsert is accounted as in addition
      assert_equal 1, ops[:deletes].size

    end

    test 'additions is invalid' do
      changes = {
        additions: [ @new.to_api.update(prio: -1) ]
      }

      ops, err = @domain.api_bulk changes

      assert_not_empty err
      assert_includes err[:additions].first[:error], 'not a valid DNS priority'
    end


    test 'delete not exists' do
      changes = Hash[
        :deletes, [{name: 'nx', type: 'TXT', content: 'not-exists'}]
      ]

      ops, err = @domain.api_bulk changes

      assert_empty ops
      assert_equal 1, err[:deletes].size
    end

    test 'upsert does not exist (single record)' do
      a1 = create(:a, domain: @domain, name: 'rr', content: '127.0.0.1')

      rr_name = "rr.#{@domain.name}"
      changes = Hash[
        :upserts, [{name: rr_name, type: 'A', content: '127.0.0.3'}]
      ]

      ops, err = @domain.api_bulk changes

      assert_empty err
      assert_equal 1, @domain.records.where(name: rr_name, type: 'A').count
      assert_equal '127.0.0.3', @domain.records.find_by(name: rr_name, type: 'A').content
    end

    test 'upsert does not exist (multiple records)' do
      a1 = create(:a, domain: @domain, name: 'rr', content: '127.0.0.1')
      a2 = create(:a, domain: @domain, name: 'rr', content: '127.0.0.2')

      rr_name = "rr.#{@domain.name}"
      changes = Hash[
        :upserts, [{name: rr_name, type: 'A', content: '127.0.0.3'}]
      ]

      ops, err = @domain.api_bulk changes

      assert_empty err
      assert_equal 1, @domain.records.where(name: rr_name, type: 'A').count
      assert_equal '127.0.0.3', @domain.records.find_by(name: rr_name, type: 'A').content
    end

    test 'upsert exists' do
      a1 = create(:a, domain: @domain, name: 'rr', content: '127.0.0.1')

      rr_name = "rr.#{@domain.name}"
      changes = Hash[
        :upserts, [{name: rr_name, type: 'A', content: '127.0.0.1'}]
      ]

      ops, err = @domain.api_bulk changes

      assert_empty err
      assert_empty ops # upsert is a noop
      assert_equal 1, @domain.records.where(name: rr_name, type: 'A').count
      assert_equal '127.0.0.1', @domain.records.find_by(name: rr_name, type: 'A').content
    end
  end
end
