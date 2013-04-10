# Copyright 2013 Pavel Tsiukhtsiayeu https://github.com/PavelTyk/
class HTTPProxyServer < Struct.new(:port)
  def run
    begin
      loop { Thread.new(server.accept, &method(:handle_request)) }
    rescue Interrupt
      Logger.log 'Interrupt signal received. Quitting...'
    ensure
      server.close
    end
  end

  private

  # Payload for each threaded request
  def handle_request(client_socket)
    begin
      request_header = client_socket.http_header
      url = request_header.lines.first.split(' ')[1]
      uri = URI.parse(url)

      response = cache.fetch(request_header) do
        server_socket = TCPSocket.new(uri.host, uri.port)
        server_socket.write(request_header)
        server_socket.read
      end

      client_socket.write(response)
    rescue => e
      Logger.log e
    ensure
      client_socket.close
      server_socket.close rescue nil
    end
  end

  def server
    return @server if defined?(@server)

    port = self.port || 8080
    Logger.log "Starting HTTP Proxy server on port #{port}..."
    @server = TCPServer.new(port)
  end

  def cache
    @cache ||= Cache.new
  end
end
