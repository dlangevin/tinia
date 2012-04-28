module CloudSearchRails

  module Search
    def self.included(klass)
      klass.send(:extend, ClassMethods)
      klass.class_eval do 
        named_scope :cloud_search_rails_scope, lambda{|*ids|
          {
            :conditions => [
              "#{self.table_name}.#{self.primary_key} IN (?)", ids.flatten
            ]
          }
        }
      end
    end

    module ClassMethods
      
      # return a scope with the subset of ids
      def cloud_search(query = nil, &block)
        search_request = AWSCloudSearch::SearchRequest.new.tap do |req|
          req.q = query if query.present?
          yield(req) if block_given?
        end

        res =  self.cloud_search_connection.search(search_request)
        ids = res.hits.collect{|h| h["id"]}
        self.cloud_search_rails_scope(ids)
      end

    end
  end

end