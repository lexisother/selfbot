module Discordrb
  class User
    def current_bot?
      false
    end
  end
end

module Selfbot
  module BotExt; end

  class Bot < Discordrb::Bot
    attr_reader :config

    EVENTS = {
      ready: Discordrb::Events::ReadyEvent,
      heartbeat: Discordrb::Events::HeartbeatEvent,
      disconnect: Discordrb::Events::DisconnectEvent,

      update_user: Discordrb::Events::ServerUpdateEvent,
      create_server: Discordrb::Events::ServerCreateEvent,
      update_server: Discordrb::Events::ServerUpdateEvent,
      delete_server: Discordrb::Events::ServerDeleteEvent,
      update_emoji: Discordrb::Events::ServerEmojiChangeEvent,
      ban_user: Discordrb::Events::UserBanEvent,
      unban_user: Discordrb::Events::UserUnbanEvent,

      create_role: Discordrb::Events::ServerRoleCreateEvent,
      update_role: Discordrb::Events::ServerRoleUpdateEvent,
      delete_role: Discordrb::Events::ServerRoleDeleteEvent,
      create_member: Discordrb::Events::ServerMemberAddEvent,
      update_member: Discordrb::Events::ServerMemberUpdateEvent,
      delete_member: Discordrb::Events::ServerMemberDeleteEvent,

      create_channel: Discordrb::Events::ChannelCreateEvent,
      update_channel: Discordrb::Events::ChannelUpdateEvent,
      delete_channel: Discordrb::Events::ChannelDeleteEvent,
      update_webhooks: Discordrb::Events::WebhookUpdateEvent,
      add_recipient: Discordrb::Events::ChannelRecipientAddEvent,
      remove_recipient: Discordrb::Events::ChannelRecipientRemoveEvent,

      create_message: Discordrb::Events::MessageEvent,
      channel_message: Discordrb::Events::MessageEvent,
      private_message: Discordrb::Events::PrivateMessageEvent,
      edit_message: Discordrb::Events::MessageUpdateEvent,
      delete_message: Discordrb::Events::MessageDeleteEvent,
      add_reaction: Discordrb::Events::ReactionAddEvent,
      remove_reaction: Discordrb::Events::ReactionRemoveEvent,
      toggle_reaction: Discordrb::Events::ReactionEvent,
      clear_reactions: Discordrb::Events::ReactionRemoveAllEvent,
      start_typing: Discordrb::Events::TypingEvent,

      # presence: Discordrb::Events::PresenceEvent,
      update_presence: Discordrb::Events::PresenceEvent,
      update_voice_state: Discordrb::Events::VoiceStateUpdateEvent,
    }.freeze

    def initialize(opts, config)
      ignore_self = false

      if opts.key?(:ignore_self)
        ignore_self = opts[:ignore_self]

        opts.delete(:ignore_self)
      end

      super(**opts)
      if ignore_self == true
        ignore_user(profile.id)
      end

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

    # TODO: REFACTOR!!!
    def add_event(type, key = nil, **filter, &blk)
      raise ArgumentError, "Invalid event type: #{type}" unless EVENTS.key?(type)

      mappedEvent = EVENTS[type]
      add_await(key, mappedEvent) do |event|
        handleEvent = true

        if type == :create_message
          if filter.key?(:user)
            handleEvent = event.user.id.to_s == filter[:user].to_s
          end
          if filter.key(:include)
            handleEvent = filter[:include].match?(event.message.content)
          end
        end

        blk.call(event) if handleEvent
      end
    end
  end
end
