require 'aws_cloud_search'
require 'tinia/connection'
require 'tinia/exceptions'
require 'tinia/index'
require 'tinia/search'

if defined?(Rails)
  require 'tinia/railtie'
end

module Tinia

  def self.connection(domain = "default")
    @connections ||= {}
    @connections[domain] ||= AWSCloudSearch::CloudSearch.new(domain)
  end

  # activate for ActiveRecord
  def self.activate_active_record!
    ::ActiveRecord::Base.send(:extend, Tinia::ActiveRecord)
  end

  module ActiveRecord

    # activation method for an AR class
    def indexed_with_cloud_search(&block)
      mods = [
        Tinia::Connection,
        Tinia::Index,
        Tinia::Search
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
        raise Tinia::MissingSearchDomain.new(self)
      end
    end

  end

end