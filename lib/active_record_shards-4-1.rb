# frozen_string_literal: true
require 'active_record_shards/connection_pool'
require 'active_record_shards/configuration_parser'
require 'active_record_shards/model'
require 'active_record_shards/shard_selection'
require 'active_record_shards/connection_switcher'
require 'active_record_shards/migration'
require 'active_record_shards/default_slave_patches'
require 'active_record_shards/association_collection_connection_selection'
require 'active_record_shards/connection_handler'
require 'active_record_shards/connection_specification'
require 'active_record_shards/schema_dumper_extension'

ActiveRecordShards::ConnectionSpecification = ActiveRecord::ConnectionAdapters::ConnectionSpecification
methods_to_override = [:establish_connection, :remove_connection, :pool_for, :pool_from_any_process_for]
ActiveRecordShards.override_connection_handler_methods(methods_to_override)

ActiveRecord::Base.extend(ActiveRecordShards::ConfigurationParser)
ActiveRecord::Base.extend(ActiveRecordShards::Model)
ActiveRecord::Base.extend(ActiveRecordShards::ConnectionSwitcher)

ActiveRecord::Base.extend(ActiveRecordShards::DefaultSlavePatches)
ActiveRecord::Relation.include(ActiveRecordShards::DefaultSlavePatches::ActiveRelationPatches)
ActiveRecord::Associations::Builder::HasAndBelongsToMany.include(ActiveRecordShards::DefaultSlavePatches::Rails41HasAndBelongsToManyBuilderExtension)

ActiveRecord::Associations::CollectionProxy.include(ActiveRecordShards::AssociationCollectionConnectionSelection)

ActiveRecord::SchemaDumper.prepend(ActiveRecordShards::SchemaDumperExtension)

ActiveRecord::Base.singleton_class.class_eval do
  def establish_connection_with_connection_pool_name(spec = nil)
    case spec
    when ActiveRecordShards::ConnectionSpecification
      connection_handler.establish_connection(connection_pool_name, spec)
    else
      establish_connection_without_connection_pool_name(spec)
    end
  end
  alias_method :establish_connection_without_connection_pool_name, :establish_connection
  alias_method :establish_connection, :establish_connection_with_connection_pool_name
end
