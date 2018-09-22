$bot.add_event(:ready, :presence) do |event|
  event.bot.update_presence(game: Selfbot::CONFIG[:presence])
end

$bot.add_event(:unhandled, :_debug_) do |event|
  MijDiscord::LOGGER.info("Events") {"Unhandled <#{event.name} #{event.data.inspect}>"}
end