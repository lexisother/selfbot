module Selfbot::Defs

  ## EV: presence ready ##

  $bot.add_event(:ready, :presence) do |event|
    event.bot.ext(:status)&.submit!(status: :dnd)
  end

  ## EV: _debug_ unhandled ##

  $bot.add_event(:unhandled, :_debug_) do |event|
    MijDiscord::LOGGER.info("Events") {"Unhandled <#{event.name} #{event.data.inspect}>"}
  end

  ## EV: logging create_message,edit_message,delete_message ##

  $bot.ext_add(:logdbc, Selfbot::Database, Selfbot::DBCOPTS)

  $bot.add_event(:create_message, :logging) do |event|
    next if event.message.content.empty?

    dbc = event.bot.ext(:logdbc)
    dbc.query(MSGLOG_NEW, [
      event.channel.id,
      event.message.id,
      event.author.id,
      event.message.timestamp,
      event.message.content,
    ])
  end

  $bot.add_event(:edit_message, :logging) do |event|
    dbc = event.bot.ext(:logdbc)
    dbc.query(MSGLOG_EDIT, [
      event.channel.id,
      event.message.id,
      event.message.edit_timestamp,
      event.message.content,
    ])
  end

  $bot.add_event(:delete_message, :logging) do |event|
    dbc = event.bot.ext(:logdbc)
    dbc.query(MSGLOG_DELETE, [
      event.channel.id,
      event.id,
    ])
  end

end
