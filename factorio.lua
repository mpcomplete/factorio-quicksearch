-- Generic utils for interfacing with Factorio.

local Fact = {}

-- Returns dimensions of the given BoundingBox.
function getBoxDims(box)
  local width = math.ceil(math.abs(box.left_top.x - box.right_bottom.x))
  local height = math.ceil(math.abs(box.left_top.y - box.right_bottom.y))
  return width, height
end

-- Creates a ghost tool for the given entity prototype directly in the player's cursor.
-- Uses Factorio 2.0's built-in ghost-in-cursor feature, so no temporary blueprint is needed.
function Fact.createGhostTool(player, entityProto)
  if not entityProto then return nil end

  local ok = pcall(function()
    -- Sets the entity ghost in the cursor; Factorio places it as a buildable ghost.
    player.cursor_ghost = entityProto.name
    -- Make the ghost a temporary cursor item so it is not stored in the inventory
    -- and returns to the previous cursor contents when cleared, matching the old
    -- temporary-blueprint behavior.
    -- player.cursor_stack_temporary = true
  end)
  if not ok then
    -- Can sometimes fail even if entityProto is valid for some reason. Ex: cargo wagon.
    player.print("cursor_ghost failed for " .. entityProto.name)
    player.clear_cursor()
    return nil
  end
  return player.cursor_stack
end

-- Destroys all instances of the above-mentioned ghost tool blueprint from the player's inventory.
function Fact.destroyGhostTool(player)
  -- local inv = player.get_main_inventory()
  -- for i = 1,#inv do
  --   if inv[i].valid_for_read and inv[i].type == "blueprint" and inv[i].label == "Quicksearch Ghost" then
  --     debug(player, "Zapping ghost")
  --     inv[i].clear()
  --   end
  -- end
end

return Fact