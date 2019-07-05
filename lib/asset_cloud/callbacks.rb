module AssetCloud
  module Callbacks
    extend ActiveSupport::Concern

    module ClassMethods
      def callback_methods(*symbols)
        symbols.each do |method|
          define_callbacks(method)
        end
      end

      def define_callbacks(method)
        before = :"before_#{method}"
        after = :"after_#{method}"
        extension_module.send(:define_method, method) do |*args, &block|
          result = nil
          if execute_callbacks(before, args)
            result = super(*args, &block)
            execute_callbacks(after, args)
          end
          result
        end

        define_singleton_method(before) do |*callbacks, &block|
          callbacks << block if block_given?
          write_inheritable_array(before, callbacks)
        end

        define_singleton_method(after) do |*callbacks, &block|
          callbacks << block if block_given?
          write_inheritable_array(after, callbacks)
        end
      end

      private

      def extension_module
        @extension_module ||= begin
          mod = Module.new
          self.const_set(:AssetCloudCallbacks, mod)
          prepend(mod)
          mod
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
