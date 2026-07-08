-- Generic utils for interfacing with Factorio.

local Fact = {}

-- Creates a ghost tool for the given entity prototype directly in the player's cursor.
function Fact.createGhostTool(player, entityProto)
  if not entityProto then return nil end

  local ok = pcall(function()
    player.cursor_ghost = entityProto.name
  end)
  if not ok then
    -- Can sometimes fail even if entityProto is valid for some reason. Ex: cargo wagon.
    player.print("Failed to create ghost item for " .. entityProto.name)
    player.clear_cursor()
    return nil
  end
  return player.cursor_stack
end

return Fact