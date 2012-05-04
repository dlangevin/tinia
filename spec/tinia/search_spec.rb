require 'spec_helper'

describe Tinia::Search do

  before(:all) do

    conn = ActiveRecord::Base.connection
    conn.create_table(:mock_classes, :force => true) do |t|
      t.string("name")
      t.timestamps
    end

    MockClass = Class.new(ActiveRecord::Base) do
      indexed_with_cloud_search do |config|
        config.cloud_search_domain = "mock-class"
      end

      named_scope :name_like, lambda{|n|
        {:conditions => ["name LIKE ?", n]}
      }

    end

  end

  context "#cloud_search" do

    before(:each) do
      AWSCloudSearch::SearchRequest.stubs(:new => search_request)

      MockClass.cloud_search_connection
        .expects(:search)
        .with(search_request)
        .returns(stub({
          :hits => [
            {"id" => 1},
            {"id" => 2}
          ],
          :found => 300,
          :start => 0
        }))
    end

    let(:search_request) do
      search_request = AWSCloudSearch::SearchRequest.new
      search_request.expects(:bq=).with("(and 'my query' type:'MockClass')")
      search_request
    end

    it "should proxy its search request to cloud_search and return
      an Arel-like object" do

      proxy = MockClass.cloud_search("my query")
      proxy.proxy_options[:conditions].should eql(
        ["mock_classes.id IN (?)", [1, 2]]
      )
    end

    it "should be chainable, maintaining its meta_data" do
      proxy = MockClass.cloud_search("my query").name_like("name")
      proxy.current_page.should eql(1)
      proxy.offset.should eql(0)
    end

    context "#current_page" do

      it "should default to 1" do
        proxy = MockClass.cloud_search("my query")
        proxy.current_page.should eql(1)
      end

      it "should be able to be set" do
        search_request.expects(:start=).with(80)
        proxy = MockClass.cloud_search("my query", :page => 5)
        proxy.current_page.should eql(5)
      end

    end

    context "#offset" do

      it "should be able to compute its offset" do
        proxy = MockClass.cloud_search("my query", :page => 5)
        proxy.offset.should eql(80)
      end

    end

    context "#per_page" do

      it "should default to 20" do
        proxy = MockClass.cloud_search("my query")
        proxy.per_page.should eql(20)
      end

      it "should be able to be set" do
        search_request.expects(:size=).with(50)
        proxy = MockClass.cloud_search("my query", :per_page => 50)
        proxy.per_page.should eql(50)
      end

    end

    context "#total_entries" do
      
      it "should get it from its search_response" do
        proxy = MockClass.cloud_search("my query")
        proxy.total_entries.should eql(300)
      end

    end

    context "#total_pages" do
      
      it "should be the ceiling of its total_entries divided 
        by per_page" do
        proxy = MockClass.cloud_search("my query", :per_page => 7)
        proxy.total_pages.should eql(43)
      end

    end
  end
  
end