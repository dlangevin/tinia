require 'aws_cloud_search'
require 'cloud_search_rails/connection'
require 'cloud_search_rails/exceptions'
require 'cloud_search_rails/index'
require 'cloud_search_rails/search'

module CloudSearchRails

  def self.connection(domain = "default")
    @connections ||= {}
    @connections[domain] ||= AWSCloudSearch::CloudSearch.new(domain)
  end

  # activate for ActiveRecord
  def self.activate_active_record!
    ::ActiveRecord::Base.send(:extend, CloudSearchRails::ActiveRecord)
  end

  module ActiveRecord

    # activation method for an AR class
    def indexed_with_cloud_search(&block)
      mods = [
        CloudSearchRails::Connection,
        CloudSearchRails::Index,
        CloudSearchRails::Search
      ]
      mods.each do |mod|
        unless self.included_modules.include?(mod)
          self.send(:include, mod) 
        end
      end
      # config block
      yield(self) if block_given?

      # ensure config is all set
      unless self.cloud_search_domain.present?
        raise CloudSearchRails::MissingSearchDomain.new
      end
    end

  end

end