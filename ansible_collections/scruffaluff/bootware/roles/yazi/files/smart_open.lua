local function entry()
    local h = cx.active.current.hovered
    if h and h.cha.is_dir then
		ya.manager_emit("enter", {})
		ya.manager_emit("quit", {})
    else
		ya.manager_emit("open", { hovered = true })
    end
end

return { entry = entry }
