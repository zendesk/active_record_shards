require 'active_record'
require 'active_record/base'
require 'active_record_shards/configuration_parser'
require 'active_record_shards/model'
require 'active_record_shards/shard_selection'
require 'active_record_shards/connection_switcher'
require 'active_record_shards/association_collection_connection_selection'
require 'active_record_shards/connection_pool'
require 'active_record_shards/migration'

ActiveRecord::Base.extend(ActiveRecordShards::ConfigurationParser)
ActiveRecord::Base.extend(ActiveRecordShards::Model)
ActiveRecord::Base.extend(ActiveRecordShards::ConnectionSwitcher)
ActiveRecord::Associations::AssociationCollection.send(:include, ActiveRecordShards::AssociationCollectionConnectionSelection)

module ActiveRecordShards
  def self.rails_env
    Kernel.const_defined?(:Rails) ? Rails.env : RAILS_ENV
  end
end
