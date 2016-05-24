# frozen_string_literal: true
require 'active_record'
require 'active_record/base'
require 'active_record_shards/configuration_parser'
require 'active_record_shards/model'
require 'active_record_shards/shard_selection'
require 'active_record_shards/connection_switcher'
require 'active_record_shards/association_collection_connection_selection'
require 'active_record_shards/migration'
require 'active_record_shards/default_slave_patches'
require 'active_record_shards/schema_dumper_extension'

ActiveRecord::Base.extend(ActiveRecordShards::ConfigurationParser)
ActiveRecord::Base.extend(ActiveRecordShards::Model)
ActiveRecord::Base.extend(ActiveRecordShards::ConnectionSwitcher)
ActiveRecord::Base.extend(ActiveRecordShards::DefaultSlavePatches)

if ActiveRecord.const_defined?(:Relation)
  ActiveRecord::Relation.send(:include, ActiveRecordShards::DefaultSlavePatches::ActiveRelationPatches)
end

if ActiveRecord::Associations.const_defined?(:Preloader) && ActiveRecord::Associations::Preloader.const_defined?(:HasAndBelongsToMany)
  ActiveRecord::Associations::Preloader::HasAndBelongsToMany.send(:include, ActiveRecordShards::DefaultSlavePatches::HasAndBelongsToManyPreloaderPatches)
end

if ActiveRecord::VERSION::STRING >= '4.1.0'
  ActiveRecord::Associations::Builder::HasAndBelongsToMany.send(:include, ActiveRecordShards::DefaultSlavePatches::Rails41HasAndBelongsToManyBuilderExtension)
end

ActiveRecord::Associations::CollectionProxy.send(:include, ActiveRecordShards::AssociationCollectionConnectionSelection)

if ActiveRecord::VERSION::MAJOR >= 4
  ActiveRecord::SchemaDumper.send(:prepend, ActiveRecordShards::SchemaDumperExtension)
end

module ActiveRecordShards
  def self.rails_env
    env = Rails.env if defined?(Rails.env)
    env ||= RAILS_ENV if Object.const_defined?(:RAILS_ENV)
    env ||= ENV['RAILS_ENV']
    env ||= 'development'
  end
end

