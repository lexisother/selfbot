require 'time'
require 'yaml'

module Selfbot::Parser
  module ArgumentConcat
    MATCHER = /\A(```|`(?!`))(.*?)\1\z/m

    def self.call(input)
      [ input.gsub(MATCHER, '\2') ]
    end
  end

  module ArgumentWords
    MATCHER = /\G\s*(?>```(.*?)```|([^\s"`]+)|``(.*?)``|`([^`]*)`|("")|"((?:[^"]|"")*)"|(\S))(\s|\z)?/m

    def self.call(input)
      words, accum = [], ''

      input.scan(MATCHER) do |blk, rw, bw2, bw, esc, qw, crap, sep|
        raise Selfbot::CommandError, 'Mismatched quotes or backticks' if crap

        if blk
          unless accum.empty?
            words << accum
            accum = ''
          end

          words << blk
        else
          accum << (rw || bw2 || bw || (esc || qw)&.gsub('""', '"'))

          if sep
            words << accum
            accum = ''
          end
        end
      end

      words
    end
  end

  module TypedArguments
    def self.call(items, types, context)
      return items unless types

      items.each_with_index.map do |item, i|
        type = types[i] || types.last
        next item if type.nil?

        item = parse_item(item, type, context)
        raise Selfbot::CommandError, "Failed to parse argument ##{i+1}" if item.nil?

        item == NilClass ? nil : item
      end
    end

    private

    def self.parse_item(item, type, context)
      if type.is_a?(Array)
        return type.reduce(nil) do |a,x|
          a.nil? ? parse_item(item, x, context) : a
        end
      end

      case type
        when :string
          item
        when :symbol
          item.to_sym
        when :integer
          Integer(item)
        when :float
          Float(item)
        when :rational
          Rational(item)
        when :time
          Time.parse(item).utc
        when :bool
          case item.downcase
            when 'true', 'yes', 'on' then true
            when 'false', 'no', 'off' then false
          end
        when :regexp
          Regexp.new(item)
        when :iregexp
          Regexp.new(item, true)
        when :nil
          NilClass
        when :yaml
          YAML::load(item.gsub(/\A\w+\n/, ''))
        when :user, :member, :channel, :role, :emoji, :message
          MentionParser.call(item, context, type: type)
        when :invite
          context.bot.parse_invite_code(item)
        else
          type.respond_to?(:from_argument) && type.from_argument(item)
      end
    rescue ArgumentError, RegexpError, Psych::Exception
      nil
    end
  end

  module MentionParser
    def self.call(mention, context, type: nil)
      mention = mention.to_s.strip
      # context = make_context(context)

      if !type.nil? && mention =~ /^(\d+)$/
        parse_mention_id($1, type, context)

      elsif mention =~ /^<@!?(\d+)>$/
        return nil if type && type != :user && type != :member
        parse_mention_id($1, type || :user, context)

      elsif mention =~ /^<#(\d+)>$/
        return nil if type && type != :channel
        parse_mention_id($1, type || :channel, context)

      elsif mention =~ /^<@&(\d+)>$/
        return nil if type && type != :role
        parse_mention_id($1, type || :role, context)

      elsif mention =~ /^<(a?):(\w+):(\d+)>$/
        return nil if type && type != :emoji
        parse_mention_id($1, type || :emoji, context) || begin
           em_data = { 'id' => $3.to_i, 'name' => $2, 'animated' => !$1.empty? }
           MijDiscord::Data::Emoji.new(em_data, nil)
        end

      elsif mention =~ /^(\d+)-(\d+)$/
        return nil if type && type != :message
        context.bot.channel($1)&.message($2)
      end
    end

    private

    def self.parse_mention_id(mention, type, context)
      case type
        when :user
          context.bot.user(mention)
        when :member
          context.server&.member(mention)
        when :channel
          context.server&.member(mention)
        when :role
          context.server&.role(mention)
        when :emoji
          context.server&.emoji(mention)
        when :message
          context.channel&.message(mention)
        else
          raise ArgumentError, "Invalid mention type '#{type}'"
      end
    end

    # def self.make_context(context)
    #   case context
    #     when Context then context
    #     when MijDiscord::Bot
    #       Context.new.do { self.bot = context }
    #     when MijDiscord::Data::Server
    #       Context.new.do { self.server = context }
    #     when MijDiscord::Data::Channel
    #       Context.new.do { self.channel = context }
    #     when MijDiscord::Data::Message
    #       Context.new.do { self.message = context }
    #     else
    #       raise TypeError, "Bad context class #{context.class}"
    #   end
    # end
  end
end
