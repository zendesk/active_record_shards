# frozen_string_literal: true

require_relative 'helper'

describe 'ActiveRecordShards' do
  describe '.app_env' do
    before do
      if defined?(Rails) || defined?(APP_ENV) || ENV['APP_ENV']
        raise "Tests in #{__FILE__} will overwrite environment constants, please update them to avoid conflicts"
      end

      @env_rails_env_before = ENV['RAILS_ENV']
      ENV.delete('RAILS_ENV')

      @rails_env_before = RAILS_ENV
      Object.send(:remove_const, 'RAILS_ENV')
    end

    after do
      ENV['RAILS_ENV'] = @env_rails_env_before if @env_rails_env_before
      Object.const_set('RAILS_ENV', @rails_env_before) if @rails_env_before
    end

    describe 'Rails.env' do
      before do
        class Rails
          def self.env
            'environment from Rails.env'
          end
        end
      end

      after { Object.send(:remove_const, 'Rails') }

      it 'looks for Rails.env' do
        assert_equal 'environment from Rails.env', ActiveRecordShards.app_env
      end
    end

    describe 'RAILS_ENV' do
      before { Object.const_set('RAILS_ENV', 'environment from RAILS_ENV') }
      after { Object.send(:remove_const, 'RAILS_ENV') }

      it 'looks for RAILS_ENV' do
        assert_equal 'environment from RAILS_ENV', ActiveRecordShards.app_env
      end
    end

    describe "ENV['RAILS_ENV']" do
      before { ENV['RAILS_ENV'] = "environment from ENV['RAILS_ENV']" }
      after { ENV.delete('RAILS_ENV') }

      it 'looks for RAILS_ENV' do
        assert_equal "environment from ENV['RAILS_ENV']", ActiveRecordShards.app_env
      end
    end

    describe 'APP_ENV' do
      before { Object.const_set('APP_ENV', 'environment from APP_ENV') }
      after { Object.send(:remove_const, 'APP_ENV') }

      it 'looks for APP_ENV' do
        assert_equal 'environment from APP_ENV', ActiveRecordShards.app_env
      end
    end

    describe "ENV['APP_ENV']" do
      before { ENV['APP_ENV'] = "environment from ENV['APP_ENV']" }
      after { ENV.delete('APP_ENV') }

      it 'looks for APP_ENV' do
        assert_equal "environment from ENV['APP_ENV']", ActiveRecordShards.app_env
      end
    end
  end
end
