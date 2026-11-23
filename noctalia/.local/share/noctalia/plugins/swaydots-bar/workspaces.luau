--!nonstrict
-- Sway destroys empty workspaces, so 1..PINNED are synthesised when IPC doesn't report them.

local PINNED = 6
local FONT = "JetBrainsMono NF"

local STREAM = "swaymsg -t get_workspaces -r | tr -d '\\n'; echo; "
  .. "swaymsg -t subscribe -m '[\"workspace\",\"window\"]' | while read -r _; do "
  .. "swaymsg -t get_workspaces -r | tr -d '\\n'; echo; done"

local function isPinned(ws)
  return type(ws.num) == "number" and ws.num >= 1 and ws.num <= PINNED
end

local function collect(raw)
  local byNum = {}
  local extras = {}
  for _, ws in ipairs(raw) do
    local entry = {
      num = ws.num,
      name = ws.name,
      focused = ws.focused == true,
      urgent = ws.urgent == true,
      occupied = type(ws.representation) == "string" and ws.representation ~= "",
    }
    if isPinned(entry) then
      byNum[entry.num] = entry
    else
      table.insert(extras, entry)
    end
  end
  local list = {}
  for n = 1, PINNED do
    table.insert(list, byNum[n] or { num = n, name = tostring(n), focused = false, urgent = false, occupied = false })
  end
  for _, e in ipairs(extras) do
    table.insert(list, e)
  end
  return list
end

local function colorFor(ws)
  if ws.urgent then
    return "error"
  elseif ws.focused then
    return "primary"
  elseif ws.occupied then
    return "on_surface"
  end
  return "on_surface/0.4"
end

local function render(list)
  local items = {}
  for _, ws in ipairs(list) do
    local numbered = type(ws.num) == "number" and ws.num >= 0
    local target = numbered and { "swaymsg", "workspace", "number", tostring(ws.num) } or { "swaymsg", "workspace", ws.name }
    table.insert(
      items,
      ui.row({
        key = "ws-" .. ws.name,
        paddingH = 5,
        onClick = function()
          noctalia.runAsync(target)
        end,
      }, {
        ui.label({
          text = numbered and tostring(ws.num) or ws.name,
          color = colorFor(ws),
          fontFamily = FONT,
          fontWeight = ws.focused and 700 or 500,
        }),
      })
    )
  end
  barWidget.render(ui.row({ gap = 0, align = "center" }, items))
end

render(collect({}))

noctalia.runStream(STREAM, function(line)
  if line == "" then
    return
  end
  local ok, raw = pcall(noctalia.json.decode, line)
  if ok and type(raw) == "table" then
    render(collect(raw))
  end
end)
