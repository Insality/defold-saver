--- Defold Saver module
--- Call saver.init() to init module to load last used or default save
--- With migrations module use saver.set_migrations(...) before saver.init()
--- Use saver.bind_save_state("save_part_name", save_part_table) to load save part to save
--- Use saver.save_game_state() to save the game
--- You can set the game state a name to save it as different save
--- Use "saver.storage" to store key-value data in the persistent storage. Useful for various settings and misc data
--- Use "saver.migrations" to apply migrations to the save

local storage = require("saver.storage")
local migrations = require("saver.migrations")
local saver_internal = require("saver.saver_internal")

--- Take a default folder name as a project name without special characters
local PROJECT_NAME = sys.get_config_string("project.title"):gsub("[^%w_ ]", "")
local DIRECTORY_PATH = sys.get_config_string("saver.save_folder", PROJECT_NAME)
local SAVE_NAME = sys.get_config_string("saver.save_name", "game")
local SAVER_KEY = sys.get_config_string("saver.saver_key", "saver")
local STORAGE_KEY = sys.get_config_string("saver.storage_key", "storage")
local DEFAULT_AUTOSAVE_TIMER = sys.get_config_int("saver.autosave_timer", 3)

---Persist data between game sessions
---@class saver.state
---@field storage table<string, any>
---@field version number
---@field last_game_version string
---@field migration_version number

---Whole game state. Add your fields here to inspect all fields
---@class saver.game_state
---@field saver saver.state
---@field storage saver.storage.state

---Logger interface
---@class saver.logger
---@field trace fun(logger: saver.logger, message: string, data: any|nil)
---@field debug fun(logger: saver.logger, message: string, data: any|nil)
---@field info fun(logger: saver.logger, message: string, data: any|nil)
---@field warn fun(logger: saver.logger, message: string, data: any|nil)
---@field error fun(logger: saver.logger, message: string, data: any|nil)

---@class saver
local M = {}
M.autosave_timer_id = nil
M.autosave_timer_counter = 0
M.last_autosave_time = nil
M.before_save_callback = nil

---@param logger_instance saver.logger|table|nil
function M.set_logger(logger_instance)
	saver_internal.logger = logger_instance or saver_internal.empty_logger
end


---Initialize the saver. Should be called on the game start
---If you have the migrations, call migrations.set_migrations(...) before this
---Autosave will be scheduled if AUTOSAVE_TIMER > 0
---		saver.init()
function M.init()
	M.load_game_state()
	M.check_game_version()
	M.set_autosave_timer(DEFAULT_AUTOSAVE_TIMER)

	saver_internal.logger:info("Save loaded", M.get_game_state()[SAVER_KEY])
end


---Save the game
---		-- Save the game with default name
---		saver.save_game_state()
---		
---		-- Save the game with custom name
---		saver.save_game_state("custom_save")
---@param save_name string|nil The save name. If not passed, will use default from settings
---@return boolean true if the file was saved successfully, false otherwise
function M.save_game_state(save_name)
	if M.before_save_callback then
		M.before_save_callback()
	end

	save_name = save_name or SAVE_NAME
	local path = M.get_save_path(save_name)

	-- Increase version
	local game_state = M.get_game_state()
	local saver_state = game_state[SAVER_KEY]
	saver_state.version = saver_state.version + 1

	-- Save!
	local is_success = M.save_file_by_path(game_state, path)
	if is_success then
		saver_internal.logger:trace("Save game state to json", { save_name = save_name, path = path })
	else
		saver_internal.logger:error("Can't save the file to save directory", { save_name = save_name, path = path })
	end

	return is_success
end


---Load the game state from the file by name
---		-- Load the game state with default name
---		local is_loaded = saver.load_game_state()
---		
---		-- Load the game state with custom name
---		local is_loaded = saver.load_game_state("custom_save")
---@param save_name string|nil The save name. If not passed, will use default from settings
---@return boolean True if the game state is loaded, false if the new game state is created
function M.load_game_state(save_name)
	save_name = save_name or SAVE_NAME

	-- Load file
	local path = M.get_save_path(save_name)
	local game_state = M.load_file_by_path(path)
	local is_loaded = game_state ~= nil

	M.set_game_state(game_state or {})

	saver_internal.reset_state()
	-- Keep current migration version as default.
	-- It will be updated in bind_save_state to the actual if exists
	saver_internal.state.migration_version = migrations.get_count()
	-- Well it actually how we add the new table to the saver module
	M.bind_save_state(SAVER_KEY, saver_internal.state)

	storage.reset_state()
	M.bind_save_state(STORAGE_KEY, storage.state)

	if is_loaded then
		saver_internal.logger:info("Load game state", { save_name = save_name, path = path })
	else
		saver_internal.logger:info("New game state created", { save_name = save_name, path = path })
	end

	return is_loaded
end


---Delete the game state file. Doesn't affect the current game state
---If autosave is enabled, it will be rescheduled, so probably you want to immediately restart the game
---		-- Delete the game state with default name
---		saver.delete_game_state()
---		
---		-- Delete the game state with custom name
---		saver.delete_game_state("custom_save")
---@param save_name string|nil The save name. If not passed, will use default from settings
---@return boolean true if the file was deleted successfully, false otherwise
function M.delete_game_state(save_name)
	save_name = save_name or SAVE_NAME

	local path = M.get_save_path(save_name)
	local is_success = M.delete_file_by_path(path)

	if is_success then
		saver_internal.logger:info("Delete game state", { save_name = save_name, path = path })
	else
		saver_internal.logger:info("File not exists to remove", { save_name = save_name, path = path })
	end

	return is_success
end


---Get the save table
---		local game_state = saver.get_game_state()
---		pprint(game_state)
---@return saver.game_state The current game state
function M.get_game_state()
	return saver_internal.GAME_STATE
end


---Set the save table data
---		local game_state = saver.get_game_state()
---		game_state.game.level = 5
---		saver.set_game_state(game_state)
---@param data table The game state data to set
---@return boolean true if the game state was set successfully
function M.set_game_state(data)
	assert(data, "Can't set nil game state")
	saver_internal.GAME_STATE = data
	return true
end


---Load and override the table_reference. The reference on the table keeps the same
---		local game_state = {
---			level = 1,
---			money = 100
---		}
---		
---		saver.bind_save_state("game", game_state)
---		
---		-- If we have previously saved game state, the game_state will be changed to the saved data
---		print(game_state.level) -- 5 (if it was saved before)
---@param table_key_id string The save state id to save
---@param table_reference table The save state table
---@return table table_reference The table_reference
function M.bind_save_state(table_key_id, table_reference)
	local save_table = M.get_game_state()
	assert(save_table, "Add save part should be called after init")

	-- Add the save part if it doesn't exist
	if not save_table[table_key_id] then
		save_table[table_key_id] = table_reference
		return table_reference
	end

	-- Override the save part if it exists
	-- Values from previous save part will be copied to the new save part
	local user_table_data = save_table[table_key_id]
	save_table[table_key_id] = table_reference

	saver_internal.override(user_table_data, table_reference)

	return table_reference
end


---Save the data to the file
---		local data = {
---			score = 100,
---			level = 1
---		}
---		
---		-- Get project path works on build from the Defold Editor only
---		local project_path = saver.get_current_game_project_folder()
---		-- Use path to the resources folder
---		local file_path = saver.get_save_path(project_path .. "/resources/data.json")
---		saver.save_file_by_path(data, file_path)
---@param data table|string The save data table or string if the data is already encoded (or binary)
---@param path string The save file path
---@return boolean true if the file was saved successfully, false otherwise
function M.save_file_by_path(data, path)
	return saver_internal.save_file_by_path(data, path)
end


---Load the data from the file
---		-- Get project path works on build from the Defold Editor only
---		local project_path = saver.get_current_game_project_folder()
---		-- Use path to the resources folder
---		local file_path = saver.get_save_path(project_path .. "/resources/data.json")
---		local data = saver.load_file_by_path(file_path)
---		pprint(data)
---@param path string The file path
---@return table|string|nil The loaded data, or nil if the file can't be loaded
function M.load_file_by_path(path)
	return saver_internal.load_file_by_path(path)
end


---Delete the file
---@param path string
---@return boolean
function M.delete_file_by_path(path)
	return saver_internal.delete_file_by_path(path)
end


---Save the data to the file by name
---		local data = {
---			score = 100,
---			level = 1
---		}
---		
---		-- Save the data to the game save folder
---		saver.save_file_by_name(data, "data.json")
---@param data table|string
---@param filename string
function M.save_file_by_name(data, filename)
	return M.save_file_by_path(data, M.get_save_path(filename))
end


---Load the data from the file by name
---		local data = saver.load_file_by_name("data.json")
---		pprint(data)
---@param filename string
---@return table|string|nil
function M.load_file_by_name(filename)
	return M.load_file_by_path(M.get_save_path(filename))
end


---Delete the file by name
---		saver.delete_file_by_name("data.json")
---@param filename string
---@return boolean
function M.delete_file_by_name(filename)
	return M.delete_file_by_path(M.get_save_path(filename))
end


---This function returns the absolute path to the game save folder. If a file name is provided, the path to the file in the game save folder is returned. Filename supports subfolders.
---		local file_path = saver.get_save_path("data.json")
---		print(file_path) -- "/Users/user/Library/Application Support/Defold Saver/data.json"
---		
---		local file_path_2 = saver.get_save_path("profiles/profile1.json")
---		print(file_path_2) -- "/Users/user/Library/Application Support/Defold Saver/profiles/profile1.json"
---@param filename string The name of the file to get the path for. Can contain subfolders.
---@return string The absolute path to the game save folder, or the path to the file in the game save folder if a file name is provided.
function M.get_save_path(filename)
	assert(filename, "Can't get save path without filename")

	-- If filename contains "/" extract subfolder to the dir_name
	local directory_path = DIRECTORY_PATH
	if filename:find("/") then
		local splitted = saver_internal.split(filename, "/")
		filename = splitted[#splitted]
		directory_path = directory_path .. "/" .. table.concat(splitted, "/", 1, #splitted - 1)
	end

	return sys.get_save_file(directory_path, filename)
end


---Return current save version. Useful for check which save data is newer
---		local save_version = saver.get_save_version()
---		print(save_version)
---@return number The current save version
function M.get_save_version()
	return M.get_game_state()[SAVER_KEY].version
end


---Set the autosave timer
---		saver.set_autosave_timer(5) -- Autosave every 5 seconds
---		saver.set_autosave_timer(0) -- Disable autosave
---@param timer number The timer in seconds, 0 to disable
function M.set_autosave_timer(timer)
	AUTOSAVE_TIMER = timer
	M.schedule_autosave()
end


---@private
---Autosave timer callback
function M.on_autosave_timer()
	if M.autosave_timer_counter <= 0 then
		return
	end

	local current_time = socket.gettime()
	local dt = current_time - M.last_autosave_time
	M.autosave_timer_counter = M.autosave_timer_counter - dt
	M.last_autosave_time = current_time

	if M.autosave_timer_counter <= 0 then
		M.save_game_state()
		M.autosave_timer_counter = AUTOSAVE_TIMER
	end
end


---@private
---Schedule autosave
function M.schedule_autosave()
	if M.autosave_timer_id then
		timer.cancel(M.autosave_timer_id)
		M.autosave_timer_id = nil
	end

	if AUTOSAVE_TIMER > 0 then
		M.autosave_timer_id = timer.delay(1, true, M.on_autosave_timer)
		M.autosave_timer_counter = AUTOSAVE_TIMER
		M.last_autosave_time = socket.gettime()
	end
end


---@private
function M.check_game_version()
	local saver_state = M.get_game_state()[SAVER_KEY]

	local last_version = saver_state.last_game_version
	local current_version = sys.get_config_string("project.version")

	if last_version ~= "" and (saver_internal.parse_game_version(current_version) < saver_internal.parse_game_version(last_version)) then
		saver_internal.logger:error("Downgrading game version", { previous = last_version, current = current_version })
	end

	saver_state.last_game_version = current_version
end


---Get current folder with Defold project (only desktop)
---		local project_folder = saver.get_current_game_project_folder()
---		print(project_folder) -- "/Users/user/projects/my_game"
---@return string|nil Current project folder or nil if can't get it
function M.get_current_game_project_folder()
	if not io.popen or html5 then
		return nil
	end

	local file = io.popen("pwd")
	if not file then
		return nil
	end

	local pwd = file:read("*l")
	file:close()

	if not pwd then
		return nil
	end

	-- Check the game.project file exists in this folder
	local game_project_path = pwd .. "/game.project"
	local game_project_file = io.open(game_project_path, "r")
	if not game_project_file then
		return nil
	end

	game_project_file:close()
	return pwd
end


---Set the migrations table
---Set before saver.init() call
---		local migrations = {
---			function(game_state, logger)
---				-- Assume we have new level_data field in the game state and we need to move level and score to it
---				game_state.game.level_data = {
---					level = game_state.game.level,
---					score = game_state.game.score
---				}
---				game_state.game.level = nil
---				game_state.game.score = nil
---				return game_state
---			},
---			function(game_state, logger)
---				-- Just an example, multiply the score by 1000. For example we changed our score system
---				game_state.game.level_data.score = game_state.game.level_data.score * 1000
---				return game_state
---			}
---		}
---		
---		saver.set_migrations(migrations)
---		saver.init()
---		saver.bind_save_state("game", game_state)
---		saver.apply_migrations()
---@param migrations_table (fun(game_state: saver.game_state, logger: saver.logger): nil)[] Array of migration functions
function M.set_migrations(migrations_table)
	migrations.set_migrations(migrations_table)
end


---Migrations should be already applied before saver.load call
---with saver.set_migrations(...)
---		saver.apply_migrations()
function M.apply_migrations()
	local game_state = M.get_game_state()
	local saver_state = game_state[SAVER_KEY]

	local current_version = saver_state.migration_version
	local migrations_count = migrations.get_count()

	while current_version < migrations_count do
		current_version = current_version + 1
		migrations.apply(current_version, M.get_game_state(), saver_internal.logger)
	end

	saver_state.migration_version = migrations_count
end


---Get the value from the saver storage. If the value is not exists, it will return the default value.
---@generic T
---@param key_id string The storage field name
---@param default_value T? The default value
---@return T
function M.get_value(key_id, default_value)
	local value = M.get_game_state()[SAVER_KEY].storage[key_id]
	if value == nil then
		return default_value
	end

	return value
end


---Set the value from the saver storage.
---@param key_id string The storage field name
---@param value any value
function M.set_value(key_id, value)
	M.get_game_state()[SAVER_KEY].storage[key_id] = value
end


return M
