# frozen_string_literal: true

module AssetCloud
  module Validations
    class << self
      def included(base)
        base.send(:alias_method, :store_without_validation, :store)
        base.extend(ClassMethods)
        base.prepend(PrependedMethods)
      end
    end

    module PrependedMethods
      def store
        validate
        errors.empty? ? super : false
      end
    end

    module ClassMethods
      def validate(*extra_validations, &block)
        validations = _callbacks[:validate] || []
        validations += extra_validations
        validations << block if block_given?

        self._callbacks = _callbacks.merge(validate: validations.freeze).freeze
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
