module Dlogger
  module_function
  
  def puts(...)
    logger.puts(...)
  end

  def logger
    @logger ||= begin
      fd = IO.sysopen("/proc/1/fd/1", "w")
      IO.new(fd, "w").tap { |x| x.sync = true }
    end
  end 
end