require 'active_record'
require 'active_record/base'
require 'active_record_shards/configuration_parser'
require 'active_record_shards/model'
require 'active_record_shards/shard_selection'
require 'active_record_shards/connection_switcher'
require 'active_record_shards/association_collection_connection_selection'
require 'active_record_shards/connection_pool'
require 'active_record_shards/migration'
require 'active_record_shards/default_slave_patches'

if ActiveRecord::VERSION::MAJOR >= 3 && ActiveRecord::VERSION::MINOR >= 2
  require 'active_record_shards/connection_specification'
end

ActiveRecord::Base.extend(ActiveRecordShards::ConfigurationParser)
ActiveRecord::Base.extend(ActiveRecordShards::Model)
ActiveRecord::Base.extend(ActiveRecordShards::ConnectionSwitcher)
ActiveRecord::Base.extend(ActiveRecordShards::DefaultSlavePatches)

if ActiveRecord::VERSION::MAJOR >= 3 && ActiveRecord::VERSION::MINOR >= 1
  ActiveRecord::Associations::CollectionProxy.send(:include, ActiveRecordShards::AssociationCollectionConnectionSelection)
else
  ActiveRecord::Associations::AssociationCollection.send(:include, ActiveRecordShards::AssociationCollectionConnectionSelection)
end

module ActiveRecordShards
  def self.rails_env
    env = Rails.env if Object.const_defined?(:Rails)
    env ||= RAILS_ENV if Object.const_defined?(:RAILS_ENV)
    env ||= ENV['RAILS_ENV']
  end
end
