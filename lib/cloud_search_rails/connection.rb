module CloudSearchRails
  module Connection

    def self.included(klass)
      klass.send(:extend, ClassMethods)
      klass.class_eval do
        class_inheritable_accessor :cloud_search_domain
      end
    end

    module ClassMethods

      # accessor for the cloud search connection
      def cloud_search_connection
        @cloud_search_connection ||= begin
          CloudSearchRails.connection(
            self.cloud_search_domain
          )
        end
      end

    end
  end
end