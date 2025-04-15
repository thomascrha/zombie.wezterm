local wezterm = require("wezterm") --[[@as Wezterm]] --- this type cast invokes the LSP module for Wezterm

local M = {}

-- ~/.local/state/wezterm/zombie/[WORKSPACE_NAME]/state.json
-- Json state file structure
-- {
--  "version": 1,
--  "name": "workspace_name",
--  "tabs": [
--    {
--      "id": 1,
--      "active_pane_id": 1,
--      "panes": [
--        {
--          "id": 1,
--    }
--
--  }

M.save_workspace = function()
  local success, err = pcall(function()
    -- Get the current workspace name
    local mux = wezterm.mux
    local workspace = mux.get_active_workspace()

    -- Create the directory structure if it doesn't exist
    local home = os.getenv("HOME")
    local state_dir = home .. "/.local/state/wezterm/zombie/" .. workspace
    os.execute("mkdir -p '" .. state_dir .. "'")

    local state_file = state_dir .. "/state.json"

    -- Get all windows in the current workspace
    local windows = mux.get_windows()

    -- Build the state object
    local state = {
      version = 1,
      name = workspace,
      tabs = {}
    }

    -- For each window, get its tabs and panes
    for _, window in ipairs(windows) do
      local tabs = window:tabs()
      for _, tab in ipairs(tabs) do
        local tab_info = {
          id = tab:tab_id(),
          active_pane_id = tab:active_pane():pane_id(),
          panes = {}
        }

        local panes = tab:panes()
        for _, pane in ipairs(panes) do
          table.insert(tab_info.panes, {
            id = pane:pane_id(),
            cwd = pane:get_current_working_dir(),
            command = pane:get_foreground_process_info()
          })
        end

        table.insert(state.tabs, tab_info)
      end
    end

    -- Convert to JSON and save to file
    local json = wezterm.json_encode(state)
    local file = io.open(state_file, "w")
    if file then
      file:write(json)
      file:close()
      wezterm.log_info("Workspace '" .. workspace .. "' saved to " .. state_file)
    else
      wezterm.log_error("Failed to open " .. state_file .. " for writing")
    end
  end)

  if not success then
    wezterm.log_error("Failed to save workspace: " .. tostring(err))
    print("Failed to save workspace: " .. tostring(err))
  else
    print("Workspace saved successfully")
  end
end

-- local function init()
--   print("Hello from Wezterm")
-- end
--
-- init()

return M
