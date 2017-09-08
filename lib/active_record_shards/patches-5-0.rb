# frozen_string_literal: true



require 'active_record_shards/schema_dumper_extension'





ActiveRecord::Associations::Builder::HasAndBelongsToMany.include(ActiveRecordShards::DefaultSlavePatches::Rails41HasAndBelongsToManyBuilderExtension)

ActiveRecord::SchemaDumper.prepend(ActiveRecordShards::SchemaDumperExtension)

ActiveRecord::InternalMetadata.not_sharded
