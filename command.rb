module Selfbot
  class CommandEvent < MijDiscord::Events::Message
    attr_reader :command

    def initialize(bot, message, command)
      super(bot, message)

      @command = command
    end
  end

  class CommandError < RuntimeError; end

  class Command
    attr_reader :name, :block
    attr_reader :arg_count, :arg_mode, :arg_types
    attr_reader :owner_only

    def initialize(name, params = {}, &block)
      @name, @block = name, block

      @arg_count = params[:arg_count] || (0..-1)
      @arg_mode = params[:arg_mode] || :words
      @arg_types = params[:arg_types]

      @owner_only = !!params[:owner_only]
    end

    def call(event, args)
      if args.length < @arg_count.first
        raise CommandError, "Too few arguments (expected #{@arg_count.first}, got #{args.length})"
      elsif @arg_count.last > -1 && args.length > @arg_count.last
        raise CommandError, "Too many arguments (expected #{@arg_count.last}, got #{args.length})"
      end

      args = Selfbot::Parser::TypedArguments.call(args, @arg_types, event)

      owners = Selfbot::CONFIG.dig(:system, :owners)
      if owners && @owner_only && !owners.include?(event.user.id)
        raise CommandError, 'Command is restricted to owner only'
      end

      @block.call(event, *args)
    end

    def execute(event, argstr)
      args = case @arg_mode
        when :concat
          Selfbot::Parser::ArgumentConcat.call(argstr)
        when :words
          Selfbot::Parser::ArgumentWords.call(argstr)
        else
          if @arg_mode.respond_to?(:call)
            @arg_mode.call(argstr)
          else
            raise CommandError, 'Invalid argument handler'
          end
      end

      call(event, args)
    end
  end

  class CommandSystem
    def initialize(nprefix, dprefix)
      @nprefix, @dprefix = nprefix, dprefix
      @commands = {}
    end

    def register(name, **params, &block)
      name = name.to_sym
      @commands[name] = Command.new(name, params, &block)
    end

    def unregister(name)
      @commands.delete(name.to_sym)
    end

    def commands
      @commands.keys
    end

    def execute(event, string = nil)
      string = event.message.content unless string

      prefix, is_del = nil

      if @dprefix && string.start_with?(@dprefix)
        prefix, is_del = @dprefix, true
      elsif @nprefix && string.start_with?(@nprefix)
        prefix, is_del = @nprefix, false
      end

      return unless prefix

      ignore_srv = Selfbot::CONFIG.dig(:system, :ignore_srv)
      return if ignore_srv.include?(event.server.id)

      ignore_chan = Selfbot::CONFIG.dig(:system, :ignore_chan)
      return if ignore_chan.include?(event.channel.id)

      string = string[prefix.length .. -1].strip
      match = string.match(/\A(\S+)(?:\s+(.+))?\z/m)
      name, argstr = match[1].downcase.to_sym, match[2] || ''

      if (cmd = @commands[name])
        result = begin
          event = CommandEvent.new(event.bot, event.message, cmd)
          cmd.execute(event, argstr)
        rescue CommandError => exc
          "\u{274C} #{exc.message}"
        rescue => exc
          "```\n(#{exc.class})\n#{exc.message}\n```"
        end

        sleep(Selfbot::CONFIG.dig(:system, :cmd_wait))
        event.message.delete if is_del

        text, embed = '', nil

        case result
          when nil then return
          when Hash
            embed = result
            text = result.fetch(:message, '')
          else
            text = result.to_s
        end

        event.channel.send_message(text: text, embed: embed)
      end

      nil
    end

    def configure(bot)
      bot.add_event(:create_message,
      user: Selfbot::BOTOPTS[:client_id],
      include: %r(\A#{@prefix}\S+)) {|e| execute(e) }
    end
  end
end
