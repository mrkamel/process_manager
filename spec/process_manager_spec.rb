
require File.expand_path("../spec_helper", __FILE__)

RSpec.describe ProcessManager do
  let(:process_manager) { ProcessManager.new }

  it "should fork processes" do
    begin
      pid1 = nil
      pid2 = nil

      prok = proc do
        pid1 = process_manager.fork("process1") do
          sleep
        end

        pid2 = process_manager.fork("process2") do
          sleep
        end

        sleep 1
      end

      expect(&prok).to change { Dir["/tmp/process_manager/*.pid"].size }.by(2)

      expect(Process.kill(0, pid1)).to eq(1)
      expect(Process.kill(0, pid2)).to eq(1)
    ensure
      process_manager.stop_all
    end
  end

  it "should create threads" do
    thread = process_manager.thread do
      sleep
    end

    expect(thread.alive?).to be(true)
  end

  it "should stop processes gracefully" do
    begin
      pid = process_manager.fork("process") do
        trap "QUIT" do
          sleep 1

          FileUtils.touch "/tmp/gracefully_stopped"

          exit 0
        end

        sleep
      end

      sleep 1

      process_manager.stop_all

      expect(File.exists?("/tmp/gracefully_stopped")).to be(true)
    ensure
      FileUtils.rm_f "/tmp/gracefully_stopped"

      process_manager.stop_all
    end
  end
end

