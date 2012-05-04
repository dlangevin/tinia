require 'spec_helper'

describe Tinia::Index do

  before(:all) do

    conn = ActiveRecord::Base.connection

    conn.create_table(:mock_index_classes, :force => true) do |t|
      t.string(:name)
      t.timestamps
    end

    conn.create_table(:mock_index_with_datas, :force => true) do |t|
      t.string(:name)
      t.string(:type)
      t.timestamps
    end

    MockIndexClass = Class.new(ActiveRecord::Base) do
      indexed_with_cloud_search do |config|
        config.cloud_search_domain = "connection-mock"
      end
    end

    MockIndexWithData = Class.new(ActiveRecord::Base) do
      indexed_with_cloud_search do |config|
        config.cloud_search_domain = "mock-index-with-data"
      end
    end

  end

  shared_examples_for "batching" do

    it "should add a document to its batch, flushing each time" do

      doc = AWSCloudSearch::Document.new
      doc2 = AWSCloudSearch::Document.new

      batcher = AWSCloudSearch::DocumentBatcher.new(stub)
      batcher.expects(document_method).with(doc)
      batcher.expects(document_method).with(doc2)
      batcher.expects(:flush).twice

      MockIndexWithData.stubs(:cloud_search_document_batcher => batcher)

      MockIndexWithData.send(batch_method, doc)
      MockIndexWithData.send(batch_method, doc2)

    end

    it "should add a document to its batch flushing only at the end
      when within a cloud_search_batch_documents block" do


      doc = AWSCloudSearch::Document.new
      doc2 = AWSCloudSearch::Document.new

      batcher = AWSCloudSearch::DocumentBatcher.new(stub)
      batcher.expects(document_method).with(doc)
      batcher.expects(document_method).with(doc2)

      # exactly one 
      batcher.expects(:flush).once

      MockIndexWithData.stubs(:cloud_search_document_batcher => batcher)

      MockIndexWithData.cloud_search_batch_documents do
        MockIndexWithData.send(batch_method, doc)
        MockIndexWithData.send(batch_method, doc2)
      end

    end
  end

  context ".cloud_search_add_document" do

    let(:batch_method) do
      :cloud_search_add_document
    end

    let(:document_method) do
      :add_document
    end

    it_should_behave_like("batching")
  end

  context ".cloud_search_delete_document" do

    let(:batch_method) do
      :cloud_search_delete_document
    end

    let(:document_method) do
      :delete_document
    end

    it_should_behave_like("batching")
  end

  context ".cloud_search_domain" do

    it "should be an inheritable attribute" do
      NewKlass = Class.new(MockIndexWithData)
      NewKlass.cloud_search_domain.should eql(
        MockIndexWithData.cloud_search_domain
      )
    end

  end


  context ".cloud_search_reindex" do

    it "should reindex the entire collection" do
      mock_index_with_data = MockIndexWithData.new
      mock_index_with_data.expects(:add_to_cloud_search)

      MockIndexWithData.cloud_search_document_batcher.expects(:flush)
      MockIndexWithData.expects(:find_each)
        .with(:conditions => ["x = y"])
        .yields(mock_index_with_data)

      MockIndexWithData.cloud_search_reindex(:conditions => ["x = y"])
    end

  end


  context "#add_to_cloud_search" do

    it "should add a document to CloudSearch" do
      doc = AWSCloudSearch::Document.new

      mock_index_with_data = MockIndexWithData.new
      mock_index_with_data.stubs(:cloud_search_document => doc)

      MockIndexWithData.expects(:cloud_search_add_document).with(doc)

      # call add to cloud_search
      mock_index_with_data.add_to_cloud_search
    end
  end

  context "#cloud_search_data" do
    
    it "should define an empty cloud_search_data method" do
      MockIndexClass.new.cloud_search_data.should eql({})
    end

  end

  context "#cloud_search_document" do

    it "should provide a wrapper for the document that is indexed " do

      t = Time.now

      doc = AWSCloudSearch::Document.new
      doc.expects(:id=).with(8989)
      doc.expects(:lang=).with("en")
      doc.expects(:version=).with(t.to_i)
      doc.expects(:add_field).with("key", "val")
      doc.expects(:add_field).with("type", "MockIndexWithData")
      AWSCloudSearch::Document.stubs(:new => doc)

      mock_index_with_data = MockIndexWithData.new
      mock_index_with_data.stubs(
        :cloud_search_data => {:key => "val"},
        :id => 8989,
        :updated_at => t.to_i
      )
      mock_index_with_data.cloud_search_document.should eql(doc)
    end

  end

  context "#delete_from_cloud_search" do

    it "should remvoe a document from CloudSearch" do
      doc = AWSCloudSearch::Document.new

      mock_index_with_data = MockIndexWithData.new
      mock_index_with_data.stubs(:cloud_search_document => doc)

      MockIndexWithData.expects(:cloud_search_delete_document).with(doc)

      # call add to cloud_search
      mock_index_with_data.delete_from_cloud_search
    end

  end


end