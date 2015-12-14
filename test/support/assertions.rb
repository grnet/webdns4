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

  def assert_jobs
    max_id = Job.maximum(:id) || 0
    yield

    assert Job.maximum(:id) > max_id, 'No jobs inserted!'
  end
end

ActiveSupport::TestCase.include Assertions
