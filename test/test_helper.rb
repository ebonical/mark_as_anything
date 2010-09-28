path = File.dirname(__FILE__)

# additional require load paths
$:.unshift(File.join(path, '/..'))
$:.unshift(File.join(path, '/../lib'))

require "rubygems"
require "test/unit"
require "active_record"
require "active_record/fixtures"
require "active_support"
require "active_support/test_case"
require "init"

config = YAML.load_file(File.join(path, 'database.yml'))
schema_file = File.join(path, 'schema.rb')

ActiveRecord::Base.configurations = config
ActiveRecord::Base.establish_connection(config['test'])

load(schema_file) if File.exist?(schema_file)


class ActiveSupport::TestCase #:nodoc:
    # Turn off transactional fixtures if you're working with MyISAM tables in MySQL
    # self.use_transactional_fixtures = true
  
    # Instantiated fixtures are slow, but give you @david where you otherwise would need people(:david)
    # self.use_instantiated_fixtures  = true

    # Add more helper methods to be used by all tests here...
end
