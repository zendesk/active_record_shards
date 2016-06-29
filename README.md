# ActiveRecord Shards

ActiveRecord Shards is an extension for ActiveRecord that provides support for sharded database and slaves. Basically it is just a nice way to
switch between database connections. We've made the implementation very small, and have tried not to reinvent any wheels already present in ActiveRecord.

ActiveRecord Shards has been used and tested on Rails 3.2, 4.0, 4.1, 4.2 and 5.0 and has in some form or another been used in production on a large Rails app for several years.

## Installation

    $ gem install active_record_shards

and make sure to require 'active\_record\_shards' in some way.

## Configuration

Add the slave and shard configuration to config/database.yml:

    production:
      adapter: mysql
      encoding: utf8
      database: my_app_main
      pool: 5
      host: db1
      username: root
      password:
      slave:
        host: db1_slave
      shards:
        1:
          host: db_shard1
          database: my_app_shard
          slave:
            host: db_shard1_slave
        2:
          host: db_shard2
          database: my_app_shard
          slave:
            host: db_shard2_slave

basically connections inherit configuration from the parent configuration file.

## Usage

Normally you have some models that live on a shared database, and you might need to query this data in order to know what shard to switch to.
All the models that live on the shared database must be marked as not\_sharded:

    class Account < ActiveRecord::Base
      not_sharded

      has_many :projects
    end

    class Project < ActiveRecord::Base
      belongs_to :account
    end

So in this setup the accounts live on the shared database, but the projects are sharded. If accounts have a shard\_id column, you could lookup the account
in a rack middleware and switch to the right shard:

    class AccountMiddleware
      def initialize(app)
        @app = app
      end

      def call(env)
        account = lookup_account(env)

        if account
          ActiveRecord::Base.on_shard(account.shard_id) do
            @app.call(env)
          end
        else
          @app.call(env)
        end
      end

      def lookup_account(env)
        ...
      end
    end

You can switch to the slave databases at any point by wrapping your code in an on\_slave block:

    ActiveRecord::Base.on_slave do
      Account.find_by_big_expensive_query
    end

This will perform the query on the slave, and mark the returned instances as read only. There is also a shortcut for this:

    Account.on_slave.find_by_big_expensive_query

## Copyright

Copyright (c) 2011 Zendesk. See LICENSE for details.

## Authors
Mick Staugaard, Eric Chapweske

[![Build Status](https://secure.travis-ci.org/osheroff/active_record_shards.png)](http://travis-ci.org/osheroff/active_record_shards)
