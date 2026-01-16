# frozen_string_literal: true
require_relative 'helper'

describe 'patching association scope' do

  with_phenix

  before do
    ActiveRecord::Base.establish_connection(RAILS_ENV.to_sym)
    require 'models'
  end

  it 'checks the association table on shard when needed' do
    assert_using_master_db
    account = Account.create!
    ActiveRecord::Base.on_shard(nil) do
      account.tickets.create!(title: 'master ticket')
    end
  end
end
