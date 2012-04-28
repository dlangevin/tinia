module CloudSearchRails
  class Railtie < Rails::Railtie

    initializer "cloud_search_rails.activate" do
      CloudSearchRails.activate_active_record!
    end

  end
end