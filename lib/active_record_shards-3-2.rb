# frozen_string_literal: true


ActiveRecordShards::ConnectionSpecification = ActiveRecord::Base::ConnectionSpecification
methods_to_override = [:remove_connection]
ActiveRecordShards.override_connection_handler_methods(methods_to_override)

ActiveRecord::Associations::Preloader::HasAndBelongsToMany.include(ActiveRecordShards::DefaultSlavePatches::HasAndBelongsToManyPreloaderPatches)
