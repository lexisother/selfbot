module Selfbot
  # Helper DSL for defining command arguments
  module Defs
    class CmdArgs
      attr_accessor :instance

      def count(count)
        @instance[:count] = count
      end

      def mode(mode)
        @instance[:mode] = mode
      end

      def types(*types)
        @instance[:types] = types
      end
    end

    def self.CmdArgs(&block)
      params = CmdArgs.new
      params.instance = {}

      params.instance_exec(&block) if block
      CommandArgs.new(**params.instance)
    end
  end

  class CommandEvent < MijDiscord::Events::Message
    attr_reader :command

    def initialize(bot, message, command)
      super(bot, message)

      @command = command
    end
  end

  class CommandError < RuntimeError; end

  class CommandArgs
    attr_reader :mode, :count, :types

    def initialize(**params)
      @mode = params[:mode] || :words
      @count = params[:count] || (0..-1)
      @types = params[:types] || nil
    end

    def call(event, argstr)
      args = case @mode
        when :concat
          Selfbot::Parser::ArgumentConcat
        when :words
          Selfbot::Parser::ArgumentWords
        else
          @mode.respond_to?(:call) ?
            @mode : (raise ArgumentError, 'Bad argument handler')
      end.call(argstr)

      if args.length < @count.first
        raise CommandError, "Too few arguments (expected #{@count.first}, got #{args.length})"
      elsif @count.last > -1 && args.length > @count.last
        raise CommandError, "Too many arguments (expected #{@count.last}, got #{args.length})"
      end

      Selfbot::Parser::TypedArguments.call(args, @types, event)
    end
  end

  class Command
    attr_reader :name, :block, :args

    def initialize(name, args = nil, **params, &block)
      @name, @args, @block = name, args, block

      @owner_only = !!params[:owner_only]

      if @args.nil?
        @args = CommandArgs.new(
          mode: params[:arg_mode],
          count: params[:arg_count],
          types: params[:arg_types])
      end
    end

    def execute(event, argstr)
      @block.call(event, *@args.call(event, argstr))
    end
  end

  class CommandSystem
    def initialize(nprefix, dprefix)
      @nprefix, @dprefix = nprefix, dprefix
      @commands = {}
    end

    def register(name, args: nil, **params, &block)
      name = name.to_sym
      @commands[name] = Command.new(name, args, **params, &block)
    end

    def unregister(name)
      @commands.delete(name.to_sym)
    end

    def commands(name)
      name.nil? ? @commands.keys : @commands[name.to_sym]
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
