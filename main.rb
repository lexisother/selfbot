require 'mij-discord'

module Selfbot
  # Load config before anything else
  require_relative 'config'

  module Defs; end
end

require_relative 'bot'
require_relative 'utils'
require_relative 'parser'
require_relative 'command'
require_relative 'database'

$bot = Selfbot::Bot.new(Selfbot::BOTOPTS, Selfbot::CONFIG)
MijDiscord::LOGGER.level = :info

$bot.ext_add(:cmd, Selfbot::CommandSystem, Selfbot::CMD_PREFIX)
$bot.ext_add(:dbc, Selfbot::Database, Selfbot::DBCOPTS)

require_relative 'utils/status'
require_relative 'utils/eval'

require_relative 'defs/events'
require_relative 'defs/commands'
require_relative 'defs/database'

begin
  $bot.connect(false)
rescue Interrupt
  puts("Received Ctrl-C, exiting...")
end

$bot.disconnect
