# If you have a very small app you may be able to
# increase this, but in general 3 workers seems to
# work best
worker_processes 3

# Load your app into the master before forking
# workers for super-fast worker spawn times
preload_app true
GC.respond_to?(:copy_on_write_friendly=) and GC.copy_on_write_friendly = true

# Immediately restart any workers that
# haven't responded within 30 seconds
timeout 30

port = ENV['UNICORN_PORT'] || "8080"

listen port.to_i

before_fork do |_server, _worker|

  Signal.trap 'TERM' do
    puts 'Unicorn master intercepting TERM and sending myself QUIT instead'
    Process.kill 'QUIT', Process.pid
  end

  defined?(ActiveRecord::Base) &&
    ActiveRecord::Base.connection.disconnect!
end

after_fork do |_server, _worker|

  Signal.trap 'TERM' do
    puts 'Unicorn worker intercepting TERM and doing nothing. Wait for master to sent QUIT'
  end

  defined?(ActiveRecord::Base) &&
    ActiveRecord::Base.establish_connection
end
