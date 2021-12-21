# frozen_string_literal: true

require_relative 'helper'
require_relative 'models'

describe "connection switching thread safety" do
  with_fresh_databases

  before do
    ActiveRecord::Base.establish_connection(:test)
    use_same_connection_handler_for_all_theads
    create_seed_data
  end

  after do
    ActiveRecord::Base.connection_handler.clear_all_connections!
  end

  it "can safely switch between all database connections in parallel" do
    new_thread("switches_through_all_1") do
      pause_and_mark_ready
      switch_through_all_databases
    end
    new_thread("switches_through_all_2") do
      pause_and_mark_ready
      switch_through_all_databases
    end
    new_thread("switches_through_all_3") do
      pause_and_mark_ready
      switch_through_all_databases
    end

    wait_for_threads_to_be_ready
    execute_and_wait_for_threads
  end

  describe "when multiple threads use different databases" do
    it "allows threads to parallelize their IO" do
      results = []

      query_delay = { fast: "0.01", slow: "1", medium: "0.5" }
      new_thread("same_db_parallel_thread1") do
        ActiveRecord::Base.on_primary do
          pause_and_mark_ready
          result = execute_sql("SELECT name,'slower query',SLEEP(#{query_delay.fetch(:slow)}) FROM accounts")
          assert('Primary account', result.first[0])
          results.push(result)
        end
      end

      new_thread("same_db_parallel_thread2") do
        ActiveRecord::Base.on_replica do
          pause_and_mark_ready
          result = execute_sql("SELECT name, 'faster query',SLEEP(#{query_delay.fetch(:fast)}) FROM accounts")
          assert('Replica account', result.first[0])
          results.push(result)
        end
      end

      new_thread("same_db_parallel_thread3") do
        ActiveRecord::Base.on_shard(0) do
          pause_and_mark_ready
          result = execute_sql("SELECT title, 'medium query',SLEEP(#{query_delay.fetch(:medium)}) FROM tickets")
          assert('Shard 0 Primary ticket', result.first[0])
          results.push(result)
        end
      end

      wait_for_threads_to_be_ready

      thread_exection_time = Benchmark.realtime do
        execute_and_wait_for_threads
      end

      minimum_serial_query_exection_time = query_delay.values.map(&:to_f).sum
      # Arbitrarily faster time such that there must have been some parallelization
      max_parallel_time = minimum_serial_query_exection_time - 0.1
      assert_operator(max_parallel_time, :>, thread_exection_time)

      # This order cannot be guaranteed but it likely given the artificial delays
      rows = results.map(&:first)
      result_strings = rows.map { |r| r[1] }
      assert([
          "faster query",
          "medium query",
          "slower query"
      ], result_strings)
    end
  end

  describe "when multiple threads use the same database" do
    it "exposes a different connections to each thread" do
      connections = []

      new_thread("connection_per_thread1") do
        ActiveRecord::Base.on_primary do
          pause_and_mark_ready
          connections << ActiveRecord::Base.connection
        end
      end

      new_thread("connection_per_thread2") do
        ActiveRecord::Base.on_primary do
          pause_and_mark_ready
          connections << ActiveRecord::Base.connection
        end
      end

      wait_for_threads_to_be_ready
      execute_and_wait_for_threads

      assert(ActiveRecord::ConnectionAdapters::Mysql2Adapter, connections.first)
      assert(2, connections.uniq.size)
    end

    it "allows threads to parallelize their IO" do
      results = []

      query_delay = { fast: "0.01", slow: "1", medium: "0.5" }
      new_thread("same_db_parallel_thread1") do
        ActiveRecord::Base.on_primary do
          pause_and_mark_ready
          result = execute_sql("SELECT 'slower query',SLEEP(#{query_delay.fetch(:slow)})")
          results.push(result)
        end
      end

      new_thread("same_db_parallel_thread2") do
        ActiveRecord::Base.on_primary do
          pause_and_mark_ready
          result = execute_sql("SELECT 'faster query',SLEEP(#{query_delay.fetch(:fast)})")
          results.push(result)
        end
      end

      new_thread("same_db_parallel_thread3") do
        ActiveRecord::Base.on_primary do
          pause_and_mark_ready
          result = execute_sql("SELECT 'fast-ish query',SLEEP(#{query_delay.fetch(:medium)})")
          results.push(result)
        end
      end

      wait_for_threads_to_be_ready

      thread_exection_time = Benchmark.realtime do
        execute_and_wait_for_threads
      end

      minimum_serial_query_exection_time = query_delay.values.map(&:to_f).sum
      # Arbitrarily faster time such that there must have been some parallelization
      max_parallel_time = minimum_serial_query_exection_time - 0.1
      assert_operator(max_parallel_time, :>, thread_exection_time)

      rows = results.map(&:first)
      result_strings = rows.map(&:first)
      # This order cannot be guaranteed but it likely given the artificial delays
      assert([
          "faster query",
          "fast-ish query",
          "slower query"
      ], result_strings)
    end
  end

  def new_thread(name)
    thread = Thread.new do
      Thread.current.name = name
      yield
    end

    @test_threads ||= []
    @test_threads.push(thread)
  end

  def switch_through_all_databases
    ActiveRecord::Base.on_primary do
      result = ActiveRecord::Base.connection.execute("SELECT * from accounts")
      assert("Primary account", record_name(result))
    end
    ActiveRecord::Base.on_replica do
      result = ActiveRecord::Base.connection.execute("SELECT * from accounts")
      assert("Replica account", record_name(result))
    end
    ActiveRecord::Base.on_shard(0) do
      result = ActiveRecord::Base.connection.execute("SELECT * from tickets")
      assert("Shard 0 Primary ticket", record_name(result))

      ActiveRecord::Base.on_replica do
        result = ActiveRecord::Base.connection.execute("SELECT * from tickets")
        assert("Shard 0 Replica ticket", record_name(result))
      end
    end
    ActiveRecord::Base.on_shard(1) do
      result = ActiveRecord::Base.connection.execute("SELECT * from tickets")
      assert("Shard 1 Primary ticket", record_name(result))

      ActiveRecord::Base.on_replica do
        result = ActiveRecord::Base.connection.execute("SELECT * from tickets")
        assert("Shard 1 Replica ticket", record_name(result))
      end
    end
  end

  # This allows us to get all of our threads into a prepared state by pausing
  # them at a 'ready' point so as there is as little overhead as possible
  # before the interesting code executes.
  #
  # Here we use 'ready' to mean the thread is spawned, has had its names set
  # and has established a database connection.
  def pause_and_mark_ready
    Thread.current[:ready] = true
    sleep
  end

  def execute_and_wait_for_threads
    @test_threads.each { |t| t.wakeup if t.alive? }
    @test_threads.each(&:join)
  end

  def wait_for_threads_to_be_ready
    sleep(0.01) until @test_threads.all? { |t| t[:ready] }
  end

  def use_same_connection_handler_for_all_theads
    ActiveRecord::Base.default_connection_handler = ActiveRecord::Base.connection_handler
  end

  def record_name(db_result)
    name_column_index = 1
    db_result.first[name_column_index]
  end

  def execute_sql(query)
    ActiveRecord::Base.connection.execute(query)
  end

  def create_seed_data
    ActiveRecord::Base.on_primary_db do
      Account.connection.execute(account_insert_sql(name: "Primary account"))

      Account.on_replica do
        Account.connection.execute(account_insert_sql(name: "Replica account"))
      end
    end

    [0, 1].each do |shard_id|
      ActiveRecord::Base.on_shard(shard_id) do
        Ticket.connection.execute(ticket_insert_sql(title: "Shard #{shard_id} Primary ticket"))

        Ticket.on_replica do
          Ticket.connection.execute(ticket_insert_sql(title: "Shard #{shard_id} Replica ticket"))
        end
      end
    end
  end

  def account_insert_sql(name:)
    "INSERT INTO accounts (id, name, created_at, updated_at)" \
      " VALUES (1000, '#{name}', NOW(), NOW())"
  end

  def ticket_insert_sql(title:)
    "INSERT INTO tickets (id, title, account_id, created_at, updated_at)" \
      " VALUES (1000, '#{title}', 5000, NOW(), NOW())"
  end
end
