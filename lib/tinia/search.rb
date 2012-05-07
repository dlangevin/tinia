module Tinia

  module Search

    def self.included(klass)
      klass.send(:extend, ClassMethods)
      klass.class_eval do 
        # lambda block for the scope
        scope_def = lambda{|*ids|
          {
            :conditions => [
              "#{self.table_name}.#{self.primary_key} IN (?)", ids.flatten
            ]
          }
        }
        named_scope :tinia_scope, scope_def do 
          include WillPaginateMethods
        end
      end
    end

    # methods of WillPaginate compatibility
    module WillPaginateMethods
      
      attr_accessor :current_page, :per_page, :total_entries

      # the next page number
      def next_page
        self.current_page + 1
      end

      # calculated offset given the current page and the number
      # of entries per page
      def offset
        self.previous_page * self.per_page
      end

      # the previous page number
      def previous_page
        self.current_page - 1
      end
      
      # total number of pages  
      def total_pages
        (self.total_entries.to_f / self.per_page.to_f).ceil
      end

    end

    module ClassMethods
      
      # return a scope with the subset of ids
      def cloud_search(*args)
        opts = {:page => 1, :per_page => 20}
        opts = opts.merge(args.extract_options!)
        opts[:page] ||= 1
        query = args.first
        
        response = self.cloud_search_response(args.first, opts)
        ids = response.hits.collect{|h| h["id"]}

        proxy = self.tinia_scope(ids)
        proxy.per_page = opts[:per_page].to_i    
        proxy.current_page = opts[:page].to_i
        proxy.total_entries = response.found  
        proxy
      end

      protected

      # perform a query to CloudSearch and get a response
      def cloud_search_response(query, opts)
        self.cloud_search_connection.search(
          self.cloud_search_request(query, opts)
        )
      end

      # generate a request to CloudSearch
      def cloud_search_request(query, opts)
        AWSCloudSearch::SearchRequest.new.tap do |req|
          if query.nil?
            req.bq = "type:'#{self.base_class.name}'"
          # this is a rich query using Solr syntax of () or : or ''
          elsif query =~ /[:\)\(']/
            req.bq = "(and #{query} type:'#{self.base_class.name}')" 
          else
            req.bq = "(and '#{query}' type:'#{self.base_class.name}')" 
          end
          req.size = opts[:per_page].to_i
          req.start = (opts[:page].to_i - 1) * opts[:per_page].to_i
        end
      end

    end
  end

end