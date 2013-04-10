module HTTPSocket
  def self.included(base)
    base.class_eval do
      include InstanceMethods
      alias_method :read_without_http_support, :read
      alias_method :read, :read_with_http_support
    end
  end

  module InstanceMethods
    def read_with_http_support(*args)
      if http_header.content_type
        http_header + read_http_data
      else
        http_header
      end
    end

    def read_http_data
      data = ''

      if size = http_header.content_length
        sent = 0
        while sent < size do
          partial = self.readpartial(1024)
          data << partial
          sent += partial.size
        end
      elsif http_header.transfer_encoding == 'chunked'
        begin
          loop do
            partial = self.readpartial(1024)
            data << partial
            break if partial =~ /\r\n0\r\n$/
          end
        rescue EOFError
        end
      end

      data
    end

    def http_header
      @http_header ||= HTTPHeader.new.tap do |req|
        while line = self.gets
          req << line
          break if line == "\r\n"
        end
      end
    end
  end
end

TCPSocket.send :include, HTTPSocket
