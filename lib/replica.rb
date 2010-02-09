require 'active_record'
require 'replica/base'
require 'replica/association_collection'
require 'replica/connection_pool'

ActiveRecord::Base.extend ActiveRecord::Base::Replica
ActiveRecord::Associations::AssociationCollection.send(:include, ActiveRecord::Associations::AssociationCollection::Replica)
