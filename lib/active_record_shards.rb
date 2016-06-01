# frozen_string_literal: true
require 'active_record'
require 'active_record/base'

module ActiveRecordShards
  def self.rails_env
    env = Rails.env if defined?(Rails.env)
    env ||= RAILS_ENV if Object.const_defined?(:RAILS_ENV)
    env ||= ENV['RAILS_ENV']
    env ||= 'development'
  end
end

case "#{ActiveRecord::VERSION::MAJOR}.#{ActiveRecord::VERSION::MINOR}"
when '3.2'
  require 'active_record_shards-3-2'
when '4.0'
  require 'active_record_shards-4-0'
when '4.1', '4.2', '5.0'
  require 'active_record_shards-4-1'
end
