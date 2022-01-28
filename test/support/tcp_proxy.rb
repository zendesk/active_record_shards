# TCPProxy binds `local_port` and forwards requests to `remote_host`:`remote_port`
#
#   proxy = TCPProxy.start(
#     remote_host: '127.0.0.1',
#     remote_port: '3306',
#     local_port: '13306'
#   )
#
# You can temporarily disable and re-enable the proxying:
#
#   proxy.pause do
#     do_work_that_cannot_call_proxied_service
#   end
#
require 'socket'

class TCPProxy
  # Set a higher interval on Ruby 2.5 to work around a bug:
  # https://github.com/ruby/ruby/commit/645f7fbd4ec0199c6266df19ad82d99bdd8553a8
  # Remove when removing Ruby 2.5 support.
  THREAD_CHECK_INTERVAL = if RUBY_VERSION.start_with?('2.5.')
                            0.2
                          else
                            0.001
                          end

  def self.start(remote_host:, remote_port:, local_port:)
    new(
      remote_host: remote_host,
      remote_port: remote_port,
      local_port: local_port
    ).tap(&:start)
  end

  def initialize(remote_host:, remote_port:, local_port:)
    @remote_host = remote_host
    @remote_port = remote_port
    @local_port = local_port

    @disabled = false
  end

  def start
    proxy_server = TCPServer.new('0.0.0.0', local_port)

    @thr = Thread.new do
      begin
        loop do
          requesting_socket = proxy_server.accept

          Thread.new do
            begin
              responding_socket = TCPSocket.new(remote_host, remote_port)

              requests = Thread.new { forward(requesting_socket, responding_socket, pause_behavior: :return) }
              requests.abort_on_exception = true

              responses = Thread.new { forward(responding_socket, requesting_socket) }
              responses.abort_on_exception = true

              # Either thread can be the first to finish - requests if the mysql2 client
              # closes the connection; responses if the MySQL server closes - so we
              # cannot do the more common `requests.join and responses.join`.
              sleep THREAD_CHECK_INTERVAL while requests.alive? && responses.alive?
              requests.kill
              responses.kill
              sleep THREAD_CHECK_INTERVAL until requests.stop? && responses.stop?
            ensure
              requesting_socket&.close
              responding_socket&.close
            end
          end
        end
      ensure
        proxy_server.close
      end
    end
  end

  def pause(&_block)
    # Give requests already sent to the socket a chance to be picked up before pausing.
    sleep 0.001
    @disabled = true
    yield
  ensure
    @disabled = false
  end

  private

  attr_reader :remote_host, :remote_port, :local_port

  def forward(src, dst, pause_behavior: :ignore)
    zero_counter = 0
    loop do
      data = src.recv(1024)

      if enabled? || pause_behavior == :ignore
        if data.empty?
          zero_counter += 1
          return if zero_counter >= 5
        else
          dst.send(data, 0)
        end
      elsif disabled? && pause_behavior == :return
        clean_data = data.gsub(/[^\w. ]/, '').strip

        warn "TCPProxy received a request while paused: `#{clean_data}`"
        return
      else
        raise "Invalid state"
      end
    end
  end

  def disabled?
    !enabled?
  end

  def enabled?
    !@disabled
  end
end
