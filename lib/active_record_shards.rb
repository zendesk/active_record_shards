require 'active_record'
require 'active_record/base'
require 'active_record_shards/connection_selection'
require 'active_record_shards/association_collection_connection_selection'
require 'active_record_shards/connection_pool'

ActiveRecord::Base.extend(ActiveRecordShards::ConnectionSelection)
ActiveRecord::Associations::AssociationCollection.send(:include, ActiveRecordShards::AssociationCollectionConnectionSelection)
