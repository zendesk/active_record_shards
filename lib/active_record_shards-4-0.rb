# frozen_string_literal: true
require 'active_record_shards/schema_dumper_extension'

ActiveRecordShards::ConnectionSpecification = ActiveRecord::ConnectionAdapters::ConnectionSpecification
methods_to_override = [:establish_connection, :remove_connection, :pool_for, :pool_from_any_process_for]
ActiveRecordShards.override_connection_handler_methods(methods_to_override)

ActiveRecord::Associations::Preloader::HasAndBelongsToMany.include(ActiveRecordShards::DefaultSlavePatches::HasAndBelongsToManyPreloaderPatches)

ActiveRecord::SchemaDumper.prepend(ActiveRecordShards::SchemaDumperExtension)
