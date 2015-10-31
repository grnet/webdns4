module Strategies
  module Incremental
    module_function

    def generate_serial(current_serial)
      current_serial + 1
    end
  end
end
