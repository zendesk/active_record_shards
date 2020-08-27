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
require 'active_record_shards/schema_dumper_extension'

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
ActiveRecord::Associations::Builder::HasAndBelongsToMany.include(ActiveRecordShards::DefaultReplicaPatches::Rails41HasAndBelongsToManyBuilderExtension)
ActiveRecord::SchemaDumper.prepend(ActiveRecordShards::SchemaDumperExtension)

case "#{ActiveRecord::VERSION::MAJOR}.#{ActiveRecord::VERSION::MINOR}"
when '4.2'
  require 'active_record_shards/patches-4-2'
when '5.0', '5.1', '5.2', '6.0'
  :ok
else
  raise "ActiveRecordShards is not compatible with #{ActiveRecord::VERSION::STRING}"
end

require 'active_record_shards/deprecation'

ActiveRecordShards::Deprecation.deprecate_methods(
  ActiveRecordShards::AssociationCollectionConnectionSelection,
  on_slave_if: :on_replica_if,
  on_slave_unless: :on_replica_unless,
  on_slave: :on_replica,
  on_master: :on_primary,
  on_master_if: :on_primary_if,
  on_master_unless: :on_primary_unless
)

ActiveRecordShards::Deprecation.deprecate_methods(
  ActiveRecordShards::ConnectionSwitcher,
  on_slave_if: :on_replica_if,
  on_slave_unless: :on_replica_unless,
  on_master_or_slave: :on_primary_or_replica,
  on_slave: :on_replica,
  on_master: :on_primary,
  on_master_if: :on_primary_if,
  on_master_unless: :on_primary_unless,
  on_slave?: :on_replica?
)

ActiveRecordShards::Deprecation.deprecate_methods(
  ActiveRecordShards::DefaultReplicaPatches,
  columns_with_force_slave: :columns_with_force_replica,
  table_exists_with_force_slave?: :table_exists_with_force_replica?,
  transaction_with_slave_off: :transaction_with_replica_off,
  on_slave_unless_tx: :on_replica_unless_tx
)

ActiveRecordShards::Deprecation.deprecate_methods(
  ActiveRecordShards::Model,
  on_slave_by_default?: :on_replica_by_default?,
  :on_slave_by_default= => :on_replica_by_default=
)

ActiveRecordShards::Deprecation.deprecate_methods(
  ActiveRecordShards::ShardSelection,
  on_slave?: :on_replica?,
  :on_slave= => :on_replica=
)
