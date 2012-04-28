require "spec_helper"

describe CloudSearchRails do
  
  context "#connection" do
    
    it "should get an instance of connection" do
      CloudSearchRails.connection.should be_instance_of(
        AWSCloudSearch::CloudSearch
      )
    end

    it "should be able to configure its connection's domain" do
      AWSCloudSearch::CloudSearch.expects(:new).with("domain")
      CloudSearchRails.connection("domain")
    end
  end

  context "#indexed_with_cloud_search" do

    it "should include the appropriate modules" do

      Indexed = Class.new(ActiveRecord::Base) 

      Indexed.expects(:after_save).with(:add_to_cloud_search)
      Indexed.expects(:after_destroy).with(:delete_from_cloud_search)

      Indexed.class_eval do
        indexed_with_cloud_search do |config|
          config.cloud_search_domain = "connection-mock"
        end
      end

      mods = [
        CloudSearchRails::Connection,
        CloudSearchRails::Index,
        CloudSearchRails::Search
      ]
      mods.each do |mod|
        Indexed.included_modules.should include mod
      end
    end
  end

end
