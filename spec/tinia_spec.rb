require "spec_helper"

describe Tinia do
  
  context "#connection" do
    
    it "should get an instance of connection" do
      Tinia.connection.should be_instance_of(
        AWSCloudSearch::CloudSearch
      )
    end

    it "should be able to configure its connection's domain" do
      AWSCloudSearch::CloudSearch.expects(:new).with("domain")
      Tinia.connection("domain")
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
        Tinia::Connection,
        Tinia::Index,
        Tinia::Search
      ]
      mods.each do |mod|
        Indexed.included_modules.should include mod
      end
    end
  end

end
