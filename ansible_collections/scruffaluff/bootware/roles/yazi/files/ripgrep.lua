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

    args = {
        "--ansi",
        "--disabled"
        "--bind",
        "start:reload:rg --column --line-number --no-heading --smart-case --color always {q}",
        "--bind",
        "change:reload:sleep 0.1; rg --column --line-number --no-heading --color=always --smart-case {q} || true",
        "--delimiter",
        ":",
        "--preview",
        "bat --color always --highlight-line {2} {1}",
        "--preview-window",
        "up,60%,border-bottom,+{2}+3/3,~3",
    }

	local output, error = Command("fzf")
        :args(args)
        :cwd(cwd)
        :stdin(Command.INHERIT)
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
    local path = splitAndGetFirst(target, ":")
	if path ~= "" then
		ya.manager_emit(path:find("[/\\]$") and "cd" or "reveal", { path })
	end
end

return { entry = entry }
