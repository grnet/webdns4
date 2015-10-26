module Assertions

  def assert_serial_update(soa, message=nil)
    soa.reload
    assert_difference 'soa.serial', 1, message do
      yield
      soa.reload
    end
  end

end

ActiveSupport::TestCase.include Assertions
