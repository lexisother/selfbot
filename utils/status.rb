module Selfbot
  class RichPresence
    include BotExt

    def initialize(bot)
      @bot = bot
    end
  end
end
