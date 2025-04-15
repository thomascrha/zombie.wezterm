local wezterm = require("wezterm") --[[@as Wezterm]] --- this type cast invokes the LSP module for Wezterm

local M = {}

local is_windows = wezterm.target_triple:find("windows")
local separator = is_windows and "\\" or "/"

local utils = nil

M.bootstrap = true

local function init()
  print("Hello from Wezterm")
end

init()

return M
