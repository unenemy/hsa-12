require 'redis-client'
require './dlogger.rb'

class Redis
  attr_reader :beta, :connection

  def initialize(beta = 1)
    @beta = beta
    @sentinel_config = RedisClient.sentinel(
      name: "redismaster",
      sentinels: [
        { host: "redis-sentinel", port: 26379 },
        { host: "redis-sentinel2", port: 26379 },
        { host: "redis-sentinel3", port: 26379 },
      ],
      role: :master
    )
    make_connection
  end

  def make_connection
    @connection = @sentinel_config.new_pool(timeout: 5, size: 5)
  end

  def xget(key, expiry_seconds, &block)
    delta = get("delta:#{key}")
    key_ttl = pttl(key) / 1000.0

    if delta.nil? || (Time.now.to_i - delta.to_f * beta * Math.log(rand)) >= (Time.now.to_i + key_ttl)
      t = Time.now
      Dlogger.puts "#{ENV["HOSTNAME"]} : Recalculating Cache at #{t.strftime('%H:%M:%S.%L')} to expire in #{expiry_seconds} seconds at #{(t+expiry_seconds).strftime('%H:%M:%S.%L')}"
      value = yield
      set(key, value, expiry_seconds)
      set("delta:#{key}", Time.now - t, expiry_seconds)
      value
    else
      get(key)
    end
  end

  def call(...)
    connection.call(...)
  rescue RedisClient::Error => e
    Dlogger.puts "Redis Timeout on host #{ENV["HOSTNAME"]}.. retrying"
    make_connection
    retry
  end

  def pttl(key)
    call("PTTL", key)
  end

  def set(key, value, expiry)
    call("SET", key, value, "EX", expiry)
  end

  def get(key)
    call("GET", key)
  end
end