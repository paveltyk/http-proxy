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

      response = cache.fetch(request_header) do
        server_socket = TCPSocket.new(uri.host, uri.port)
        server_socket.write(request_header)

        response_header = HTTPHeader.read_header(server_socket)

        if response_header.content_type
          size = response_header.content_length
          chunked = response_header.transfer_encoding == 'chunked'
          response_header << read_data(server_socket, size, chunked)
        end

        response_header
      end

      client_socket.write(response)
    rescue => e
      log e
    ensure
      client_socket.close
      server_socket.close rescue nil
    end
  end

  def read_data(socket, size, chunked)
    data = ''
    if size
      sent = 0
      while sent < size do
        socket.readpartial(1024).tap do |partial|
          sent += partial.size
          data << partial
        end
      end
    elsif chunked
      begin
        loop do
          partial = socket.readpartial(1024)
          data << partial
          break if partial =~ /\r\n0\r\n$/
        end
      rescue EOFError
      end
    end

    data
  end

  def server
    return @server if defined?(@server)

    port = self.port || 8080
    log "Starting HTTP Proxy server on port #{port}..."
    @server = TCPServer.new(port)
  end

  def log(msg)
    logger.log(msg)
  end

  def logger
    @logger ||= Logger.new
  end

  def cache
    @cache ||= Cache.new(logger)
  end
end
