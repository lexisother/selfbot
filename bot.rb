module Selfbot
  module BotExt; end

  class Bot < Discordrb::Bot
    attr_reader :config

    def initialize(opts, config)
      ignore_self = false

      if opts.key?(:ignore_self)
        ignore_self = true if ignore_self

        opts.delete(:ignore_self)
      end

      super(**opts)
      self.ignore_user(self.profile.id) if ignore_self

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

    def stop
      @extlist.each_value do |ext|
        ext.disconnect if ext.respond_to?(:disconnect)
      end

      super
    end

    def add_event(*args)
      # TODO: map first argument to event Discordrb::Events::*, pass rest to add_await (which seems unstable)
    end
  end
end
