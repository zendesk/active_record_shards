require 'active_record'
require 'active_record_shards/base'
require 'active_record_shards/association_collection'
require 'active_record_shards/connection_pool'

ActiveRecord::Base.extend ActiveRecord::Base::Replica
ActiveRecord::Associations::AssociationCollection.send(:include, ActiveRecord::Associations::AssociationCollection::Replica)
