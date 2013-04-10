class Cache
  def fetch(obj)
    key = to_key(obj)
    if store[key]
      Logger.log "Cache hit: #{key.to_s.inspect}"
      store[key]
    else
      Logger.log "Cache miss: #{key.to_s.inspect}"
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
end
