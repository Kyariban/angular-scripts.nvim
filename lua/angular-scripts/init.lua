local pickers = require("telescope.pickers")
local config = require("telescope.config").values
local finders = require("telescope.finders")
local actions = require("telescope.actions")
local actions_state = require("telescope.actions.state")
local Path = require("plenary.path")

local log = require("plenary.log"):new()
log.level = "debug"

local function run_script_in_new_window(script)
	vim.cmd("botright new | term yarn run " .. script)
	vim.cmd("startinsert")
end

-- Define the main module
local M = {}

M.run_angular_scripts = function(opts)
	-- Find the package.json file
	local package_json = Path:new(vim.fn.getcwd(), "package.json")
	if not package_json:exists() then
		vim.api.nvim_err_writeln("Can't find the package.json file")
		return
	end

	-- Reading the package.json file
	local ok, json = pcall(vim.fn.readfile, package_json.filename)
	if not ok then
		vim.api.nvim_err_writeln("Can't read the package.json file")
		return
	end

	-- Get it as Json
	local package_data = vim.fn.json_decode(table.concat(json, "\n"))
	local scripts = package_data.scripts

	if not scripts then
		vim.api.nvim_err_writeln("Can't find any scripts in the package.json file")
		return
	end

	local script_names = {}
	for name, _ in pairs(scripts) do
		table.insert(script_names, name)
	end

	-- Display telescope
	pickers
		.new(opts, {
			prompt_title = "Angular Scripts",
			finder = finders.new_table(script_names),
			sorter = config.generic_sorter(opts),
			attach_mappings = function(prompt_bufnr)
				actions.select_default:replace(function()
					local selection = actions_state.get_selected_entry()
					actions.close(prompt_bufnr)
					run_script_in_new_window(selection.value)
				end)
				return true
			end,
		})
		:find()
end

return M
