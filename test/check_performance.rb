# frozen_string_literal: true

require "bundler/setup"

$LOAD_PATH.unshift(File.join(__dir__, '..', 'lib'))
$LOAD_PATH.unshift(__dir__)

require "active_record"
require "active_record_shards"
require "mysql2"
require "benchmark/ips"
require "support/db_helper"

RAILS_ENV = "test"
ActiveRecord::Base.logger = Logger.new("/dev/null")

class Account < ActiveRecord::Base
  not_sharded

  has_many :tickets
end

class Ticket < ActiveRecord::Base
  belongs_to :account
end

erb_config = <<-ERB
  <% mysql = URI(ENV['MYSQL_URL'] || 'mysql://root@127.0.0.1:3306') %>

  mysql: &MYSQL
    encoding: utf8
    adapter: mysql2
    username: <%= mysql.user %>
    host: <%= mysql.host %>
    port: <%= mysql.port %>
    password: <%= mysql.password %>
    ssl_mode: :disabled

  test:
    <<: *MYSQL
    database: ars_test
    shard_names: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54, 55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71, 72, 73, 74, 75, 76, 77, 78, 79, 80]
  test_replica:
    <<: *MYSQL
    database: ars_test_replica

  test_shard_0:
    <<: *MYSQL
    database: ars_test_shard0
  test_shard_0_replica:
    <<: *MYSQL
    database: ars_test_shard0_replica

  test_shard_1:
    <<: *MYSQL
    database: ars_test_shard1
  test_shard_1_replica:
    <<: *MYSQL
    database: ars_test_shard1_replica

  test_shard_2:
    <<: *MYSQL
    database: ars_test_shard_2
  test_shard_2_replica:
    <<: *MYSQL
    database: ars_test_shard_2_replica

  test_shard_3:
    <<: *MYSQL
    database: ars_test_shard_3
  test_shard_3_replica:
    <<: *MYSQL
    database: ars_test_shard_3_replica

  test_shard_4:
    <<: *MYSQL
    database: ars_test_shard_4
  test_shard_4_replica:
    <<: *MYSQL
    database: ars_test_shard_4_replica

  test_shard_5:
    <<: *MYSQL
    database: ars_test_shard_5
  test_shard_5_replica:
    <<: *MYSQL
    database: ars_test_shard_5_replica

  test_shard_6:
    <<: *MYSQL
    database: ars_test_shard_6
  test_shard_6_replica:
    <<: *MYSQL
    database: ars_test_shard_6_replica

  test_shard_7:
    <<: *MYSQL
    database: ars_test_shard_7
  test_shard_7_replica:
    <<: *MYSQL
    database: ars_test_shard_7_replica

  test_shard_8:
    <<: *MYSQL
    database: ars_test_shard_8
  test_shard_8_replica:
    <<: *MYSQL
    database: ars_test_shard_8_replica

  test_shard_9:
    <<: *MYSQL
    database: ars_test_shard_9
  test_shard_9_replica:
    <<: *MYSQL
    database: ars_test_shard_9_replica

  test_shard_10:
    <<: *MYSQL
    database: ars_test_shard_10
  test_shard_10_replica:
    <<: *MYSQL
    database: ars_test_shard_10_replica

  test_shard_11:
    <<: *MYSQL
    database: ars_test_shard_11
  test_shard_11_replica:
    <<: *MYSQL
    database: ars_test_shard_11_replica

  test_shard_12:
    <<: *MYSQL
    database: ars_test_shard_12
  test_shard_12_replica:
    <<: *MYSQL
    database: ars_test_shard_12_replica

  test_shard_13:
    <<: *MYSQL
    database: ars_test_shard_13
  test_shard_13_replica:
    <<: *MYSQL
    database: ars_test_shard_13_replica

  test_shard_14:
    <<: *MYSQL
    database: ars_test_shard_14
  test_shard_14_replica:
    <<: *MYSQL
    database: ars_test_shard_14_replica

  test_shard_15:
    <<: *MYSQL
    database: ars_test_shard_15
  test_shard_15_replica:
    <<: *MYSQL
    database: ars_test_shard_15_replica

  test_shard_16:
    <<: *MYSQL
    database: ars_test_shard_16
  test_shard_16_replica:
    <<: *MYSQL
    database: ars_test_shard_16_replica

  test_shard_17:
    <<: *MYSQL
    database: ars_test_shard_17
  test_shard_17_replica:
    <<: *MYSQL
    database: ars_test_shard_17_replica

  test_shard_18:
    <<: *MYSQL
    database: ars_test_shard_18
  test_shard_18_replica:
    <<: *MYSQL
    database: ars_test_shard_18_replica

  test_shard_19:
    <<: *MYSQL
    database: ars_test_shard_19
  test_shard_19_replica:
    <<: *MYSQL
    database: ars_test_shard_19_replica

  test_shard_20:
    <<: *MYSQL
    database: ars_test_shard_20
  test_shard_20_replica:
    <<: *MYSQL
    database: ars_test_shard_20_replica

  test_shard_21:
    <<: *MYSQL
    database: ars_test_shard_21
  test_shard_21_replica:
    <<: *MYSQL
    database: ars_test_shard_21_replica

  test_shard_22:
    <<: *MYSQL
    database: ars_test_shard_22
  test_shard_22_replica:
    <<: *MYSQL
    database: ars_test_shard_22_replica

  test_shard_23:
    <<: *MYSQL
    database: ars_test_shard_23
  test_shard_23_replica:
    <<: *MYSQL
    database: ars_test_shard_23_replica

  test_shard_24:
    <<: *MYSQL
    database: ars_test_shard_24
  test_shard_24_replica:
    <<: *MYSQL
    database: ars_test_shard_24_replica

  test_shard_25:
    <<: *MYSQL
    database: ars_test_shard_25
  test_shard_25_replica:
    <<: *MYSQL
    database: ars_test_shard_25_replica

  test_shard_26:
    <<: *MYSQL
    database: ars_test_shard_26
  test_shard_26_replica:
    <<: *MYSQL
    database: ars_test_shard_26_replica

  test_shard_27:
    <<: *MYSQL
    database: ars_test_shard_27
  test_shard_27_replica:
    <<: *MYSQL
    database: ars_test_shard_27_replica

  test_shard_28:
    <<: *MYSQL
    database: ars_test_shard_28
  test_shard_28_replica:
    <<: *MYSQL
    database: ars_test_shard_28_replica

  test_shard_29:
    <<: *MYSQL
    database: ars_test_shard_29
  test_shard_29_replica:
    <<: *MYSQL
    database: ars_test_shard_29_replica

  test_shard_30:
    <<: *MYSQL
    database: ars_test_shard_30
  test_shard_30_replica:
    <<: *MYSQL
    database: ars_test_shard_30_replica

  test_shard_31:
    <<: *MYSQL
    database: ars_test_shard_31
  test_shard_31_replica:
    <<: *MYSQL
    database: ars_test_shard_31_replica

  test_shard_32:
    <<: *MYSQL
    database: ars_test_shard_32
  test_shard_32_replica:
    <<: *MYSQL
    database: ars_test_shard_32_replica

  test_shard_33:
    <<: *MYSQL
    database: ars_test_shard_33
  test_shard_33_replica:
    <<: *MYSQL
    database: ars_test_shard_33_replica

  test_shard_34:
    <<: *MYSQL
    database: ars_test_shard_34
  test_shard_34_replica:
    <<: *MYSQL
    database: ars_test_shard_34_replica

  test_shard_35:
    <<: *MYSQL
    database: ars_test_shard_35
  test_shard_35_replica:
    <<: *MYSQL
    database: ars_test_shard_35_replica

  test_shard_36:
    <<: *MYSQL
    database: ars_test_shard_36
  test_shard_36_replica:
    <<: *MYSQL
    database: ars_test_shard_36_replica

  test_shard_37:
    <<: *MYSQL
    database: ars_test_shard_37
  test_shard_37_replica:
    <<: *MYSQL
    database: ars_test_shard_37_replica

  test_shard_38:
    <<: *MYSQL
    database: ars_test_shard_38
  test_shard_38_replica:
    <<: *MYSQL
    database: ars_test_shard_38_replica

  test_shard_39:
    <<: *MYSQL
    database: ars_test_shard_39
  test_shard_39_replica:
    <<: *MYSQL
    database: ars_test_shard_39_replica

  test_shard_40:
    <<: *MYSQL
    database: ars_test_shard_40
  test_shard_40_replica:
    <<: *MYSQL
    database: ars_test_shard_40_replica

  test_shard_41:
    <<: *MYSQL
    database: ars_test_shard_41
  test_shard_41_replica:
    <<: *MYSQL
    database: ars_test_shard_41_replica

  test_shard_42:
    <<: *MYSQL
    database: ars_test_shard_42
  test_shard_42_replica:
    <<: *MYSQL
    database: ars_test_shard_42_replica

  test_shard_43:
    <<: *MYSQL
    database: ars_test_shard_43
  test_shard_43_replica:
    <<: *MYSQL
    database: ars_test_shard_43_replica

  test_shard_44:
    <<: *MYSQL
    database: ars_test_shard_44
  test_shard_44_replica:
    <<: *MYSQL
    database: ars_test_shard_44_replica

  test_shard_45:
    <<: *MYSQL
    database: ars_test_shard_45
  test_shard_45_replica:
    <<: *MYSQL
    database: ars_test_shard_45_replica

  test_shard_46:
    <<: *MYSQL
    database: ars_test_shard_46
  test_shard_46_replica:
    <<: *MYSQL
    database: ars_test_shard_46_replica

  test_shard_47:
    <<: *MYSQL
    database: ars_test_shard_47
  test_shard_47_replica:
    <<: *MYSQL
    database: ars_test_shard_47_replica

  test_shard_48:
    <<: *MYSQL
    database: ars_test_shard_48
  test_shard_48_replica:
    <<: *MYSQL
    database: ars_test_shard_48_replica

  test_shard_49:
    <<: *MYSQL
    database: ars_test_shard_49
  test_shard_49_replica:
    <<: *MYSQL
    database: ars_test_shard_49_replica

  test_shard_50:
    <<: *MYSQL
    database: ars_test_shard_50
  test_shard_50_replica:
    <<: *MYSQL
    database: ars_test_shard_50_replica

  test_shard_51:
    <<: *MYSQL
    database: ars_test_shard_51
  test_shard_51_replica:
    <<: *MYSQL
    database: ars_test_shard_51_replica

  test_shard_52:
    <<: *MYSQL
    database: ars_test_shard_52
  test_shard_52_replica:
    <<: *MYSQL
    database: ars_test_shard_52_replica

  test_shard_53:
    <<: *MYSQL
    database: ars_test_shard_53
  test_shard_53_replica:
    <<: *MYSQL
    database: ars_test_shard_53_replica

  test_shard_54:
    <<: *MYSQL
    database: ars_test_shard_54
  test_shard_54_replica:
    <<: *MYSQL
    database: ars_test_shard_54_replica

  test_shard_55:
    <<: *MYSQL
    database: ars_test_shard_55
  test_shard_55_replica:
    <<: *MYSQL
    database: ars_test_shard_55_replica

  test_shard_56:
    <<: *MYSQL
    database: ars_test_shard_56
  test_shard_56_replica:
    <<: *MYSQL
    database: ars_test_shard_56_replica

  test_shard_57:
    <<: *MYSQL
    database: ars_test_shard_57
  test_shard_57_replica:
    <<: *MYSQL
    database: ars_test_shard_57_replica

  test_shard_58:
    <<: *MYSQL
    database: ars_test_shard_58
  test_shard_58_replica:
    <<: *MYSQL
    database: ars_test_shard_58_replica

  test_shard_59:
    <<: *MYSQL
    database: ars_test_shard_59
  test_shard_59_replica:
    <<: *MYSQL
    database: ars_test_shard_59_replica

  test_shard_60:
    <<: *MYSQL
    database: ars_test_shard_60
  test_shard_60_replica:
    <<: *MYSQL
    database: ars_test_shard_60_replica

  test_shard_61:
    <<: *MYSQL
    database: ars_test_shard_61
  test_shard_61_replica:
    <<: *MYSQL
    database: ars_test_shard_61_replica

  test_shard_62:
    <<: *MYSQL
    database: ars_test_shard_62
  test_shard_62_replica:
    <<: *MYSQL
    database: ars_test_shard_62_replica

  test_shard_63:
    <<: *MYSQL
    database: ars_test_shard_63
  test_shard_63_replica:
    <<: *MYSQL
    database: ars_test_shard_63_replica

  test_shard_64:
    <<: *MYSQL
    database: ars_test_shard_64
  test_shard_64_replica:
    <<: *MYSQL
    database: ars_test_shard_64_replica

  test_shard_65:
    <<: *MYSQL
    database: ars_test_shard_65
  test_shard_65_replica:
    <<: *MYSQL
    database: ars_test_shard_65_replica

  test_shard_66:
    <<: *MYSQL
    database: ars_test_shard_66
  test_shard_66_replica:
    <<: *MYSQL
    database: ars_test_shard_66_replica

  test_shard_67:
    <<: *MYSQL
    database: ars_test_shard_67
  test_shard_67_replica:
    <<: *MYSQL
    database: ars_test_shard_67_replica

  test_shard_68:
    <<: *MYSQL
    database: ars_test_shard_68
  test_shard_68_replica:
    <<: *MYSQL
    database: ars_test_shard_68_replica

  test_shard_69:
    <<: *MYSQL
    database: ars_test_shard_69
  test_shard_69_replica:
    <<: *MYSQL
    database: ars_test_shard_69_replica

  test_shard_70:
    <<: *MYSQL
    database: ars_test_shard_70
  test_shard_70_replica:
    <<: *MYSQL
    database: ars_test_shard_70_replica

  test_shard_71:
    <<: *MYSQL
    database: ars_test_shard_71
  test_shard_71_replica:
    <<: *MYSQL
    database: ars_test_shard_71_replica

  test_shard_72:
    <<: *MYSQL
    database: ars_test_shard_72
  test_shard_72_replica:
    <<: *MYSQL
    database: ars_test_shard_72_replica

  test_shard_73:
    <<: *MYSQL
    database: ars_test_shard_73
  test_shard_73_replica:
    <<: *MYSQL
    database: ars_test_shard_73_replica

  test_shard_74:
    <<: *MYSQL
    database: ars_test_shard_74
  test_shard_74_replica:
    <<: *MYSQL
    database: ars_test_shard_74_replica

  test_shard_75:
    <<: *MYSQL
    database: ars_test_shard_75
  test_shard_75_replica:
    <<: *MYSQL
    database: ars_test_shard_75_replica

  test_shard_76:
    <<: *MYSQL
    database: ars_test_shard_76
  test_shard_76_replica:
    <<: *MYSQL
    database: ars_test_shard_76_replica

  test_shard_77:
    <<: *MYSQL
    database: ars_test_shard_77
  test_shard_77_replica:
    <<: *MYSQL
    database: ars_test_shard_77_replica

  test_shard_78:
    <<: *MYSQL
    database: ars_test_shard_78
  test_shard_78_replica:
    <<: *MYSQL
    database: ars_test_shard_78_replica

  test_shard_79:
    <<: *MYSQL
    database: ars_test_shard_79
  test_shard_79_replica:
    <<: *MYSQL
    database: ars_test_shard_79_replica

  test_shard_80:
    <<: *MYSQL
    database: ars_test_shard_80
  test_shard_80_replica:
    <<: *MYSQL
    database: ars_test_shard_80_replica
ERB

config_io = StringIO.new(erb_config)
DbHelper.drop_databases
DbHelper.create_databases
DbHelper.load_database_schemas
DbHelper.load_database_configuration(config_io)

ActiveRecord::Base.establish_connection(:test)

def unsharded_primary
  ActiveRecord::Base.on_shard(nil) do
    ActiveRecord::Base.on_primary { Account.count }
  end
end

def unsharded_replica
  ActiveRecord::Base.on_shard(nil) do
    ActiveRecord::Base.on_replica { Account.count }
  end
end

def sharded_primary
  ActiveRecord::Base.on_shard(1) do
    ActiveRecord::Base.on_primary { Ticket.count }
  end
end

def sharded_replica
  ActiveRecord::Base.on_shard(1) do
    ActiveRecord::Base.on_replica { Ticket.count }
  end
end

def switch_around
  unsharded_primary
  unsharded_replica
  sharded_primary
  sharded_replica
end

Benchmark.ips do |x|
  x.report("#{ActiveRecord::VERSION::STRING} DB switching") { switch_around }
end

# Results using Ruby 2.7.5
#
# 5.0.7.2 DB switching    207.457  (± 8.2%) i/s
#   5.1.7 DB switching    211.790  (± 3.8%) i/s
#   5.2.5 DB switching    213.797  (± 5.1%) i/s
#   6.0.4 DB switching    216.607  (± 4.2%) i/s

DbHelper.drop_databases
