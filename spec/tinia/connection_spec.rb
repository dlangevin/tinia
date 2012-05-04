require 'spec_helper'

describe Tinia::Connection do

  before(:each) do

    ConnectionMock = Class.new(ActiveRecord::Base) do
      indexed_with_cloud_search do |config|
        config.cloud_search_domain = "connection-mock"
      end
    end

  end
  
  context ".cloud_search_connection" do

    it "should get a namespaced connection" do
      ConnectionMock.stubs(:cloud_search_domain => "connection-mock")
      Tinia.expects(:connection).with("connection-mock")
      ConnectionMock.cloud_search_connection
    end

  end

  context ".cloud_search_domain" do

    it "should provide a setter and getter" do
      ConnectionMock.cloud_search_domain = "123"
      ConnectionMock.cloud_search_domain.should eql "123"

      ConnectionMock2 = Class.new(ConnectionMock)
      ConnectionMock2.cloud_search_domain.should eql "123"      
    end

    it "should raise an error if cloud_search_domain is not defined" do

      lambda{
        ErrorMock = Class.new(ActiveRecord::Base) do
          indexed_with_cloud_search
        end
      }.should raise_error(Tinia::MissingSearchDomain)
    end

  end

end