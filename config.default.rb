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

      ignore_srv: [
      ],
      ignore_chan: [
      ],

      cmd_wait: 0.50,
      reply_wait: 0.33,
    },

    thonk: [3, 4..8],
  }

  PREFIX_MAIN = "%"

  PREFIX_DEL = nil
end
