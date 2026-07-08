-- Stuff to create/manage the GUI.

local Lib = require("lib")
local Global = require("global")
local Fact = require("factorio")
local Inventory = require("inventory")
local Recipe = require("recipe")
local Logistic = require("logistic")

local Gui = {}

function GUI(player)
  return player.gui.screen.quicksearch
end

function destroyGui(player)
  if GUI(player) ~= nil then GUI(player).destroy() end
  Global.get(player).gui = {}
end

function showGui(player)
  if Global.get(player).guiVersion ~= 2 then destroyGui(player) end
  Global.get(player).guiVersion = 2
  if GUI(player) == nil then buildGui(player) end
  GUI(player).visible = true
  GUI(player).inputarea["quicksearch.query"].text = ""
  GUI(player).inputarea["quicksearch.query"].focus()
  Global.get(player).gui = {}
  Gui.setQuery(player, "")
  Gui.refresh(player)
end

function hideGui(player)
  if GUI(player) ~= nil then GUI(player).visible = false end
end

function buildGui(player)
  if GUI(player) ~= nil then return end

  window = player.gui.screen.add{
    type = "frame",
    name = "quicksearch",
    direction = "vertical",
    style = "quicksearch-window-style",
    caption = "Quicksearch",
    vertical_scroll_policy = "never",
  }
  -- Row 1: input area
  do
    frame = window.add{
      type = "flow",
      name = "inputarea",
    }
    frame.add{
      type = "textfield",
      name = "quicksearch.query"
    }
    frame.add{
      type = "button",
      name = "quicksearch.close",
      caption = " X ",
      style = "quicksearch-button-style"
    }
  end
  -- Row 2: checkbox
  window.add{
    type = "checkbox",
    name = "quicksearch.toggle-hidden",
    caption = "Show hidden/unresearched recipes",
    style = "quicksearch-checkbox-style",
    state = Global.get(player).showHidden or false
  }
  -- Row 3: matches
  window.add{
    type = "flow",
    name = "matches",
    direction = "horizontal",
    style = "quicksearch-match-horizontal-flow-style",
  }
end

function Gui.open(player)
  showGui(player)
end

function Gui.close(player)
  hideGui(player)
end

function Gui.isOpen(player)
  return GUI(player) ~= nil and GUI(player).visible
end

function Gui.get(player)
  return GUI(player)
end

function Gui.global(player)
  local g = Global.get(player)
  g.gui = g.gui or {}
  return g.gui
end

function Gui.setQuery(player, query)
  -- Insert ".*" in between each letter for a fuzzy match. That way "etb" will match "express-transport-belt"
  Gui.global(player).queryLen = #query
  Gui.global(player).query = string.sub(string.gsub(string.lower(query), "(.)", "%1.*"), 1, -3) -- remove last .*
end

function Gui.matchQuery(player, text)
  local match = string.match(text, Gui.global(player).query or "")
  if match then
    local lendiff = #match - (Gui.global(player).queryLen or 0) -- better matches have a shorter length difference
    return lendiff
  end
  return false
end

function Gui.toggleHidden(player)
  Global.get(player).showHidden = not Global.get(player).showHidden
  Gui.refresh(player)
end

function Gui.refresh(player)
  if not player.gui.screen.quicksearch then return end
  debug(player, "Refreshing GUI.")

  local matchesFrame = player.gui.screen.quicksearch.matches
  Gui.matches = {}

  -- Add matching items from player's inventory.
  local matches = Inventory.findMatches(player, {player.get_main_inventory()}, Gui.matchQuery)
  local leftFlow = matchesFrame.left or matchesFrame.add{
    type = "flow",
    name = "left",
    direction = "vertical",
    style = "quicksearch-match-vertical-flow-style",
  }
  leftFlow.style.vertically_stretchable = true
  Gui.buildMatchGrid(player, leftFlow, "Inventory", "inventoryGrid", matches)

  -- Add matching recipes.
  local matches = Recipe.findMatches(player, Gui.matchQuery, Global.get(player).showHidden)
  Gui.buildMatchGrid(player, leftFlow, "Crafting", "crafting", matches)

  local rightFlow = matchesFrame.right or matchesFrame.add{
    type = "flow",
    name = "right",
    direction = "vertical",
    style = "quicksearch-match-vertical-flow-style",
  }
  rightFlow.style.vertically_stretchable = true

  -- Add matches from current chest.
  local matches = Inventory.findMatches(player, {Inventory.getForOpenContainer(player)}, Gui.matchQuery)
  local caption = next(matches) and player.opened.localised_name or ""
  Gui.buildMatchGrid(player, rightFlow, caption, "container", matches)

  -- Add matches from logistics networks.
  local matches = Logistic.findMatches(player, Gui.matchQuery)
  Gui.buildMatchGrid(player, rightFlow, "Logistics Networks", "logistic", matches)
end

function Gui.buildMatchGrid(player, parent, caption, name, matches)
  local frame = parent[name] or parent.add{
    type = "flow",
    name = name,
    direction = "vertical",
    style = "quicksearch-match-vertical-flow-style",
  }

  if next(matches) == nil then
    if frame.frame then
      frame.frame.destroy()
    end
    return
  end

  local frame = frame.frame or frame.add{
    type = "frame",
    caption = caption,
    name = "frame",
    style = "quicksearch-match-frame-style",
  }
  frame.style.horizontally_stretchable = true
  frame = frame.scrollpane or frame.add{
    type = "scroll-pane",
    name = "scrollpane",
    style = "quicksearch-match-scrollpane-style",
    horizontal_scroll_policy = "never",
  }
  frame.clear()
  local grid = frame.add{
    type = "table",
    name = "table",
    column_count = 10,
    style = "quicksearch-match-grid-style",
  }
  for name, match in Lib.spairs(matches, function(t, a, b) return t[a].order < t[b].order end) do
    g = grid.add{
      type = "sprite-button",
      name = string.format("quicksearch.match/%d", #Gui.matches + 1),
      tooltip = match.tooltip,
      number = match.number,
      sprite = match.sprite,
      style = isFavorite(player, match.name) and "quicksearch-match-item-favorite-style" or "quicksearch-match-item-style",
    }
    table.insert(Gui.matches, match)
  end
end

function Gui.acceptMatch(player, index, event)
  local match = Gui.matches[index]
  if match then
    if event.control and event.alt then
      local action_type = (event.button == defines.mouse_button_type.left) and "craft" or "usage"
      if not pcall(function() remote.call("fnei", "show_recipe_for_prot", action_type, match.itemProto.type, match.itemProto.name) end) then
        player.print("Cannot open FNEI")
      end
    elseif event.alt then
      Global.get(player).favorites = Global.get(player).favorites or {}
      Global.get(player).favorites[match.name] = not Global.get(player).favorites[match.name]
      debug(player, "Favorite match=%s: %s", match.name, isFavorite(player, match.name) and "yes" or "no")
    else
      debug(player, "Accepting match=%s", match.name)
      local ok = pcall(function()
        match.acceptFunc(player, match, event)
      end)
      if not ok then
        player.print("Unknown error occurred when processing quicksearch input.")
      end
    end
  end
end

function isFavorite(player, name)
  return Global.get(player).favorites and Global.get(player).favorites[name]
end

return Gui