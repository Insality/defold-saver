local M = {}

--- Use empty function to save a bit of memory
local EMPTY_FUNCTION = function(_, message, context) end

---@type saver.logger
M.empty_logger = {
	trace = EMPTY_FUNCTION,
	debug = EMPTY_FUNCTION,
	info = EMPTY_FUNCTION,
	warn = EMPTY_FUNCTION,
	error = EMPTY_FUNCTION,
}

---@type saver.logger
M.logger = {
	trace = function(_, msg) print("TRACE: " .. msg) end,
	debug = function(_, msg, data) pprint("DEBUG: " .. msg, data) end,
	info = function(_, msg, data) pprint("INFO: " .. msg, data) end,
	warn = function(_, msg, data) pprint("WARN: " .. msg, data) end,
	error = function(_, msg, data) pprint("ERROR: " .. msg, data) end
}

---Contains the current game state data
---@type saver.game_state
M.GAME_STATE = nil

-- Persistent storage for saver table
M.state = nil

function M.reset_state()
	M.state = {
		version = 0,
		last_game_version = "",
		migration_version = 0,
	}
end
M.reset_state()


---Split string by separator
---@param s string
---@param sep string
function M.split(s, sep)
	sep = sep or "%s"
	local t = {}
	local i = 1
	for str in string.gmatch(s, "([^" .. sep .. "]+)") do
		t[i] = str
		i = i + 1
	end
	return t
end


---@param version string The version string in format "major.minor.patch" or "major.minor" or "major"
---@return number
function M.parse_game_version(version)
	local sMajor, sMinor, sPatch, sPrereleaseAndBuild = version:match("^(%d+)%.?(%d*)%.?(%d*)(.-)$")
	assert(type(sMajor) == 'string', ("Could not extract version number(s) from %q"):format(version))

	local major, minor, patch = tonumber(sMajor), tonumber(sMinor), tonumber(sPatch)
	return major * 10000 + (minor or 0) * 100 + (patch or 0)
end


---Load the file from internal save directory
---@param filepath string The save file path in save directory
---@return table|nil The loaded data, or nil if the file can't be loaded
function M.load_by_path(filepath)
	--- If the game is running in HTML5, then load the data from the local storage
	if html5 then
		return M.load_html5(filepath)
	end

	-- If the file ext is JSON, then load it as JSON
	if filepath:sub(-5) == ".json" then
		local file_data = nil
		local file = io.open(filepath)
		if file then
			file_data = file:read("*all")
			file:close()
		end

		if file_data then
			local is_ok, result_or_error = pcall(json.decode, file_data)
			if not is_ok then
				M.logger:error("Can't parse the JSON file", result_or_error)
				return nil
			end

			local parsed_data = result_or_error
			if parsed_data and type(parsed_data) == "table" then
				return parsed_data
			end
		end

		return nil
	elseif filepath:sub(-4) == ".lua" then
		local file_data = nil
		local file = io.open(filepath)
		if file then
			file_data = file:read("*all")
			file:close()
		end

		if file_data then
			local is_ok, result_or_error = pcall(load, file_data)
			if not is_ok then
				M.logger:error("Can't load the Lua file", result_or_error)
				return nil
			end

			if result_or_error then
				local parse_ok, parsed_data = pcall(result_or_error)
				if parse_ok and parsed_data and type(parsed_data) == "table" then
					return parsed_data
				else
					M.logger:error("Can't parse the Lua file", parsed_data)
					return nil
				end
			end
		end

		return nil
	else
		local is_exists = sys.exists(filepath)
		if not is_exists then
			M.logger:error("Can't load the file from save directory", filepath)
			return nil
		end

		return sys.load(filepath)
	end
end


---Save the data in save directory
---@param data table The save data table
---@param filepath string The save file path in save directory
---@return boolean true if the file was saved successfully, false otherwise
function M.save_to_path(data, filepath)
	-- If the game is running in HTML5, then save the data to the local storage
	if html5 then
		return M.save_html5(data, filepath)
	end

	if filepath:sub(-5) == ".json" then
		local file = io.open(filepath, "w+")

		if file then
			file:write(json.encode(data))
			file:close()
			return true
		else
			M.logger:error("Can't save the file to save directory", filepath)
			return false
		end
	elseif filepath:sub(-4) == ".lua" then
		local file = io.open(filepath, "w+")
		if file then
			local filedata = "return " .. M.table_to_lua_string(data)
			file:write(filedata)
			file:close()
			return true
		else
			M.logger:error("Can't save the file to save directory", filepath)
			return false
		end
	else
		-- In other cases, use sys.save as binary format
		return sys.save(filepath, data)
	end
end


---Override the target table with the source table values
---@param source table
---@param target table
function M.override(source, target)
	for key, value in pairs(source) do
		if type(value) == "table" and target[key] then
			M.override(value, target[key])
		else
			target[key] = value
		end
	end
end


---Convert table to lua string
---@param tbl table The table to convert
---@param indent string|nil The indentation string
---@param is_array boolean|nil If the table is an array
---@return string The lua string
function M.table_to_lua_string(tbl, indent, is_array)
	indent = indent or ""
	local result = "{\n"
	local i = 1

	for k, v in pairs(tbl) do
		-- Add indentation
		result = result .. indent .. "    "

		-- Add key if it's not an array index
		if not is_array or type(k) ~= "number" or k ~= i then
			if type(k) == "string" then
				-- Write string keys without [" "]
				result = result .. k
			else
				result = result .. "[" .. k .. "]"
			end
			result = result .. " = "
		end

		-- Add value based on its type
		if type(v) == "table" then
			-- Recursively handle nested tables
			-- Check if the table could be an array
			local v_is_array = type(next(v)) == "number"
			result = result .. M.table_to_lua_string(v, indent .. "    ", v_is_array)
		elseif type(v) == "string" then
			-- Add quotes around string values
			result = result .. string.format("%q", v)
		else
			-- Add other types directly
			result = result .. tostring(v)
		end

		result = result .. ",\n"
		i = i + 1
	end

	result = result .. indent .. "}"
	return result
end


local GET_LOCAL_STORAGE =  [[
(function() {
	try {
		return window.localStorage.getItem('%s') || '{}';
	} catch(e) {
		return '{}';
	}
}) ()
]]

---Load the data from the local storage in HTML5
---@param path string The path to the data in the local storage
---@return table|nil The loaded data
function M.load_html5(path)
	local web_data = html5.run(string.format(GET_LOCAL_STORAGE, path))
	if not web_data then
		return nil
	end

	return json.decode(web_data)
end


local SET_LOCAL_STORAGE =  [[
(function() {
	try {
		window.localStorage.setItem('%s','%s');
		return true;
	} catch(e) {
		return false;
	}
})()
]]

---Save the data to the local storage in HTML5
---@param data table The data to save
---@param path string The path to the data in the local storage
---@return boolean true if the data was saved successfully, false otherwise
function M.save_html5(data, path)
	local encoded_data = json.encode(data)
	encoded_data = string.gsub(encoded_data, "'", "\'")

	local is_save_successful = html5.run(string.format(SET_LOCAL_STORAGE, path, encoded_data))

	return (not not is_save_successful)
end


return M
