--- @sync entry

-- Yazi plugin to customized open keybindings.
--
-- Based on logic https://yazi-rs.github.io/docs/tips/#smart-enter.

local function entry()
    local path = cx.active.current.hovered
    if path and path.cha.is_dir then
		ya.manager_emit("enter", {})
		ya.manager_emit("quit", {})
    else
		ya.manager_emit("open", { hovered = true })
    end
end

return { entry = entry }
