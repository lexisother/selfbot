module Selfbot
  module BotExt; end

  class Bot < MijDiscord::Bot
    attr_reader :config

    def initialize(opts, config)
      super(**opts)

      @config = config
      @extlist = {}
    end

    def ext(name)
      @extlist[name]
    end

    def ext_add(name, clazz, *args, &blk)
      hasbot = clazz.include?(BotExt)
      args.unshift(self) if hasbot

      ext = clazz.new(*args)
      ext.instance_exec(self, &blk) if blk

      @extlist[name] = ext
      nil
    end

    def disconnect
      @extlist.each_value do |ext|
        ext.disconnect if ext.respond_to?(:disconnect)
      end

      super
    end
  end
end
