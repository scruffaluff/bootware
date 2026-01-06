--- @sync entry

-- Yazi plugin to customize open keybindings.
--
-- Based on logic https://yazi-rs.github.io/docs/tips/#smart-enter.

local function entry()
    local path = cx.active.current.hovered
    if path and path.cha.is_dir then
        ya.emit("mgr:enter", {})
        ya.emit("mgr:quit", {})
    else
        ya.emit("mgr:open", { hovered = true })
    end
end

return { entry = entry }
