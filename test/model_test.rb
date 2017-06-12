# frozen_string_literal: true
require File.expand_path('../helper', __FILE__)

describe 'models' do
  before do
    Phenix.rise!(with_schema: true)
    ActiveRecord::Base.establish_connection(RAILS_ENV.to_sym)
    require 'models'
  end

  describe 'primary_key' do
    it "should be set to 'id' by default" do
      User.connection.expects(:execute).never
      assert_equal 'id', User.primary_key
    end

    it 'should keep value if already set' do
      class UniqueModel < ActiveRecord::Base
        self.primary_key = 'model_id'
      end

      assert 'model_id', UniqueModel.primary_key
    end
  end
end
