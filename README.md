[![CircleCI build status](https://circleci.com/gh/zendesk/active_record_shards/tree/master.svg?style=svg)](https://circleci.com/gh/zendesk/active_record_shards/tree/master)

# ActiveRecord Shards

ActiveRecord Shards is an extension for ActiveRecord that provides support for sharded database and replicas. Basically it is just a nice way to
switch between database connections. We've made the implementation very small, and have tried not to reinvent any wheels already present in ActiveRecord.

ActiveRecord Shards has been used and tested on Rails 4.2, 5.x and 6.0, and has in some form or another been used in production on large Rails apps for several years.

- [Installation](#installation)
- [Configuration](#configuration)
- [Migrations](#migrations)
  - [Example](#example)
    - [Shared Model](#create-a-table-for-the-shared-not-sharded-model)
    - [Sharded Model](#create-a-table-for-the-sharded-model)
- [Usage](#usage)
- [Debugging](#debugging)

## Installation

    $ gem install active_record_shards

and make sure to require 'active\_record\_shards' in some way.

## Configuration

Add the replica and shard configuration to config/database.yml:

```yaml
production:
  adapter: mysql
  encoding: utf8
  database: my_app_main
  pool: 5
  host: db1
  username: root
  password:
  replica:
    host: db1_replica
  shards:
    1:
      host: db_shard1
      database: my_app_shard
      replica:
        host: db_shard1_replica
    2:
      host: db_shard2
      database: my_app_shard
      replica:
        host: db_shard2_replica
```

basically connections inherit configuration from the parent configuration file.

## Migrations

ActiveRecord Shards also patches migrations to support running migrations on a shared (not sharded) or a sharded database.
Each migration class has to specify a shard spec indicating where to run the migration.

Valid shard specs:

* `:none` - Run this migration on the shared database, not any shards
* `:all` - Run this migration on all of the shards, not the shared database

#### Example

###### Create a table for the shared (not sharded) model

```ruby
class CreateAccounts < ActiveRecord::Migration
  shard :none

  def change
    create_table :accounts do |t|
      # This is NOT necessary for the gem to work, we just use it in the examples below demonstrating one way to switch shards
      t.integer :shard_id, null: false

      t.string :name
    end
  end
end
```

###### Create a table for the sharded model

```ruby
class CreateProjects < ActiveRecord::Migration
  shard :all

  def change
    create_table :projects do |t|
      t.references :account
      t.string :name
    end
  end
end
```

## Usage

Normally you have some models that live on a shared database, and you might need to query this data in order to know what shard to switch to.
All the models that live on the shared database must be marked as not\_sharded:

```ruby
class Account < ActiveRecord::Base
  not_sharded

  has_many :projects
end

class Project < ActiveRecord::Base
  belongs_to :account
end
```

So in this setup the accounts live on the shared database, but the projects are sharded. If accounts have a shard\_id column, you could lookup the account
in a rack middleware and switch to the right shard:

```ruby
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
    # ...
  end
end
```

You can switch to the replica databases at any point by wrapping your code in an on\_replica block:

```ruby
ActiveRecord::Base.on_replica do
  Account.find_by_big_expensive_query
end
```

This will perform the query on the replica, and mark the returned instances as read only. There is also a shortcut for this:

```ruby
Account.on_replica.find_by_big_expensive_query
```

## Debugging

Show if a query went to primary or replica in the logs:

```Ruby
require 'active_record_shards/sql_comments'
ActiveRecordShards::SqlComments.enable
```

## Changelog

We use [github-changelog-generator](https://github.com/github-changelog-generator/github-changelog-generator) gem to keep our changelog updated.

```Shell
bundle exec github_changelog_generator \
  --user zendesk \
  --project active_record_shards
  --token CHANGELOG_GITHUB_TOKEN
```

*This script can make only 50 requests to GitHub API per hour without a token.*
Follow instructions to generate a token [here](https://github.com/github-changelog-generator/github-changelog-generator#github-token) (don't forget to enable SSO access).

## Copyright

Copyright (c) 2011 Zendesk. See LICENSE for details.

## Authors

Mick Staugaard, Eric Chapweske
