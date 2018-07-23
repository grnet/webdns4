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
      @record.name = @record.domain.name.split(".")[0..-3].reverse.join(".") + ".1"
      assert @record.save

      assert_equal @record.name, "1." + @record.domain.name
    end

    test 'chop terminating dot' do
      @record.content = 'with-dot.example.com.'
      @record.save!
      @record.reload

      assert_equal 'with-dot.example.com', @record.content
    end

    test "name invalid" do
      rec = build(:v4_ptr, name: "195.")
      rec.valid?
      assert_not_empty rec.errors[:name], "name '195.' should be invalid"
    end

    test "name valid" do
      rec = build(:v4_ptr, name: "195")
      rec.valid?
      assert_empty rec.errors[:name], "name '195' should be valid"
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
      @record.name = '2001:db' + @record.domain.name.split(".")[0] + '::2'
      assert @record.save

      assert_equal '2.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.' + @record.domain.name,
                   @record.name
    end
  end

end
