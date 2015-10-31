module Assertions

  def assert_serial_update(soa)
    soa.reload

    old = soa.serial
    yield
    soa.reload

    assert soa.serial > old, "#{soa.serial} is not larger than #{old}!"
  end

  def freeze_time(&block)
    travel_to(Time.now, &block)
  end

end

ActiveSupport::TestCase.include Assertions
