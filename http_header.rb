class HTTPHeader < String
  def self.read_header(socket)
    self.new.tap do |req|
      while line = socket.gets
        req << line
        break if line == "\r\n"
      end
    end
  end

  def content_length
    if length_str = self.scan(/^content-length: (\d+)/i).flatten.last
      length_str.to_i
    end
  end

  def content_type
    self.scan(/^content-type:/i).flatten.last
  end
end
