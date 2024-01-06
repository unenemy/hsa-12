require './redis-wrapper.rb'
require './dlogger.rb'

r = Redis.new

Dlogger.puts "Starting on host #{ENV["HOSTNAME"]} at #{Time.now.strftime('%H:%M:%S.%L')}"

while true
  r.xget("hsa-12", 60) do
    sleep 1 # emulate heavy computation
    42
  end
end