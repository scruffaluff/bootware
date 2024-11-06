-- Yazi plugin for interactive ripgrep search.
--
-- Based on logic from https://github.com/lpnh/fg.yazi.

local cwd, entry

cwd = ya.sync(
function()
    return tostring(cx.active.current.cwd)
end
)

function entry()
	local folder = cwd()
    ya.hide()

	local output, error = Command("fzf")
        :cwd(cwd):stdin(Command.INHERIT)
        :stdout(Command.PIPED)
        :stderr(Command.INHERIT)
        :spawn()
        :wait_with_output()


	if not output or not output.status.success then
        local code = output and output.status.code or error
		return ya.notify({
            content = string.format("Failed with exit code %s", code),
            level = "error",
            timeout = 5.0,
            title = "Fzf",
        })
	end

	local target = output.stdout:gsub("\n$", "")
	if target ~= "" then
		ya.manager_emit(target:find("[/\\]$") and "cd" or "reveal", { target })
	end
end

return { entry = entry }
