require 'active_record'
require 'active_record/base'
require 'active_record_shards/shard_selection'
require 'active_record_shards/connection_switcher'
require 'active_record_shards/association_collection_connection_selection'
require 'active_record_shards/connection_pool'

ActiveRecord::Base.extend(ActiveRecordShards::ConnectionSwitcher)
ActiveRecord::Associations::AssociationCollection.send(:include, ActiveRecordShards::AssociationCollectionConnectionSelection)
