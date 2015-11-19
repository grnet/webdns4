require 'test_helper'

class PTRTest < ActiveSupport::TestCase
  class V4PTRTest < ActiveSupport::TestCase
    setup do
      @record = build(:v4_ptr)
    end

    test 'save' do
      @record.save

      assert_empty @record.errors
    end

    test 'guess record' do
      @record.name = '192.0.2.1'
      assert @record.save

      assert_equal '1.2.0.192.in-addr.arpa', @record.name
    end

    test 'chop terminating dot' do
      @record.content = 'with-dot.example.com.'
      @record.save!
      @record.reload

      assert_equal 'with-dot.example.com', @record.content
    end
  end

  class V6PTRTest < ActiveSupport::TestCase
    setup do
      @record = build(:v6_ptr)
    end

    test 'save' do
      @record.save
      assert_empty @record.errors
    end

    test 'guess record' do
      @record.name = '2001:db8::2'
      assert @record.save

      assert_equal '2.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.8.b.d.0.1.0.0.2.ip6.arpa',
                   @record.name
    end
  end

end
