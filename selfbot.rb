require 'mij-discord'

module Selfbot
  auth = ENV['AUTH'].split(/\s+/)
  exit(-1) if auth.length < 2

  BOTOPTS = {
    type: :user,
    client_id: auth[0],
    token: auth[1],
    ignore_bots: true,
    ignore_self: false,
  }.freeze

  DBCOPTS = {
    dbname: 'mijyu',
  }.freeze

  CONFIG = {
    system: {
      owners: [243061915281129472],

      cmd_wait: 0.50,
      reply_wait: 0.33,
    },

    thonk: [3, 4..8],
  }

  PREFIX = '%'
end

require_relative 'parser'
require_relative 'evalutils'
require_relative 'command'
require_relative 'database'

$bot = MijDiscord::Bot.new(**Selfbot::BOTOPTS)
MijDiscord::LOGGER.level = :info

$cmd = Selfbot::CommandSystem.new(Selfbot::PREFIX)
$cmd.configure($bot)

$dbc = Selfbot::Database.new(**Selfbot::DBCOPTS)

module Selfbot::Defs
  require_relative 'defs/events'
  require_relative 'defs/commands'
  require_relative 'defs/database'
end

begin
  $bot.connect(false)
rescue Interrupt
  puts("Received Ctrl-C, exiting...")
end

$bot.disconnect
$dbc.disconnect
