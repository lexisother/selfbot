require 'optparse'

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

      def flag(key, option, type = nil, value = nil)
        flags = (@instance[:flags] ||= [])
        flags << {
          key: key.to_sym,
          option: option,
          type: type,
          value: value,
        }.freeze
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
    attr_reader :mode, :count, :types, :flags

    def initialize(**params)
      @mode = params[:mode] || :words
      @count = params[:count] || (0..-1)
      @types = params[:types] || nil

      if (@flags = params[:flags])
        @flags.freeze
        @flag_parser = OptionParser.new

        @flags.each do |flag|
          opt, key = flag[:option], flag[:key]
          @flag_parser.on(opt) {|val| @flag_data[key] = val }
        end
      end
    end

    def call(event, argstr)
      if @flag_parser
        # Disgusting hack!!! Rewrite later.
        # "Tokenizes" the string by spaces and preserves them
        args, spaces = [], []
        argstr.scan(/(\A|\s+)(\S+)/) do |sp, txt|
          spaces << sp
          args << txt
        end
        args_len = args.length

        begin
          @flag_data = {}
          @flag_parser.parse!(args)

          @flags.each do |flag|
            key, type, default = flag[:key], flag[:type]
            value = @flag_data.fetch(key, flag[:value])

            # Kludge
            next if value.nil? && !@flag_data.key?(key)

            unless type.nil? || value.nil?
              ok, value = Selfbot::Parser::TypedArguments.parse_item(value, type, event)
              raise CommandError, "Failed to parse flag '#{key}'" unless ok
            end

            @flag_data[key] = value
          end
        rescue OptionParser::ParseError => exc
          @flag_data = nil
          raise CommandError, exc.message
        end

        # Disgusting hack!!! Rewrite later.
        # Reconstructs remaining arguments with original spacing
        argstr = args.shift
        spaces.shift(args_len - args.length)
        spaces.zip(args).each do |s, a|
          argstr << s << a
        end
      end

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

      args = Selfbot::Parser::TypedArguments.call(args, @types, event)

      if @flag_data
        args.unshift(@flag_data)
        @flag_data = nil
      end

      args
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
