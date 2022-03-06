require 'rubygems'
require 'bundler/setup'

require 'discordrb'
require 'mij-discord'
require 'logger'
require_relative 'selfbot-polyfills'

module Selfbot
  # Load config before anything else
  require_relative 'config'

  module Defs; end

  LOGGER = Logger.new(STDOUT, level: :error)

  LOGGER.formatter = proc do |sev, ts, prg, msg|
    time = ts.strftime '%Y-%m-%d %H:%M:%S %z'
    text = case msg
      when Exception
        trace = msg.backtrace.map {|x| "TRACE> #{x}" }
        "#{msg.message} (#{msg.class})\n#{trace.join("\n")}"
      when String
        msg
      else
        msg.inspect
    end

    "[#{sev}] [#{time}] #{prg.upcase}: #{text}\n"
  end
end

require_relative 'bot'
require_relative 'utils'
require_relative 'parser'
require_relative 'command'
require_relative 'database'

$bot = Selfbot::Bot.new(Selfbot::BOTOPTS, Selfbot::CONFIG)

$bot.ext_add(:cmd, Selfbot::CommandSystem, Selfbot::CMD_PREFIX)
$bot.ext_add(:dbc, Selfbot::Database, Selfbot::DBCOPTS)

require_relative 'utils/status'
require_relative 'utils/eval'

require_relative 'defs/events'
require_relative 'defs/commands'
require_relative 'defs/database'

begin
  $bot.run
rescue Interrupt
  puts("Received Ctrl-C, exiting...")
end

$bot.stop
