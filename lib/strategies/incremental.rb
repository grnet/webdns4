module Strategies
  module Incremental
    module_function

    # Generate a new incremental serial for the zone.
    #
    # Returns the new serial.
    def generate_serial(current_serial)
      current_serial + 1
    end
  end
end
