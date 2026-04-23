-- Yazi plugin to search directories with Fzf.
--
-- Forked to only search for directories from
-- https://github.com/sxyazi/yazi/blob/main/yazi-plugin/preset/plugins/fzf.lua.

local module = {}
local state = ya.sync(function()
  return cx.active.current.cwd
end)

function module:entry()
  ya.emit("escape", { visual = true })
  local cwd = state()
  local permit = ui.hide()

  local output, error = module:run_fzf(cwd)
  permit:drop()
  if not output then
    return ya.notify { title = "Fzf", content = tostring(error), timeout = 5, level = "error" }
  end

  local folder = module:parse_folder(cwd, output)
  if fs.cha(folder) then
    ya.emit("mgr:cd", { folder, raw = true })
  end
end

function module:parse_folder(cwd, output)
  local folder = Url(output:match("[^\r\n]+") or "")
  if folder.is_absolute then
    return folder
  else
    return cwd:join(folder)
  end
end

function module:run_fzf(cwd)
  local process, error = Command("fzf")
      :arg("--height")
      :arg("~100")
      :cwd(tostring(cwd))
      :env("FZF_DEFAULT_COMMAND", "fd --hidden --no-require-git --type dir")
      :stdin(Command.INHERIT)
      :stdout(Command.PIPED)
      :spawn()

  if not process then
    return nil, Err("Failed to start fzf with error '%s'.", error)
  end

  local output, error = process:wait_with_output()
  if not output then
    return nil, Err("Failed to read fzf output with error: '%s'.", error)
  elseif not output.status.success and output.status.code ~= 130 then
    return nil, Err("Process fzf exited with code %s.", output.status.code)
  end
  return output.stdout, nil
end

return module
