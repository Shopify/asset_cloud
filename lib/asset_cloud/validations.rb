module AssetCloud
  module Validations
    def self.included(base)
      base.send(:alias_method, :store_without_validation, :store)
      base.extend(ClassMethods)
      base.prepend(PrependedMethods)
    end

    module PrependedMethods
      def store
        validate
        errors.empty? ? super : false
      end
    end

    module ClassMethods
      def validate(*validations, &block)
        validations << block if block_given?
        write_inheritable_array(:validate, validations)
      end
    end

    def errors
      @errors ||= []
    end

    def warnings
      @warnings ||= []
    end

    def valid?
      validate
      errors.empty?
    end

    def add_error(msg)
      errors << msg
      errors.uniq!
    end

    def add_warning(*msgs)
      warnings.concat(msgs)
    end

    def validate
      errors.clear
      warnings.clear
      execute_callbacks(:validate, [])
    end
  end
end
