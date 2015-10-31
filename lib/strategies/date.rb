module Strategies
  module Date
    module_function

    def generate_serial(current_serial)
      # Optimization for the case that current_serial is a lot larger
      # than the generated serial
      new = [
        Time.now.strftime('%Y%m%d00').to_i,
        current_serial
      ].max

      # Increment until we find a spot
      new += 1 while new <= current_serial

      new
    end
  end
end
