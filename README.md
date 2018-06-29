# ProcessManager

[![Build Status](https://secure.travis-ci.org/mrkamel/process_manager.png?branch=master)](http://travis-ci.org/mrkamel/process_manager)

A process manager framework for forking, threading and graceful termination

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'process_manager'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install process_manager

## Usage

`ProcessManager` manages your background processes, thread and their graceful termination.

```ruby
process_manager = ProcessManager.new(logger: Logger.new(STDOUT))

process_manager.thread do
  # ...
end

process_manager.fork "process1" do # process1 will be shown in top, ps, etc
  # ...
end

process_manager.wait # blocking
```

To gracefully stop the forked processes and `ProcessManager` itself, send a
`QUIT` or `INT` signal to the process running `ProcessManager`.
`ProcessManager` will then gracefully stop the forked processes by sending a
`QUIT` signal to them to subsequently wait until they are shut down and
terminate itself afterwards. The PID files of the forked processes are stored
in `/tmp/process_manager`.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/mrkamel/process_manager.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
