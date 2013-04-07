# Copyright 2013 Pavel Tsiukhtsiayeu https://github.com/PavelTyk/
class HTTPProxyServer < Struct.new(:port)
  def run
    begin
      loop { Thread.new(server.accept, &method(:handle_request)) }
    rescue Interrupt
      log "Interrupt signal received. Quitting..."
    ensure
      server.close
    end
  end

  private

  # Payload for each threaded request
  def handle_request(client_socket)
    begin
      request_header = HTTPHeader.read_header(client_socket)
      verb, url = request_header.lines.first.split(' ')
      uri = URI.parse(url)

      log "#{verb} #{url}"

      server_socket = TCPSocket.new(uri.host, uri.port)
      server_socket.write(request_header)

      response_header = HTTPHeader.read_header(server_socket)

      client_socket.write(response_header)

      if response_header.content_type
        forward_data(server_socket, client_socket, response_header.content_length)
      end
    rescue => e
      log e
    ensure
      client_socket.close
      server_socket.close rescue nil
    end
  end

  # Forward message body from one socket to another.
  # The size should be in bytes. Most often it will come from
  # Content-Length message header.
  # If the data is transfered in chunks with keep-alive true
  # (Content-Length not present), it should handle that case
  # gracefully in most cases :)
  def forward_data(from, to, size)
    if size
      sent = 0
      while sent < size do
        sent = sent + to.write(from.readpartial(1024))
        to.flush
      end
    else
      begin
        loop do
          sent = to.write(from.read(1024))
          to.flush
          break if sent < 1024
        end
      rescue EOFError
      end
    end
  end

  def server
    return @server if defined?(@server)

    port = self.port || 8080
    log "Starting HTTP Proxy server on port #{port}..."
    @server = TCPServer.new(port)
  end

  def log(msg)
    @logger ||= Logger.new
    @logger.log(msg)
  end
end
