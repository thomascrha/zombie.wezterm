local wezterm = require("wezterm") --[[@as Wezterm]] --- this type cast invokes the LSP module for Wezterm

local M = {}

-- Constants
local STATE_DIR = os.getenv("HOME") .. "/.local/state/wezterm/zombie"
local VERSION = 1
-- ~/.local/state/wezterm/zombie/[WORKSPACE_NAME].json


local path_exists = function(path)
  local f = io.open(path, "r")
  if f then
    f:close()
    return true
  else
    return false
  end
end

M.save_workspace = function(workspace_name)
  if not workspace_name then
    wezterm.log_error("No workspace name provided to save_workspace")
    return false
  end

  local state_file = STATE_DIR .. "/" .. workspace_name .. ".json"
  if not path_exists(state_file) then
    os.execute("mkdir -p '" .. STATE_DIR .. "'")
  end

  local workspace_state = {
    version = VERSION,
    name = workspace_name,
    tabs = {}
  }

  for _, window in ipairs(wezterm.mux.all_windows()) do
    if window and window:get_workspace() == workspace_name then
      local tabs = window:tabs()

      for _, tab in ipairs(tabs) do
        local active_pane = tab:active_pane()
        local tab_info = {
          id = tostring(tab.tab_id),
          active_pane_id = active_pane and tostring(active_pane:pane_id()) or nil,
          panes = {}
        }

        local panes = tab:panes()
        for _, pane in ipairs(panes) do
          local cwd = pane:get_current_working_dir()
          local cwd_path = cwd and cwd.path or nil

          local process_info = pane:get_foreground_process_info()
          local cmd = process_info and {
            name = process_info.name,
            args = process_info.args
          } or nil

          table.insert(tab_info.panes, {
            id = tostring(pane:pane_id()),
            cwd = cwd_path,
            command = cmd
          })
        end

        table.insert(workspace_state.tabs, tab_info)
      end
    end
  end

  local file = io.open(state_file, "w")
  if file then
    file:write(wezterm.json_encode(workspace_state))
    file:close()
    return true
  else
    wezterm.log_error("Failed to open file for writing: " .. state_file)
    return false
  end
end

M.restore_workspace = function (workspace_name)
  if not workspace_name then
    wezterm.log_error("No workspace name provided to restore_workspace")
    return false
  end

  local state_file = STATE_DIR .. "/" .. workspace_name .. ".json"
  if not path_exists(state_file) then
    wezterm.log_error("State file does not exist: " .. state_file)
    return false
  end

  local file = io.open(state_file, "r")
  if not file then
    wezterm.log_error("Failed to open file for reading: " .. state_file)
    return false
  end

  local content = file:read("*a")
  file:close()

  local workspace_state = wezterm.json_decode(content)

  if not workspace_state or workspace_state.version ~= VERSION then
    assert(workspace_state.version == VERSION, "Unsupported workspace state version: " .. workspace_state.version)
  end

  wezterm.mux.set_active_workspace(workspace_name)

  for _, tab_info in ipairs(workspace_state.tabs) do
    local tab = wezterm.mux.spawn_window({
      cwd = tab_info.panes[1].cwd,
      args = tab_info.panes[1].command and tab_info.panes[1].command.args or nil,
      name = tab_info.id,
      initial_rows = wezterm.gui.get_config().initial_rows,
      initial_cols = wezterm.gui.get_config().initial_cols,
    })

    for _, pane_info in ipairs(tab_info.panes) do
      tab:split_pane({
        direction = "Right",
        size = "50%",
        cwd = pane_info.cwd,
        args = pane_info.command and pane_info.command.args or nil,
      })
    end
  end

  return true
end

M.save_current_workspace = function()
  local active_workspace = wezterm.mux.get_active_workspace()

  if not active_workspace then
    wezterm.log_error("No active workspace found")
    return false
  end

  return M.save_workspace(active_workspace)
end

M.restore_current_workspace = function()
  local active_workspace = wezterm.mux.get_active_workspace()

  if not active_workspace then
    wezterm.log_error("No active workspace found")
    return false
  end

  return M.restore_workspace(active_workspace)
end

M.restore_workspaces = function()
  local workspaces = wezterm.mux.get_workspace_names()

  for _, workspace_name in ipairs(workspaces) do
    if workspace_name ~= wezterm.mux.get_active_workspace() then
      M.restore_workspace(workspace_name)
    end
  end

  M.restore_workspace(wezterm.mux.get_active_workspace())
end

M.save_workspaces = function()
  local workspaces = wezterm.mux.get_workspace_names()
  local active_workspace = wezterm.mux.get_active_workspace()

  M.save_workspace(active_workspace)

  for _, workspace_name in ipairs(workspaces) do
    if workspace_name ~= active_workspace then
      M.save_workspace(workspace_name)
    end
  end
end

return M
