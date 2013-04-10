class Cache
  def initialize
    @data = {}
    @key_access = {}
    @max_size = 5*1024*1024
    @cache_size = 0
    @pruning = false
  end

  def fetch(obj)
    key = to_key(obj)
    if entry = read_entry(key)
      Logger.log "Cache hit (#{@cache_size}/#{@max_size}): #{key.to_s.inspect}"
      entry
    else
      entry = yield
      Logger.log "Cache miss (#{@cache_size + entry.size}/#{@max_size}): #{key.to_s.inspect}"
      write_entry(key, entry)

      entry
    end
  end

  private

  def to_key(obj)
    obj.lines.first.to_s.strip.to_sym
  end

  def pruning?
    @pruning
  end

  def read_entry(key)
    entry = @data[key]
    synchronize do
      if entry
        @key_access[key] = Time.now.to_f
      else
        @key_access.delete(key)
      end
    end
    entry
  end

  def write_entry(key, entry)
    synchronize do
      @cache_size -= @data[key].size if @data[key]
      @cache_size += entry.size
      @key_access[key] = Time.now.to_f
      @data[key] = entry
      prune! if @cache_size > @max_size
      true
    end
  end

  def delete_entry(key)
    @key_access.delete(key)
    entry = @data.delete(key)
    @cache_size -= entry.size if entry
    !!entry
  end

  def prune!
    return if pruning?

    Logger.log 'Memory limit exceeded! Pruning...'

    target_size = @max_size * 0.75

    @pruning = true
    begin
      keys = @key_access.keys.sort{|a,b| @key_access[a].to_f <=> @key_access[b].to_f}
      keys.each do |key|
        delete_entry(key)
        if @cache_size <= target_size
          Logger.log "Pruning complete. Status: #{@cache_size}/#{@max_size}"
          return
        end
      end
    ensure
      @pruning = false
    end
  end

  def synchronize(&block)
    (@semaphore ||= Mutex.new).synchronize &block
  end
end
