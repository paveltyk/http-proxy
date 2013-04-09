class Cache < Struct.new(:logger)
  def fetch(obj)
    key = to_key(obj)
    if store[key]
      log "Cache hit: #{key.to_s.inspect}"
      store[key]
    else
      log "Cache miss: #{key.to_s.inspect}"
      store[key] = yield
    end
  end

  private

  def to_key(obj)
    obj.lines.first.to_s.strip.to_sym
  end

  def store
    @store ||= Hash.new
  end

  def log(msg)
    logger.log(msg)
  end
end
