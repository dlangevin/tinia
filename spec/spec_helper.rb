$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))
require 'rspec'
require 'cloud_search_rails'
require 'active_record'
require 'mocha'

require 'ruby-debug'
Debugger.start

# Requires supporting files with custom matchers and macros, etc,
# in ./support/ and its subdirectories.
Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].each {|f| require f}

ActiveRecord::Base.establish_connection({
  "adapter" => "sqlite3",
  "database" => "/tmp/cloud_search_rails_test.sqlite"
})

CloudSearchRails.activate_active_record!

Mocha::Configuration.prevent(:stubbing_non_existent_method)

RSpec.configure do |config|
  config.mock_with :mocha
end
