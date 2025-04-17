local wezterm = require("wezterm") --[[@as Wezterm]] --- this type cast invokes the LSP module for Wezterm

local M = {}

-- ~/.local/state/wezterm/zombie/[WORKSPACE_NAME].json

M.save_current_workspace = function()
  local active_workspace = wezterm.mux.get_active_workspace()

  if not active_workspace then
    wezterm.log_error("No active workspace found")
    return false
  end

  return M.save_workspace(active_workspace)
end

M.save_workspace = function(workspace_name)
  if not workspace_name then
    wezterm.log_error("No workspace name provided to save_workspace")
    return false
  end

  local home = os.getenv("HOME")
  local state_dir = home .. "/.local/state/wezterm/zombie"
  local state_file = state_dir .. "/" .. workspace_name .. ".json"
  os.execute("mkdir -p '" .. state_dir .. "'")

  local workspace_state = {
    version = 1,
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

-- Save all workspaces
M.save_workspaces = function()
  -- Get the list of workspace names
  local workspaces = wezterm.mux.get_workspace_names()
  local active_workspace = wezterm.mux.get_active_workspace()

  -- Save the active workspace first
  M.save_workspace(active_workspace)

  -- Then save all other workspaces
  for _, workspace_name in ipairs(workspaces) do
    if workspace_name ~= active_workspace then
      M.save_workspace(workspace_name)
    end
  end
end

return M
