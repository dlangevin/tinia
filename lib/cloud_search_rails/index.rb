module CloudSearchRails
  module Index

    def self.included(klass)
      klass.send(:include, InstanceMethods)
      klass.send(:extend, ClassMethods)
      klass.class_eval do
        cattr_accessor :in_cloud_search_batch_documents
        self.in_cloud_search_batch_documents = false

        # set up our callbacks
        after_save(:add_to_cloud_search)
        after_destroy(:delete_from_cloud_search)
      end
    end

    module InstanceMethods

      # add ourself as a document to CloudSearch
      def add_to_cloud_search
        self.class.cloud_search_add_document(
          self.cloud_search_document
        )
      end

      # empty implementation - re-implement 
      # or we might end up doing some meta-programming here
      def cloud_search_data
        {}
      end

      # wrapper for a fully formed AWSCloudSearch::Document
      def cloud_search_document
        AWSCloudSearch::Document.new.tap do |d|
          d.id = self.id
          d.lang = "en"
          d.version = self.updated_at.to_i
          # class name
          d.add_field("type", self.class.base_class.name)
          self.cloud_search_data.each_pair do |k,v|
            d.add_field(k.to_s, v.to_s)
          end
        end
      end

      # add ourself as a document to CloudSearch
      def delete_from_cloud_search
        self.class.cloud_search_delete_document(
          self.cloud_search_document
        )
      end

    end

    module ClassMethods

      # class method to add documents
      def cloud_search_add_document(doc)
        self.cloud_search_batcher_command(:add_document, doc)
      end

     # class method to add documents
      def cloud_search_delete_document(doc)
        self.cloud_search_batcher_command(:delete_document, doc)
      end

      # perform all add/delete operations within a buffered
      # DocumentBatcher
      def cloud_search_batch_documents(&block)
        begin
          self.in_cloud_search_batch_documents = true
          yield
          # final flush for any left over documents
          self.cloud_search_document_batcher.flush
        ensure
          self.in_cloud_search_batch_documents = false
        end
      end

      # reindex the entire collection
      def cloud_search_reindex(*args)
        self.cloud_search_batch_documents do
          self.find_each(*args) do |record|
            record.add_to_cloud_search
          end
        end
      end

      # new instance of AWSCloudSearch::DocumentBatcher
      def cloud_search_document_batcher
        @cloud_search_document_batcher ||= begin
          self.cloud_search_connection.new_batcher
        end
      end

      protected
      # send a command to the batcher and then conditionally flush
      # depending on whether we are in a cloud_search_batch_documents
      # block
      def cloud_search_batcher_command(command, doc)
        # send the command to our batcher
        self.cloud_search_document_batcher.send(command, doc)

        # if we are not in a batch_documents block, flush immediately
        unless self.in_cloud_search_batch_documents
          self.cloud_search_document_batcher.flush
        end
      end
    end

  end
end