require 'active_model/errors'

module AssetCloud
  module Validations
    def self.included(base)
      base.extend ClassMethods
      base.class_eval do
        include AssetCloud::Callbacks

        alias_method_chain :store, :validation
      end
    end

    module ClassMethods
      def validate(*validations, &block)
        validations << block if block_given?
        write_inheritable_array(:validate, validations)
      end
    end

    def store_with_validation
      valid? ? store_without_validation : false
    end

    def errors
      @errors ||= ActiveModel::Errors.new(self)
    end

    def warnings
      @warnings ||= ActiveModel::Errors.new(self)
    end

    def valid?
      validate
      errors.empty?
    end

    def add_error(msg)
      errors.add(:base, msg)
    end

    def add_warning(*msgs)
      msgs.each do |msg|
        warnings.add(:base, msg)
      end
    end

    def validate
      errors.clear
      warnings.clear
      execute_callbacks(:validate, [])
    end
  end
end
