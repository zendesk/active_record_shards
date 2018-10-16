# frozen_string_literal: true
require 'active_record'
require 'active_record/base'
require 'active_record_shards/configuration_parser'
require 'active_record_shards/model'
require 'active_record_shards/shard_selection'
require 'active_record_shards/connection_switcher'
require 'active_record_shards/association_collection_connection_selection'
require 'active_record_shards/migration'
require 'active_record_shards/default_replica_patches'

module ActiveRecordShards
  def self.rails_env
    env = Rails.env if defined?(Rails.env)
    env ||= RAILS_ENV if Object.const_defined?(:RAILS_ENV)
    env ||= ENV['RAILS_ENV']
    env || 'development'
  end
end

ActiveRecord::Base.extend(ActiveRecordShards::ConfigurationParser)
ActiveRecord::Base.extend(ActiveRecordShards::Model)
ActiveRecord::Base.extend(ActiveRecordShards::ConnectionSwitcher)
ActiveRecord::Base.extend(ActiveRecordShards::DefaultReplicaPatches)
ActiveRecord::Relation.include(ActiveRecordShards::DefaultReplicaPatches::ActiveRelationPatches)
ActiveRecord::Associations::CollectionProxy.include(ActiveRecordShards::AssociationCollectionConnectionSelection)

case "#{ActiveRecord::VERSION::MAJOR}.#{ActiveRecord::VERSION::MINOR}"
when '3.2'
  require 'active_record_shards/patches-3-2'
when '4.2'
  require 'active_record_shards/patches-4-2'
when '5.0', '5.1', '5.2'
  require 'active_record_shards/patches-5-0'
else
  raise "ActiveRecordShards is not compatible with #{ActiveRecord::VERSION::STRING}"
end
