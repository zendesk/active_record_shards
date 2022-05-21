# frozen_string_literal: true

require 'active_record'
require 'active_record/base'
require 'active_record_shards/configuration_parser'
require 'active_record_shards/model'
require 'active_record_shards/shard_selection'
require 'active_record_shards/connection_switcher'
require 'active_record_shards/association_collection_connection_selection'
require 'active_record_shards/migration'
require 'active_record_shards/schema_dumper_extension'

module ActiveRecordShards
  def self.app_env
    env = Rails.env if defined?(Rails.env)
    env ||= RAILS_ENV if Object.const_defined?(:RAILS_ENV)
    env ||= ENV['RAILS_ENV']
    env ||= APP_ENV if Object.const_defined?(:APP_ENV)
    env ||= ENV['APP_ENV']
    env || 'development'
  end
end

ActiveRecord::Base.extend(ActiveRecordShards::ConfigurationParser)
ActiveRecord::Base.extend(ActiveRecordShards::Model)
ActiveRecord::Base.extend(ActiveRecordShards::ConnectionSwitcher)
ActiveRecord::Associations::CollectionProxy.include(ActiveRecordShards::AssociationCollectionConnectionSelection)
ActiveRecord::SchemaDumper.prepend(ActiveRecordShards::SchemaDumperExtension)
