module Selfbot::Defs
  _cmd = $bot.ext(:cmd)

  ## CMD: thonk ##

  THONKS = %w[
    <:thonkang:349702669910147072> <:thankong:349702642425004032>
    <:thunkeng:364556235498061834> <:thwonknag:364556224609386496>
    <:thonkery:416978735791865857> <:thonkwoke:364556414292852739>
    <:thowonkang:364556266309287936> <:megathink:412085787849523200>
    <:blob_thonk:390657789606887424> <:blob_thonkwoke:412140519150452736>
    <:think_eyes:412085787908112384> <:tunk:426355695433285647>
    <:tonk:428138276621123587> <:tinkung:453389313716125707>
    <:tink:421306955194171402> <:thonkin:438354764720242689>
    <:thinking2:459788749434388510> <:thinkies:422024407368597505>
    <:thenkeng:433342330549043202> <:blob_thonkang:435181996495470602>
    <:blob_thinkcool:431648649135652864> <:blob_thinkeyes:431648649349431306>
    <:thankang:468827164838461450>
  ]

  _cmd.register(:thonk,
  arg_count: 0..1) do |_, flag|
    count, dist = Selfbot::CONFIG[:thonk]

    count = $1.to_i if flag =~ /d(\d+)/i
    dist = ($1.to_i .. dist.last) if flag =~ /l(\d+)/i
    dist = (dist.first .. $1.to_i) if flag =~ /h(\d+)/i

    thonk = THONKS.sample(count).map {|x| x * (rand(dist) || 1) }.join

    flag =~ /c/i ?
      thonk : "***T H O N K . . .*** #{thonk}"
  end

  ## CMD: letters ##

  LETTERS_MATCH = /\G([a-z]+)|([0-9]+)|(!?[!?]| )|(?:{(\w*)(?:=([^}]*))?})|(<[^>]*?>)|(.)/im
  LETTERS_NUM = %w[zero one two three four five six seven eight nine]
  LETTERS_MISC = {
    "!!" => ":bangbang:",
    "!?" => ":interrobang:",
    "!" => ":exclamation:",
    "?" => ":question:",
    " " => "\u{3000}",
  }
  LETTERS_FUNC = {
    "a" => ":a:", "b" => ":b:",
    "o" => ":o2:", "ab" => ":ab:",
    "i" => ":information_source:",
    "0" => ":o:", "x" => ":x:",
    "p" => ":parking:", "ok" => ":ok:",
    "cool" => ":cool:", "new" => ":new:",

    "bonk" => "<:bonk:433341788900818975>",
    "meme" => "<:meme:522375281504419884>",
    "del" => "<:delet:522375281760010250>",
    "out" => "<:getout:522375281693163532>",
    "smh" => "<:smh:522375351523868672>",
    "nani" => "<:nani:412103942646923264>",
  }

  _cmd.register(:letters,
  arg_mode: :concat) do |_, argstr|
    result = String.new

    argstr.scan(LETTERS_MATCH) do |let, num, misc, func, farg, raw, other|
      result << case true
        when !!let
          let.gsub(/[a-z]/i) {|x| ":regional_indicator_#{x.downcase}:\u{200A}"}
        when !!num
          num.gsub(/[0-9]/) {|x| ":#{LETTERS_NUM[x.to_i]}:\u{200A}"}
        when !!misc
          LETTERS_MISC[misc] || misc
        when !!func
          func = LETTERS_FUNC[func.downcase] || "{#{func}}"
          func.respond_to?(:call) ? func.call(farg) : func
        else raw || other
      end
    end

    result
  end

  ## CMD: tm ##

  _cmd.register(:tm,
  arg_mode: :concat) do |_, argstr|
    result = argstr.chars.each_with_index.map {|x, i| i.even? ? x.upcase : x.downcase}.join(' ')
    result.gsub!(/<\s:\s(?:\w\s)+:\s(?:\d\s)+>/) {|x| x.gsub(/\s/, "") }
    result.gsub!(/<\s(?:@\s!|@\s&|@|#)\s(?:\d\s)+>/) {|x| x.gsub(/\s/, "") }

    "***#{result} \u2122***"
  end

  ## CMD: cowsay ##

  _cmd.register(:cowsay, args: CmdArgs do
    mode :concat

    flag :list, '-l'
    flag :cow, '-fX', nil, 'default'
  end) do |_, opts, argstr|
    require 'shellwords'

    if opts[:list]
      result = %x(cowsay -l | sed "1 d").split(/\s+/).join(' ')
      next "```\n#{result}\n```"
    end

    argstr = argstr.shellescape
    result = %x(echo #{argstr} | cowsay -n -f #{opts[:cow]} 2>&1)
    "```\n#{result}\n```"
  end

  ## CMD: junk ##

  _cmd.register(:junk,
  arg_count: 1..1, arg_types: [:integer]) do |_, count|
    %x(mkjunk #{count} 2>&1)
  end

  ## CMD: wetquote ##

  _cmd.register(:wetquote,
  arg_count: 0..2, arg_types: [:integer, :string]) do |_, count, cow|
    count = [1, count || 1].max
    if cow
      cow = cow.shellescape
      result = %x(wetquote -rc #{count} | cowsay -f #{cow} 2>&1)
      %(```\n#{result}\n```)
    else
      %x(wetquote -c #{count})
    end
  end

  ## CMD: uwut ##

  UWUT = %w[
    :uwut:517331842974744586 :uwut:371711644897771520
    :uwut1:488077317999165441 :uwut2:488077336185536523
    :uwut3:488077349951111171 :uwut4:488077359799468087
    :uwut5:488077370478034945 :uwut6:488077380045242368
    :uwut7:488077398345121795 :uwut8:488077473196802089
  ]

  _cmd.register(:uwut,
  arg_count: 1..1, arg_types: [:integer]) do |event, msgid|
    message = event.channel.message(msgid)
    next "\u{274C} Invalid message ID" unless message

    UWUT.each do |uwut|
      message.add_reaction(uwut)
      sleep(0.33)
    end

    nil
  end

  ## CMD: eval ##

  EVAL_GLOBALS = Selfbot::EvalStorage.new

  _cmd.register(:eval, args: CmdArgs do
    mode :concat
  end) do |event, argstr|
    # kludge
    opts = {quiet: argstr =~ /(#q|;)\s*$/i}

    argstr = argstr.strip.gsub(/\A\w+\n/i, '')
    context = Selfbot::EvalContext.new(event, EVAL_GLOBALS)
    status, value = context.protected_eval(argstr)

    result = if status
      opts[:quiet] ? nil : "```rb\n#{value.inspect}\n```"
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

  _cmd.register(:sh, args: CmdArgs do
    mode :concat
  end) do |_, argstr|
    # kludge
    opts = {quiet: argstr =~ /(#q|;)\s*$/i}

    require 'shellwords'

    result = %x(fish -c #{argstr.shellescape} 2>&1)
    next if opts[:quiet] || result =~ /^\s*$/

    "```\n#{result[0..1950]}\n```"
  end

  ## CMD: sql ##

  _cmd.register(:sql,
  arg_mode: :concat) do |event, argstr|
    require 'terminal-table'

    begin
      dbc = event.bot.ext(:dbc)
      query = dbc.query(argstr)
      result = Terminal::Table.new do |t|
        t.headings = query.fields
        t.rows = query.entries.map(&:values)
        t.style = {border_top: false, border_bottom: false}
      end.to_s

      result.gsub!(/^[|+]|[|+]$/, '')
      "```\n#{result[0..1950]}\n```"

    rescue PG::Error => exc
      msg, *rest = exc.message.split("\n")
      "\u{274C} #{msg}\n```\n#{rest.join("\n")}\n```"
    end
  end

  ## CMD: avatar ##

  _cmd.register(:avatar,
  arg_count: 1..-1, arg_types: [ [:user, :nil] ]) do |_, *args|
    args.map {|x| x&.avatar_url || '(Invalid User)' }.join("\n")
  end

  ## CMD: emoji ##

  _cmd.register(:emoji,
  arg_count: 1..-1, arg_types: [ [:emoji, :nil] ]) do |_, *args|
    args.map {|x| x&.icon_url || '(Invalid Emoji)' }.join("\n")
  end

  ## CMD: uinfo ##

  UINFO_ROLES_MAX = 5

  _cmd.register(:uinfo, args: CmdArgs do
    count 1..1
    types [:member, :user]

    flag :id, '-i'
    flag :un, '-u'
    flag :ct, '-c'
    flag :av, '-a'
    flag :usr, '-U'

    flag :nk, '-n'
    flag :jt, '-j'
    flag :rl, '-r'
    flag :mbr, '-M'

    flag :big, '-A'
  end) do |event, opts, user|
    output = []

    output << "ID: `#{user.id}`" if opts.try_keys(:id, :usr)
    output << "Name: ``#{user.distinct}``" if opts.try_keys(:un, :usr)
    output << "Created: `#{user.creation_time}`" if opts.try_keys(:ct, :usr)

    if opts.try_keys(:av, :usr)
      large = opts[:big] ? '?size=1024' : ''
      output << "Avatar: #{user.avatar_url}#{large}"
    end

    if user.is_a?(MijDiscord::Data::Member)
      member_opts = opts.try_keys(:nk, :jt, :rl, :mbr)

      output << ("—" * 15) if output.any? && member_opts
      output << "Joined: `#{user.joined_at}`" if opts.try_keys(:jt, :mbr)

      if opts.try_keys(:nk, :mbr)
        nickname = user.nickname || '<none>'
        output << "Nickname: ``#{nickname}``"
      end

      if opts.try_keys(:rl, :mbr)
        roles = user.roles
                .sort {|x,y| y.position <=> x.position }
                .take(UINFO_ROLES_MAX)
                .map {|x| "``#{x.name}``" }

        rest = user.roles.length - UINFO_ROLES_MAX
        roles << "#{rest} more…" if rest > 0

        output << "Roles: #{roles.join(', ')}"
      end
    end

    output.any? ? output.join("\n") : "\u{274C} No options specified"
  end

  ## CMD: status ##

  $bot.ext_add(:status, Selfbot::StatusHandler)

  _cmd.register(:status,
  arg_count: 1..2, arg_types: [:symbol, :yaml]) do |event, cmd, data|
    status = event.bot.ext(:status)

    case cmd
    when :get
      yml = status.load(raw: true)
      "```yml\n#{yml || 'null'}\n```"
    when :set, :aug
      next "\u{274C} No data provided" if data.nil?
      status.update(data, merge: cmd == :aug)
      status.submit!
    when :rem
      status.reset
      status.submit!
    else
      "\u{274C} Invalid option specified"
    end
  end

  ## CMD: pick ##

  _cmd.register(:pick,
  arg_count: 1..-1, arg_types: [:string]) do |event, *args|
    %(\u{1F3B2} The Computer™ has picked "#{args.shuffle.sample}")
  end

  ## CMD: reflink ##

  _cmd.register(:reflink,
  arg_count: 2..2, arg_types: [:channel, :time]) do |event, channel, time|
    snowflake = MijDiscord::Data::IDObject.synthesize(time)
    %(https://discordapp.com/channels/#{channel.id}/#{channel.id}/#{snowflake})
  end

  ## CMD: tag ##

  _cmd.register(:tag,
  arg_count: 1..-1, arg_types: [:string]) do |event, tag, *args|
    next "\u{274C} Tag name cannot be empty" if tag.empty?

    dbc = event.bot.ext(:dbc)
    result = dbc.query(TAG_FIND, [tag.downcase])
    if result.none?
      %(\u{274C} Tag "#{tag}" not found)
    else
      result.first['content']
    end
  end

  ## CMD: tag? ##

  _cmd.register(:"tag?",
  arg_count: 0..1, arg_types: [:iregexp]) do |event, filter|
    dbc = event.bot.ext(:dbc)
    result = dbc.query(TAG_LIST, [event.bot.profile.id])

    tags = result.map {|x| x['tag'] }
    tags.select! {|x| x =~ filter } if filter
    tags.sort!

    "```\n#{tags.join("\t")}\n```"
  end

  ## CMD: tag+ ##

  _cmd.register(:"tag+",
  arg_count: 2..2, arg_types: [:string]) do |event, tag, data|
    next "\u{274C} Tag name cannot be empty" if tag.empty?

    begin
      dbc = event.bot.ext(:dbc)
      dbc.query(TAG_ADD, [tag, event.bot.profile.id, data])
      %(\u{2705} Added tag "#{tag}")
    rescue PG::UniqueViolation
      %(\u{274C} Tag "#{tag}" already exists)
    end
  end

  ## CMD: tag= ##

  _cmd.register(:"tag=",
  arg_count: 2..2, arg_types: [:string]) do |event, tag, data|
    next "\u{274C} Tag name cannot be empty" if tag.empty?

    begin
      result = event.ext(:dbc).query(TAG_EDIT, [tag.downcase, data])
      if result.cmd_tuples > 0
        %(\u{2705} Updated tag "#{tag}")
      else
        %(\u{274C} Tag "#{tag}" not found)
      end
    end
  end

  ## CMD: tag- ##

  _cmd.register(:"tag-",
  arg_count: 1..1, arg_types: [:string]) do |event, tag|
    next "\u{274C} Tag name cannot be empty" if tag.empty?

    begin
      result = event.ext(:dbc).query(TAG_REMOVE, [tag.downcase, nil])
      if result.cmd_tuples > 0
        %(\u{2705} Removed tag "#{tag}")
      else
        %(\u{274C} Tag "#{tag}" not found)
      end
    end
  end

end
