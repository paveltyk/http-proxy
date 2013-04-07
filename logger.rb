# Copyright 2013 Pavel Tsiukhtsiayeu https://github.com/PavelTyk/
class Logger
  def log(msg)
    semaphore.synchronize {
      puts "<Thread:#{Thread.current.object_id.to_s(16)}>: #{msg}"
    }
  end

  private

  def semaphore
    @semaphore ||= Mutex.new
  end
end
