local Fact = require("factorio")

local Recipe = {}

-- Helper to collect a list of recipes that match the query.
function Recipe.findMatches(player, matchFunc, showHidden)
  local matches = {}
  for name, recipe in pairs(player.force.recipes) do
    local itemProto = recipe.prototype.main_product and prototypes.item[recipe.prototype.main_product.name]
    local visible = (not recipe.hidden and recipe.enabled) or showHidden
    local canPlaceOrCraft = itemProto and itemProto.stackable
    if itemProto and not matches[itemProto.name] and visible and canPlaceOrCraft then
      local matchDist = matchFunc(player, itemProto.name)
      if matchDist then
        matches[itemProto.name] = {
          recipe = recipe,
          itemProto = itemProto,
          name = itemProto.name,
  --        number = player.get_craftable_count(recipe), -- too slow
          order = (isFavorite(player, name) and "[a]" or "[b]") .. (placeable and "[a]" or "[b]") .. string.format("%04d", matchDist) .. itemProto.order,
          sprite = "recipe/"..name,
          tooltip = {
            "",
            itemProto.localised_name,
            " (", itemProto.name, ")",
            "\nclick = pick up ghost of item",
            "\nctrl+click = craft single item",
            "\nshift+click = craft stack of item",
            "\nalt+click = toggle favorite",
            "\nctrl+alt+click = open in FNEI",
          },
          acceptFunc = Recipe.pick,
        }
      end
    end
  end
  return matches
end

-- Player chose a recipe.
function Recipe.pick(player, match, event)
  local itemProto = prototypes.item[match.recipe.prototype.main_product.name]
  local craft =
    (event.shift) and 100 or -- "100" means "a full stack"
    (event.control and event.button == defines.mouse_button_type.right) and 5 or
    (event.control) and 1 or
    0
  if craft == 0 then
    Fact.createGhostTool(player, itemProto)
    return
  end
  -- Craft the item.
  if (player.controller_type == defines.controllers.god or player.controller_type == defines.controllers.editor) then
    player.insert{count=craft == 100 and itemProto.stack_size or craft, name=itemProto.name}
  else
    if craft == 100 then
      local amount = match.recipe.prototype.main_product.amount or match.recipe.prototype.main_product.amount_min or 1
      craft = math.ceil(itemProto.stack_size / amount)
    end
    player.begin_crafting{count=craft, recipe=match.recipe}
  end
end

return Recipe