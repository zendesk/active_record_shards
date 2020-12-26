# frozen_string_literal: true

require_relative 'helper'
require 'active_record_shards/sql_comments'

describe ActiveRecordShards::SqlComments do
  with_phenix

  class CommentTester
    attr_reader :called
    prepend ActiveRecordShards::SqlComments::Methods

    def execute(query, _name = nil)
      (@called ||= []) << query
    end
  end

  let(:comment) { CommentTester.new }

  it "adds sql comment" do
    comment.execute("foo")
    assert_equal ["foo /* primary */"], comment.called
  end
end
