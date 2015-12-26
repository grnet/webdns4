require 'test_helper'

class NSTest < ActiveSupport::TestCase
  setup do
    @record = build(:ns)
  end

  test 'save' do
    @record.save

    assert_empty @record.errors
  end

  test 'chop terminating dot' do
    @record.content = 'with-dot.example.com.'
    @record.save!
    @record.reload

    assert_equal 'with-dot.example.com', @record.content
  end

  test 'drop privileges on zone NS records' do
    @record.drop_privileges = true
    @record.save

    assert_not_empty @record.errors[:name]
  end

  test 'doesnt drop privileges on non zone NS records' do
    @record.name = 'other'
    @record.drop_privileges = true

    @record.save

    assert_empty @record.errors[:name]
  end

  class ClasslessDelegation < ActiveSupport::TestCase
    setup do
      @record = build(:cd_ns, name: '192/29')
      @domain = @record.domain
    end

    test 'creates delegation' do
      assert @record.save
      assert @record.classless_delegation?

      octets = [192, 193, 194, 195, 196, 197, 198, 199]

      assert_equal octets.size, @domain.records.where(type: 'CNAME').count

      octets.each { |octet|
        cname = @domain.records.where(type: 'CNAME', name: "#{octet}.#{@domain.name}").first

        assert cname, "#{octet} delegation"
        assert_not cname.editable?, "#{octet} editable"
        assert cname.classless_delegated?, "#{octet} classless_delegated"
      }
    end

    test 'delete delegation' do
      assert @record.save

      @record.destroy
      assert_equal 0, @domain.records.where(type: 'CNAME').count, 'zero delegations'
    end

    [
      '0/24', # too big
      '0/32', # too small
      '191/29',
      '-192/29',
      '192/-29',
      '192/29/29',
      '192',
    ].each { |del|
      test "invalid delegation #{del}" do
        @record.name = del
        @record.save!
        assert_not @record.classless_delegation?

        assert_equal 0, @domain.records.where(type: 'CNAME').count, "0 CNAMEs for #{del}"
      end
    }

    test 'add errors when a record already exists' do
      create(:v4_ptr, domain: @domain, name: '194')

      assert_not @record.save, 'delegation with records should fail'
      assert_not_empty @record.errors[:name]
    end

    test 'allow second delegation with a different NS' do
      @record.save!

      assert_no_difference "@domain.records.where(type: 'CNAME').count" do
        NS.create!(domain: @domain, name: @record.name, content: 'ns-other.example.com')
      end
    end

    test 'drop records after all NS are deleted' do
      @record.save!
      second = NS.create!(domain: @domain, name: @record.name, content: 'ns-other.example.com')

      # CNAMEs are not deleted
      assert_no_difference '@domain.records.where(type: "CNAME").count' do
        second.destroy
      end

      # Deleting the last NS delegation should delete all CNAMEs
      @record.destroy
      assert_equal 0, @domain.records.where(type: 'CNAME').count, 'zero delegations'
    end
  end

  class ClasslessDelegationWithDash < ActiveSupport::TestCase
    setup do
      @record = build(:cd_ns, name: '192-29')
      @domain = @record.domain
    end

    test 'creates delegation' do
      assert @record.save
      assert @record.classless_delegation?

      octets = [192, 193, 194, 195, 196, 197, 198, 199]

      assert_equal octets.size, @domain.records.where(type: 'CNAME').count

      octets.each { |octet|
        cname = @domain.records.where(type: 'CNAME', name: "#{octet}.#{@domain.name}").first

        assert cname, "#{octet} delegation"
        assert_not cname.editable?, "#{octet} editable"
        assert cname.classless_delegated?, "#{octet} classless_delegated"
      }
    end

    test 'delete delegation' do
      assert @record.save

      @record.destroy
      assert_equal 0, @domain.records.where(type: 'CNAME').count, 'zero delegations'
    end

    [
      '0-24', # too big
      '0-32', # too small
      '191-29',
      '-192-29',
      '192--29',
      '192-29-29',
      '192',
    ].each { |del|
      test "invalid delegation #{del}" do
        @record.name = del
        @record.save!
        assert_not @record.classless_delegation?

        assert_equal 0, @domain.records.where(type: 'CNAME').count, "0 CNAMEs for #{del}"
      end
    }

    test 'add errors when a record already exists' do
      create(:v4_ptr, domain: @domain, name: '194')

      assert_not @record.save, 'delegation with records should fail'
      assert_not_empty @record.errors[:name]
    end

    test 'allow second delegation with a different NS' do
      @record.save!

      assert_no_difference "@domain.records.where(type: 'CNAME').count" do
        NS.create!(domain: @domain, name: @record.name, content: 'ns-other.example.com')
      end
    end

    test 'drop records after all NS are deleted' do
      @record.save!
      second = NS.create!(domain: @domain, name: @record.name, content: 'ns-other.example.com')

      # CNAMEs are not deleted
      assert_no_difference '@domain.records.where(type: "CNAME").count' do
        second.destroy
      end

      # Deleting the last NS delegation should delete all CNAMEs
      @record.destroy
      assert_equal 0, @domain.records.where(type: 'CNAME').count, 'zero delegations'
    end
  end
end
