module Selfbot::Defs
  ## CMD: thonk ##

  THONKS = %w[
    TODO
  ]

  $cmd.register(:thonk, arg_count: 0..0) do |_|
    ns, nr = Selfbot::CONFIG[:thonk]
    thonk = THONKS.sample(ns).map {|x| x * rand(nr) }.join

    "***T H O N K . . .*** #{thonk}"
  end

  ## CMD: letters ##

  LETTERS_MATCH = /\G([a-z]+)|([0-9]+)|(!?[!?]| )|(?:{(\w*)(?:=([^}]*))?})|(.)/im
  LETTERS_NUM = %w[zero one two three four five six seven eight nine]
  LETTERS_MISC = {
    "!!" => ":bangbang:",
    "!?" => ":interrobang:",
    "!" => ":exclamation:",
    "?" => ":question:",
  }
  LETTERS_FUNC = {
    "a" => ":a:", "b" => ":b:",
    "o" => ":o2:", "ab" => ":ab:",
    "i" => ":information_source:",
    "0" => ":o:", "x" => ":x:",
    "p" => ":parking:", "ok" => ":ok:",
    "cool" => ":cool:", "new" => ":new:",

    "meme" => "<:meme:424666219686395904>",
    "bonk" => "<:bonk:433341788900818975>",
    "del" => "<:delet:426906577761468417>",
    "out" => "<:getout:435188560283435010>",
    "nani" => "<:nani:412103942646923264>",

    "" => proc {|x| "#{x}" },
  }

  $cmd.register(:letters,
  arg_mode: :concat) do |_, argstr|
    result = String.new

    argstr.scan(LETTERS_MATCH) do |let, num, misc, func, farg, other|
      result << case true
        when !!let
          let.gsub(/[a-z]/i) {|x| ":regional_indicator_#{x.downcase}:\u200B"}
        when !!num
          num.gsub(/[0-9]/) {|x| ":#{LETTERS_NUM[x.to_i]}:"}
        when !!misc
          LETTERS_MISC[misc] || misc
        when !!func
          func = LETTERS_FUNC[func.downcase] || "{#{func}}"
          func.respond_to?(:call) ? func.call(farg) : func
        else other
      end
    end

    result
  end

  ## CMD: tm ##

  $cmd.register(:tm,
  arg_mode: :concat) do |_, argstr|
    result = argstr.chars.each_with_index.map {|x, i| i.even? ? x.upcase : x.downcase}.join(' ')
    result.gsub!(/<\s:\s(?:\w\s)+:\s(?:\d\s)+>/) {|x| x.gsub(/\s/, "") }
    result.gsub!(/<\s(?:@\s!|@\s&|@|#)\s(?:\d\s)+>/) {|x| x.gsub(/\s/, "") }

    "***#{result} \u2122***"
  end

  ## CMD: cowsay ##

  $cmd.register(:cowsay,
  arg_mode: :concat) do |_, argstr|
    if argstr == '*?'
      result = %x(cowsay -l | sed "1 d").split(/\s+/).join(' ')

      next "```\n#{result}\n```"
    end

    match = argstr.match(/\*(\S+)\s+(.+)/)
    params = match ? match[1..2] : ["default", argstr]
    fmt, text = params.map(&:shellescape)
    result = %x(echo #{text} | cowsay -n -f #{fmt} 2>&1)

    "```\n#{result}\n```"
  end

  ## CMD: junk ##

  $cmd.register(:junk,
  arg_count: 1..1, arg_types: [:integer]) do |_, count|
    %x(mkjunk #{count} 2>&1)
  end

  ## CMD: wetquote ##

  $cmd.register(:wetquote,
  arg_count: 0..1, arg_types: [:integer]) do |_, count|
    count = [1, count || 1].max
    %x(wetquote -c #{count})
  end

  ## CMD: eval ##

  EVAL_GLOBALS = Selfbot::EvalStorage.new

  $cmd.register(:eval,
  arg_mode: :concat) do |event, argstr|
    argstr = argstr.strip.gsub(/\A\w+\n/i, '')
    context = Selfbot::EvalContext.new(event, EVAL_GLOBALS)
    status, value = context.protected_eval(argstr)

    result = if status
      argstr.end_with?(";") ? nil : "```rb\n#{value.inspect}\n```"
    else
      "```\n(#{value.class})\n#{value.message}\n```"
    end

    if context.has_print_buffer?
      result = "```\n#{context.drain_print_buffer}\n``` #{result || ''}"
    end

    if result && result.length > 1950
      result = result[0..1950] + "\n```"
    end

    result
  end

  ## CMD: sh ##

  $cmd.register(:sh,
  arg_mode: :concat) do |_, argstr|
    require 'shellwords'

    result = %x(fish -c #{argstr.shellescape} 2>&1)
    next if result =~ /^\s*$/

    "```\n#{result[0..1950]}\n```"
  end

  ## CMD: sql ##

  $cmd.register(:sql,
  arg_mode: :concat) do |_, argstr|
    require 'terminal-table'

    begin
      query = $dbc.query(argstr)
      result = Terminal::Table.new do |t|
        t.headings = query.fields
        t.rows = query.entries.map(&:values)
        t.style = {border_top: false, border_bottom: false}
      end

      result.gsub!(/^[|+]|[|+]$/, '')
      "```\n#{result[0..1950]}\n```"

    rescue PG::Error => exc
      msg, *rest = exc.message.split("\n")
      "\u{274C} #{msg}\n```\n#{rest.join("\n")}\n```"
    end
  end

  ## CMD: avatar ##

  $cmd.register(:avatar,
  arg_count: 1..-1, arg_types: [ [:user, :nil] ]) do |_, *args|
    args.map {|x| x&.avatar_url || '(Invalid User)' }.join("\n")
  end

  ## CMD: emoji ##

  $cmd.register(:emoji,
  arg_count: 1..-1, arg_types: [ [:emoji, :nil] ]) do |_, *args|
    args.map {|x| x&.icon_url || '(Invalid Emoji)' }.join("\n")
  end

  ## CMD: status ##

  STATUS_FIELDS = [
    :type, :name, :url,
    :details, :state,
    :application,
    :small_image, :small_text,
    :large_image, :large_text,
    :start_time, :end_time,
  ].freeze

  $cmd.register(:status,
  arg_count: 1..1, arg_types: [:yaml]) do |event, data|
    "NOT IMPLEMENTED"
  end

  ## CMD: pick ##

  $cmd.register(:pick,
  arg_count: 1..-1, arg_types: [:string]) do |event, *args|
    %(\u{1F3B2} The Computer™ has picked "#{args.shuffle.sample}")
  end

  ## CMD: tag ##

  $cmd.register(:tag,
  arg_count: 1..-1, arg_types: [:string]) do |event, tag, *args|
    next "\u{274C} Tag name cannot be empty" if tag.empty?

    result = $dbc.query(TAG_FIND, [tag.downcase])
    if result.none?
      %(\u{274C} Tag "#{tag}" not found)
    else
      result.first['content']
    end
  end

  ## CMD: tag? ##

  $cmd.register(:"tag?",
  arg_count: 0..1, arg_types: [:iregexp]) do |event, filter|
    result = $dbc.query(TAG_LIST, [event.bot.profile.id])

    tags = result.map {|x| x['tag'] }
    tags.select! {|x| x =~ filter } if filter
    tags.sort!

    "```\n#{tags.join("\t")}\n```"
  end

  $cmd.register(:"tag+",
  arg_count: 2..2, arg_types: [:string]) do |event, tag, data|
    next "\u{274C} Tag name cannot be empty" if tag.empty?

    begin
      $dbc.query(TAG_ADD, [tag, event.bot.profile.id, data])
      %(\u{2705} Added tag "#{tag}")
    rescue PG::UniqueViolation
      %(\u{274C} Tag "#{tag}" already exists)
    end
  end

  $cmd.register(:"tag=",
  arg_count: 2..2, arg_types: [:string]) do |event, tag, data|
    next "\u{274C} Tag name cannot be empty" if tag.empty?

    begin
      result = $dbc.query(TAG_EDIT, [tag, data])
      if result.cmd_tuples > 0
        %(\u{2705} Updated tag "#{tag}")
      else
        %(\u{274C} Tag "#{tag}" not found)
      end
    end
  end

  $cmd.register(:"tag-",
  arg_count: 1..1, arg_types: [:string]) do |event, tag|
    next "\u{274C} Tag name cannot be empty" if tag.empty?

    begin
      result = $dbc.query(TAG_REMOVE, [tag, nil])
      if result.cmd_tuples > 0
        %(\u{2705} Removed tag "#{tag}")
      else
        %(\u{274C} Tag "#{tag}" not found)
      end
    end
  end
end
