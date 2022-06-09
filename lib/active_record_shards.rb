# frozen_string_literal: true

require 'active_record'
require 'active_record/base'
require 'active_record_shards/configuration_parser'
require 'active_record_shards/model'
require 'active_record_shards/shard_selection'
require 'active_record_shards/configuration'
require 'active_record_shards/connection_switcher'
require 'active_record_shards/association_collection_connection_selection'
require 'active_record_shards/migration'
require 'active_record_shards/schema_dumper_extension'

module ActiveRecordShards
  def self.app_env
    env = Rails.env if defined?(Rails.env)
    env ||= RAILS_ENV if Object.const_defined?(:RAILS_ENV)
    env ||= ENV['RAILS_ENV']
    env ||= APP_ENV if Object.const_defined?(:APP_ENV)
    env ||= ENV['APP_ENV']
    env || 'development'
  end
end

module ConnectionRetrievalPatches
  cattr_accessor :ars_current_shard, :ars_current_role
  def current_shard
    return :default unless is_sharded?
    return :default if ActiveRecord::Base.ars_current_shard == :default

    if ActiveRecord::Base.ars_current_shard.nil?
      new_shard = super
    else
      new_shard = ActiveRecord::Base.ars_current_shard
    end
    return :default if new_shard == :default || new_shard.nil?

    ActiveRecordShards::Configuration.shard_id_map.fetch(new_shard.to_i)
  end
end

ActiveRecord::Base.singleton_class.prepend ConnectionRetrievalPatches
ActiveRecord::Base.extend(ActiveRecordShards::ConfigurationParser)
ActiveRecord::Base.extend(ActiveRecordShards::Model)
ActiveRecord::Base.extend(ActiveRecordShards::ConnectionSwitcher)
ActiveRecord::Associations::CollectionProxy.include(ActiveRecordShards::AssociationCollectionConnectionSelection)
ActiveRecord::SchemaDumper.prepend(ActiveRecordShards::SchemaDumperExtension)
ActiveRecord::Base.legacy_connection_handling = false
