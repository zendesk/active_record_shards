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
ActiveRecord::Base.extend(ActiveRecordShards::DefaultReplicaPatches)
ActiveRecord::Relation.include(ActiveRecordShards::DefaultReplicaPatches::ActiveRelationPatches)
ActiveRecord::Associations::CollectionProxy.include(ActiveRecordShards::AssociationCollectionConnectionSelection)
ActiveRecord::Associations::Builder::HasAndBelongsToMany.include(ActiveRecordShards::DefaultReplicaPatches::Rails41HasAndBelongsToManyBuilderExtension)
ActiveRecord::SchemaDumper.prepend(ActiveRecordShards::SchemaDumperExtension)

case "#{ActiveRecord::VERSION::MAJOR}.#{ActiveRecord::VERSION::MINOR}"
when '4.2'
  require 'active_record_shards/patches-4-2'

  # https://github.com/rails/rails/blob/v4.2.11.3/activerecord/lib/active_record/associations/association.rb#L97
  ActiveRecord::Associations::Association.prepend(ActiveRecordShards::DefaultReplicaPatches::AssociationsAssociationAssociationScopePatch)

  # https://github.com/rails/rails/blob/v4.2.11.3/activerecord/lib/active_record/associations/singular_association.rb#L44-L53
  ActiveRecord::Associations::SingularAssociation.prepend(ActiveRecordShards::DefaultReplicaPatches::AssociationsAssociationGetRecordsPatch)

  # https://github.com/rails/rails/blob/v4.2.11.3/activerecord/lib/active_record/associations/collection_association.rb#L447-L456
  ActiveRecord::Associations::CollectionAssociation.prepend(ActiveRecordShards::DefaultReplicaPatches::AssociationsAssociationGetRecordsPatch)

  # https://github.com/rails/rails/blob/v4.2.11.3/activerecord/lib/active_record/associations/preloader/association.rb#L89
  ActiveRecord::Associations::Preloader::Association.prepend(ActiveRecordShards::DefaultReplicaPatches::AssociationsPreloaderAssociationAssociatedRecordsByOwnerPatch)
when '5.0'
  # https://github.com/rails/rails/blob/v5.0.7/activerecord/lib/active_record/associations/association.rb#L97
  ActiveRecord::Associations::Association.prepend(ActiveRecordShards::DefaultReplicaPatches::AssociationsAssociationAssociationScopePatch)

  # https://github.com/rails/rails/blob/v5.0.7/activerecord/lib/active_record/associations/singular_association.rb#L56-L65
  ActiveRecord::Associations::SingularAssociation.prepend(ActiveRecordShards::DefaultReplicaPatches::AssociationsAssociationGetRecordsPatch)

  # https://github.com/rails/rails/blob/v5.0.7/activerecord/lib/active_record/associations/collection_association.rb#L442-L451
  ActiveRecord::Associations::CollectionAssociation.prepend(ActiveRecordShards::DefaultReplicaPatches::AssociationsAssociationGetRecordsPatch)

  # https://github.com/rails/rails/blob/v5.0.7/activerecord/lib/active_record/associations/preloader/association.rb#L120
  ActiveRecord::Associations::Preloader::Association.prepend(ActiveRecordShards::DefaultReplicaPatches::AssociationsPreloaderAssociationLoadRecordsPatch)
when '5.1'
  # https://github.com/rails/rails/blob/v5.1.7/activerecord/lib/active_record/associations/association.rb#L97
  ActiveRecord::Associations::Association.prepend(ActiveRecordShards::DefaultReplicaPatches::AssociationsAssociationAssociationScopePatch)

  # https://github.com/rails/rails/blob/v5.1.7/activerecord/lib/active_record/associations/singular_association.rb#L41
  ActiveRecord::Associations::SingularAssociation.prepend(ActiveRecordShards::DefaultReplicaPatches::AssociationsAssociationFindTargetPatch)

  # https://github.com/rails/rails/blob/v5.1.7/activerecord/lib/active_record/associations/collection_association.rb#L305
  ActiveRecord::Associations::CollectionAssociation.prepend(ActiveRecordShards::DefaultReplicaPatches::AssociationsAssociationFindTargetPatch)

  # https://github.com/rails/rails/blob/v5.1.7/activerecord/lib/active_record/associations/preloader/association.rb#L120
  ActiveRecord::Associations::Preloader::Association.prepend(ActiveRecordShards::DefaultReplicaPatches::AssociationsPreloaderAssociationLoadRecordsPatch)
when '5.2'
  # https://github.com/rails/rails/blob/v5.2.6/activerecord/lib/active_record/relation.rb#L530
  # But the #exec_queries method also calls #connection, and I don't know if we should patch that one, too...
  ActiveRecord::Relation.prepend(ActiveRecordShards::DefaultReplicaPatches::Rails52RelationPatches)

  # https://github.com/rails/rails/blob/v5.2.6/activerecord/lib/active_record/associations/singular_association.rb#L42
  ActiveRecord::Associations::SingularAssociation.prepend(ActiveRecordShards::DefaultReplicaPatches::AssociationsAssociationFindTargetPatch)

  # https://github.com/rails/rails/blob/v5.2.6/activerecord/lib/active_record/associations/collection_association.rb#L308
  ActiveRecord::Associations::CollectionAssociation.prepend(ActiveRecordShards::DefaultReplicaPatches::AssociationsAssociationFindTargetPatch)

  # https://github.com/rails/rails/blob/v5.2.6/activerecord/lib/active_record/associations/preloader/association.rb#L96
  ActiveRecord::Associations::Preloader::Association.prepend(ActiveRecordShards::DefaultReplicaPatches::AssociationsPreloaderAssociationLoadRecordsPatch)
when '6.0'
  # https://github.com/rails/rails/blob/v6.0.4/activerecord/lib/active_record/type_caster/connection.rb#L28
  ActiveRecord::TypeCaster::Connection.prepend(ActiveRecordShards::DefaultReplicaPatches::TypeCasterConnectionConnectionPatch)

  # https://github.com/rails/rails/blob/v6.0.4/activerecord/lib/active_record/schema.rb#L53-L54
  ActiveRecord::Schema.prepend(ActiveRecordShards::DefaultReplicaPatches::SchemaDefinePatch)

  # https://github.com/rails/rails/blob/v6.0.4/activerecord/lib/active_record/relation.rb#L739
  # But the #exec_queries and #compute_cache_version methods also call #connection, and I don't know if we should patch those, too...
  ActiveRecord::Relation.prepend(ActiveRecordShards::DefaultReplicaPatches::Rails52RelationPatches)

  # https://github.com/rails/rails/blob/v6.0.4/activerecord/lib/active_record/associations/association.rb#L213
  ActiveRecord::Associations::Association.prepend(ActiveRecordShards::DefaultReplicaPatches::AssociationsAssociationFindTargetPatch)
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
