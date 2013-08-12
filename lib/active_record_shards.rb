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
require 'active_record_shards/arel_engine'
require 'active_record_shards/connection_handler'

if ActiveRecord::VERSION::STRING >= "3.2.0"
  require 'active_record_shards/connection_specification'
end

if ActiveRecord::VERSION::STRING >= "4.0.0"
  methods_to_override = [:establish_connection, :remove_connection, :pool_for,
                         :pool_from_any_process_for]
  ActiveRecordShards::ConnectionSpecification = ActiveRecord::ConnectionAdapters::ConnectionSpecification
else
  methods_to_override = [:remove_connection]
  ActiveRecordShards::ConnectionSpecification = ActiveRecord::Base::ConnectionSpecification
end

ActiveRecordShards.override_connection_handler_methods(methods_to_override)

ActiveRecord::Base.extend(ActiveRecordShards::ConfigurationParser)
ActiveRecord::Base.extend(ActiveRecordShards::Model)
ActiveRecord::Base.extend(ActiveRecordShards::ConnectionSwitcher)
ActiveRecord::Base.extend(ActiveRecordShards::DefaultSlavePatches)

if ActiveRecord.const_defined?(:Relation)
  ActiveRecord::Relation.send(:include, ActiveRecordShards::DefaultSlavePatches::ActiveRelationPatches)
end

if ActiveRecord::VERSION::STRING >= "3.1.0"
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

ActiveRecord::Base.singleton_class.class_eval do
  def establish_connection_with_connection_pool_name(spec = nil)
    case spec
    when ActiveRecordShards::ConnectionSpecification
      connection_handler.establish_connection(connection_pool_name, spec)
    else
      establish_connection_without_connection_pool_name(spec)
    end
  end
  alias_method_chain :establish_connection, :connection_pool_name
end
