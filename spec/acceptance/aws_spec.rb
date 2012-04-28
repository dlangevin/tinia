require 'spec_helper'

describe "AWS" do

  before(:all) do

    conn = ActiveRecord::Base.connection
    conn.create_table(:clients, :force => true) do |t|
      t.string(:first_name)
      t.string(:last_name)
      t.string(:email)
      t.timestamps
    end

    Client = Class.new(ActiveRecord::Base) do
      indexed_with_cloud_search do |config|
        config.cloud_search_domain = "client-4wwi2n4ghrnro46w2adiw2temy"
      end

      def cloud_search_data
        self.attributes
      end

    end

    Client.create(
      :first_name => "Dan",
      :last_name => "Langevin",
      :email => "test@test.com"
    )
  end

  after(:all) do
    Client.all.each(&:destroy)
  end

  it "should be able to index and search records" do

    Client.cloud_search_reindex
    c = Client.cloud_search("Dan Langevin").first
    c.should be_instance_of(Client)

  end

end