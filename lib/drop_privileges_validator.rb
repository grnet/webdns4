module ActiveModel
  module Validations
    class DropPrivilegesValidator < EachValidator
      def initialize(options)
        super
        setup!(options[:class])
      end

      # Add an error on the specified attribute if we are on drop privileges mode.
      def validate_each(record, attribute, _value)
        record.errors.add(attribute, options[:message]) if record.drop_privileges
      end

      private

      def setup!(klass)
        klass.send(:attr_reader, :drop_privileges) unless klass.method_defined?(:drop_privileges)
        klass.send(:attr_writer, :drop_privileges) unless klass.method_defined?(:drop_privileges=)
      end
    end

    module HelperMethods
      def validates_drop_privileges(*attr_names)
        validates_with DropPrivilegesValidator, _merge_attributes(attr_names)
      end
    end
  end
end
