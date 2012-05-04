module Tinia
  class Railtie < Rails::Railtie

    initializer "tinia.activate" do
      Tinia.activate_active_record!
    end

  end
end