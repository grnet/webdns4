module Strategies
  module Date
    module_function

    # Generate a new date based serial.
    #
    # A serial is generate based on the current date where 2 digits
    # are held as a counter for changes that happen in the same date.
    # We also make sure that the new serial is larger than the previous
    # one.
    #
    # current_serial - The current zone zone serial.
    #
    # Returns the new serial.
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
