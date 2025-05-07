local Global = {}

function Global.get(player)
  -- storage = storage or {}
  storage.perplayer = storage.perplayer or {}
  storage.perplayer[player.index] = storage.perplayer[player.index] or {}
  return storage.perplayer[player.index]
end

function Global.destroy(player_index)
  if storage and storage.perplayer then
    storage.perplayer[player_index] = nil
  end
end

script.on_event(defines.events.on_player_left_game, function(event)
  Global.destroy(event.player_index)
end)

return Global