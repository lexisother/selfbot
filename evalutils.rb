module Selfbot
  class EvalStorage < BasicObject
    DELEGATE = [:to_s, :to_a, :to_h, :to_hash, :to_enum, :to_proc]

    def [](idx)
      if DELEGATE.include?(idx)
        raise ArgumentError, "Cannot use reserved key '#{idx}'"
      end

      @storage ||= {}
      @storage[idx]
    end

    def []=(idx, val)
      if DELEGATE.include?(idx)
        raise ArgumentError, "Cannot use reserved key '#{idx}'"
      end

      @storage ||= {}
      @storage[idx] = val
    end

    def method_missing(name, *args)
      if DELEGATE.include?(name)
        @storage ||= {}
        return @storage.send(name, *args)
      end

      name =~ /^(.+?)(=?)$/
      if $2.empty?
        self[$1.to_sym]
      else
        self[$1.to_sym] = args.first
      end
    end

    def inspect
      %(#<Storage #{@storage.inspect}>)
    end
  end

  class EvalContext
    attr_reader :event, :global, :print_buffer

    # Lua-compatible `global` alias
    def _G
      @global
    end

    def initialize(event, global)
      @event, @global = event, global
    end

    def drain_print_buffer
      ret = @print_buffer
      @print_buffer = nil
      ret.chomp
    end

    def has_print_buffer?
      !@print_buffer.nil?
    end

    def protected_eval(_code)
      return true, instance_eval(_code)
    rescue Exception => _error
      return false, _error
    end

    ## User functions below

    def print(*args)
      @print_buffer ||= String.new
      @print_buffer << args.join
      nil
    end

    def puts(*args)
      args << "\n"
      print(*args)
    end

    def reply(text, fmt: nil)
      text = case fmt
        when true
          "```\n#{text}\n```"
        when Symbol, String
          "```#{fmt}\n#{text}\n```"
        else
          text.to_s
      end

      sleep(Selfbot::CONFIG.dig(:system, :reply_wait))
      @event.channel.send_message(text: text)
    end

    def embed(**args)
      text = args.delete(:message).to_s

      sleep(Selfbot::CONFIG.dig(:system, :reply_wait))
      @event.channel.send_message(text: text, embed: args)
    end
  end
end
