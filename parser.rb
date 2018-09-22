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
    MATCHER = /\G\s*(?>```(.*?)```|([^\s"`]+)|`([^`]*)`|("")|"((?:[^"]|"")*)"|(\S))(\s|\z)?/m

    def self.call(input)
      words, accum = [], ''

      input.scan(MATCHER) do |blk, rw, bw, esc, qw, crap, sep|
        raise Selfbot::CommandError, 'Mismatched quotes or backticks' if crap

        if blk
          unless accum.empty?
            words << accum
            accum = ''
          end

          words << blk
        else
          accum << (rw || bw || (esc || qw)&.gsub('""', '"'))

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
    def self.call(items, types, server)
      return items unless types

      items.each_with_index.map do |item, i|
        type = types[i] || types.last
        next item if type.nil?

        item = parse_item(item, type, server)
        raise Selfbot::CommandError, "Failed to parse argument ##{i+1}" if item.nil?

        item == NilClass ? nil : item
      end
    end

    private

    def self.parse_item(item, type, server)
      if type.is_a?(Array)
        return type.reduce(nil) do |a,x|
          a.nil? ? parse_item(item, x, server) : a
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
        when :user
          server.bot.parse_mention(item, nil, type: type)
        when :member, :channel, :role, :emoji
          server.bot.parse_mention(item, server, type: type)
        when :invite
          server.bot.parse_invite_code(item)
        else
          type.respond_to?(:from_argument) && type.from_argument(item)
      end
    rescue ArgumentError, RegexpError, Psych::Exception
      nil
    end
  end
end
