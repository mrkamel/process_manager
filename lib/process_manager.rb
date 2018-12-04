
require "process_manager/version"
require "fileutils"
require "logger"

class ProcessManager
  def initialize(logger = Logger.new("/dev/null"))
    @logger = logger
  end

  def thread(&block)
    Thread.new do
      begin
        block.call
      rescue => e
        @logger.error e

        raise e
      end
    end
  end

  def fork(name, &block)
    before_fork

    child_pid = Process.fork do
      begin
        $0 = name

        FileUtils.mkdir_p "/tmp/process_manager"

        open("/tmp/process_manager/#{name}.pid", "w") { |stream| stream.puts Process.pid }

        after_fork

        if defined?(Rails)
          @logger.info "#{name} booted into #{Rails.env} environment"
        else
          @logger.info "#{name} booted"
        end

        block.call

        @logger.info "#{name} stopped"
      rescue => e
        @logger.error "#{name} process failed/stopped"
        @logger.error e
      end
    end

    after_fork

    Process.detach child_pid

    child_pid
  end

  def stop_all
    threads = Dir["/tmp/process_manager/*.pid"].map do |pidfile|
      Thread.new { terminate(pidfile) }
    end

    threads.each(&:join)
  end

  def wait
    ["INT", "QUIT", "TERM"].each do |sig|
      trap sig do
        puts "INT"

        stop_all

        exit 0
      end
    end

    sleep
  end

  private

  def terminate(pidfile)
    pid = File.read(pidfile).to_i

    waiter = Thread.new do
      Process.waitpid pid
    end

    Process.kill "QUIT", pid

    sleep 0.5

    30.times do
      return unless waiter.alive?

      sleep 1
    end

    @logger.error "Termination of #{File.basename pidfile, ".*"} (PID #{pid}) within 30 seconds failed"

    loop do
      return unless waiter.alive?

      sleep 1
    end
  rescue => e
    @logger.error e
  ensure
    FileUtils.rm_f pidfile
  end

  def before_fork
    ActiveRecord::Base.connection.disconnect! if defined?(ActiveRecord::Base)
  end

  def after_fork
    ActiveRecord::Base.establish_connection if defined?(ActiveRecord::Base)
  end
end

