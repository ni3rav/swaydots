--!nonstrict
-- Music glyph, visible only while a player is playing or paused.

local STREAM = "playerctl --follow metadata --format '{{status}}\t{{artist}} - {{title}}' 2>/dev/null"

barWidget.setGlyph("music")
barWidget.setText("")
barWidget.setVisible(false)

noctalia.runStream(STREAM, function(line)
  local status, track = string.match(line, "^(%a*)\t(.*)$")
  local active = status == "Playing" or status == "Paused"
  barWidget.setVisible(active)
  if active then
    barWidget.setTooltip(track)
  end
end)
