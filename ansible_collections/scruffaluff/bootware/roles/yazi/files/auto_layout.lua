-- Yazi plugin to adjust the number of Yazi panes based on terminal width.
--
-- Forked to only search for directories from
-- https://github.com/Yazelix/auto-layout.yazi/blob/main/main.lua.

local module = {}
local original = nil
local overridden = false

local function layout_ratios()
  if rt and rt.mgr and rt.mgr.ratio then
    return rt.mgr.ratio, false
  end
  return { 2, 3, 4 }, true
end

local function override_layout(self)
  if
    not self._area
    or not self._area.w
    or not ui
    or not ui.Constraint
    or not ui.Layout
  then
    original(self)
    return
  end

  local width = self._area.w
  local ratios = layout_ratios()
  local all = ratios[1] + ratios[2] + ratios[3]

  local constraints
  if width > 100 then
    constraints = {
      ui.Constraint.Ratio(ratios[1], all),
      ui.Constraint.Ratio(ratios[2], all),
      ui.Constraint.Ratio(ratios[3], all),
    }
  elseif width > 50 then
    constraints = {
      ui.Constraint.Ratio(0, all),
      ui.Constraint.Ratio(ratios[1] + ratios[2], all),
      ui.Constraint.Ratio(ratios[1] + ratios[3], all),
    }
  else
    constraints = {
      ui.Constraint.Ratio(0, all),
      ui.Constraint.Ratio(all, all),
      ui.Constraint.Ratio(0, all),
    }
  end

  self._chunks = ui.Layout()
    :direction(ui.Layout.HORIZONTAL)
    :constraints(constraints)
    :split(self._area)
end

function module:setup()
  if overridden or not Tab then
    return
  end

  if not original then
    original = Tab.layout
    if not original then
      original = function() end
    end
  end

  Tab.layout = override_layout
  overridden = true
end

return module
