-- Yazi plugin to change access permissions for files.
--
-- Based on logic from https://github.com/yazi-rs/plugins.

local entry, selected

local function entry()
    local paths = selected()
    if #paths == 0 then
        return
    end

    local value, event = ya.input({
        position = { "top-center", y = 2, w = 50 },
        title = "Chmod:",
    })
    if event ~= 1 then
        return
    end

    local status, error = Command("chmod"):arg(value):args(paths):spawn():wait()
    if not status or not status.success then
        local code = status and status.code or error
        ya.notify({
            content = string.format("Failed with exit code %s", code),
            level = "error",
            timeout = 5.0,
            title = "Chmod",
        })
    end
end

-- Get selected file paths or file path under focus.
selected = ya.sync(
function()
	local tab, paths = cx.active, {}
	for _, path in pairs(tab.selected) do
		paths[#paths + 1] = tostring(path)
	end
	if #paths == 0 and tab.current.hovered then
		paths[1] = tostring(tab.current.hovered.url)
	end
	return paths
end
)

return { entry = entry }
