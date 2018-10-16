# frozen_string_literal: true
require 'active_record_shards/connection_pool'
require 'active_record_shards/connection_handler'
require 'active_record_shards/connection_specification'


ActiveRecordShards::ConnectionSpecification = ActiveRecord::Base::ConnectionSpecification
methods_to_override = [:remove_connection]
ActiveRecordShards.override_connection_handler_methods(methods_to_override)

ActiveRecord::Associations::Preloader::HasAndBelongsToMany.include(ActiveRecordShards::DefaultReplicaPatches::HasAndBelongsToManyPreloaderPatches)
