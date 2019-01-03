require 'yaml'

module Selfbot
  class StatusHandler
    include BotExt

    KEYVALUE = 'rich_presence'

    def initialize(bot)
      @bot = bot
    end

    def load(raw: false, preset: nil)
      key = preset ? "#{KEYVALUE}@#{preset}" : KEYVALUE
      data = @bot.ext(:dbc).keyvalue(get: key)

      raw ? data : (data ? YAML.load(data) : false)
    end

    def save(data, raw: false, preset: nil)
      key = preset ? "#{KEYVALUE}@#{preset}" : KEYVALUE

      if data
        data = YAML.dump(data) unless raw
        @bot.ext(:dbc).keyvalue(set: key, value: data)
      else
        @bot.ext(:dbc).keyvalue(clear: key)
      end
    end

    def list_presets
      key = "#{KEYVALUE}@"
      list = @bot.ext(:dbc).keyvalue(find: key)

      list.map! {|x| x[key.length..-1] }
      list.select! {|x| yield x } if block_given?

      list
    end

    def update(data, merge: false)
      game = {}

      if merge
        yml = @bot.ext(:dbc).keyvalue(get: KEYVALUE)
        game.merge!(YAML.load(yml)) unless yml.nil?
      end

      game.merge!(data)
      game.reject! {|_,v| v.nil? }
      @bot.ext(:dbc).keyvalue(set: KEYVALUE, value: YAML.dump(game))

      game
    end

    def submit!(status: nil)
      @bot.update_presence(status: status, game: self.load)
    end
  end
end
