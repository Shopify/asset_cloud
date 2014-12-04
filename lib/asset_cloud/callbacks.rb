require 'class_inheritable_attributes'

module AssetCloud
  module Callbacks
    extend ActiveSupport::Concern

    module ClassMethods
      def callback_methods(*symbols)
        symbols.each do |method|
          code = <<-"end_eval"
           def self.before_#{method}(*callbacks, &block)
             callbacks << block if block_given?
             write_inheritable_array(:before_#{method}, callbacks)
           end

           def self.after_#{method}(*callbacks, &block)
             callbacks << block if block_given?
             write_inheritable_array(:after_#{method}, callbacks)
           end

           def #{method}_with_callbacks(*args)
             if execute_callbacks(:before_#{method}, args)
               result = #{method}_without_callbacks(*args)
               execute_callbacks(:after_#{method}, args)
             end
             result
           end

           alias_method_chain :#{method}, 'callbacks'
          end_eval

          self.class_eval code, __FILE__, __LINE__
        end
      end
    end

    def execute_callbacks(symbol, args)
      callbacks_for(symbol).each do |callback|

        result = case callback
        when Symbol
          self.send(callback, *args)
        when Proc, Method
          callback.call(self, *args)
        else
          if callback.respond_to?(method)
            callback.send(method, self, *args)
          else
            raise StandardError, "Callbacks must be a symbol denoting the method to call, a string to be evaluated, a block to be invoked, or an object responding to the callback method."
          end
        end
        return false if result == false
      end
      true
    end

    def callbacks_for(symbol)
      self.class.send(symbol) || []
    end
  end
end
