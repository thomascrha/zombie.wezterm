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
  print("Saving workspace...")
end

-- local function init()
--   print("Hello from Wezterm")
-- end
--
-- init()

return M
