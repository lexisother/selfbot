require 'yaml'

module Selfbot
  class StatusHandler
    include BotExt

    KEYVALUE = 'rich_presence'

    def initialize(bot)
      @bot = bot
    end

    def load(raw: false)
      data = @bot.ext(:dbc).keyvalue(get: KEYVALUE)

      return data if raw
      data ? YAML.load(data) : false
    end

    def update(data, merge: false)
      game = {}

      if merge
        yml = @bot.ext(:dbc).keyvalue(get: KEYVALUE)
        game.merge!(YAML.load(yml)) unless yml.nil?
      end

      game.merge!(data)
      @bot.ext(:dbc).keyvalue(set: KEYVALUE, value: YAML.dump(game))

      game
    end

    def reset
      @bot.ext(:dbc).keyvalue(clear: KEYVALUE)
      nil
    end

    def submit!(status: nil)
      @bot.update_presence(status: status, game: self.load)
      nil
    end
  end
end
