local M = {}

--- Use empty function to save a bit of memory
local EMPTY_FUNCTION = function(_, message, context) end
local LUA_REQUIRE_AS_STRING = sys.get_config_int("saver.lua_require_as_string", 0) == 1

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
	trace = EMPTY_FUNCTION,
	debug = EMPTY_FUNCTION,
	info = EMPTY_FUNCTION,
	warn = EMPTY_FUNCTION,
	error = function(_, message, context)
		pprint(message, context)
	end,
}

---Contains the current game state data
---@type saver.game_state
M.GAME_STATE = nil

-- Persistent storage for saver table
M.state = nil

function M.reset_state()
	M.state = {
		storage = {},
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


---Encode the data to JSON.
---Overwrite this function if you want to use another JSON library
---@param data table The data to encode
---@return string The JSON encoded string
function M.json_encode(data)
	return json.encode(data)
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
---@return table|string|nil result The loaded data, or nil if the file can't be loaded
function M.load_file_by_path(filepath)
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
			if LUA_REQUIRE_AS_STRING then
				-- Replace all require("some.path") to "/some/path.lua"
				file_data = file_data:gsub('require%("([^"]+)"%)', function(path)
					return string.format('"/%s"', path:gsub("%.", "/") .. ".lua")
				end)
			end

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
			M.logger:debug("The file is not exists", filepath)
			return nil
		end

		return sys.load(filepath)
	end
end


---Remove file by path
---@param filepath string The file path
---@return boolean true if the file was removed successfully, false otherwise
function M.delete_file_by_path(filepath)
	if html5 then
		M.delete_html5(filepath)
	end

	return os.remove(filepath)
end


---Save the data in save directory
---@param data table The save data table
---@param filepath string The save file path in save directory
---@return boolean true if the file was saved successfully, false otherwise
function M.save_file_by_path(data, filepath)
	-- If the game is running in HTML5, then save the data to the local storage
	if html5 then
		return M.save_html5(data, filepath)
	end

	if filepath:sub(-5) == ".json" then
		local file = io.open(filepath, "w+")

		if file then
			file:write(M.json_encode(data))
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


---Convert table to lua string with stable key ordering
---@param tbl table The table to convert
---@param indent string|nil The indentation string
---@param is_array boolean|nil If the table is an array
---@return string The lua string
function M.table_to_lua_string(tbl, indent, is_array)
	indent = indent or ""
	local result = "{\n"

	-- Handle arrays first if it's an array table
	local array_part = {}
	local dict_part = {}

	-- Split numeric and string keys
	for k, v in pairs(tbl) do
		if type(k) == "number" and k > 0 and k <= #tbl then
			array_part[k] = v
		else
			dict_part[k] = v
		end
	end

	-- Process array part first to maintain order
	if is_array or #array_part > 0 then
		for i = 1, #array_part do
			local v = array_part[i]
			result = result .. indent .. "    "

			-- Add value based on its type
			if type(v) == "table" then
				-- Check if nested table is array-like
				local v_is_array = #v > 0
				result = result .. M.table_to_lua_string(v, indent .. "    ", v_is_array)
			elseif type(v) == "string" then
				result = result .. string.format("%q", v)
			else
				result = result .. tostring(v)
			end
			result = result .. ",\n"
		end
	end

	-- Get and sort dictionary keys
	local sorted_keys = {}
	for k in pairs(dict_part) do
		table.insert(sorted_keys, k)
	end
	table.sort(sorted_keys, function(a, b)
		-- Convert to strings for comparison
		return tostring(a) < tostring(b)
	end)

	-- Process dictionary part with sorted keys
	for _, k in ipairs(sorted_keys) do
		local v = dict_part[k]
		result = result .. indent .. "    "

		-- Format key
		if type(k) == "string" then
			-- Check if key needs to be quoted
			if k:match("[^%w_]") then
				result = result .. "[" .. string.format("%q", k) .. "]"
			else
				result = result .. k
			end
		else
			result = result .. "[" .. tostring(k) .. "]"
		end
		result = result .. " = "

		-- Format value
		if type(v) == "table" then
			local v_is_array = #v > 0
			result = result .. M.table_to_lua_string(v, indent .. "    ", v_is_array)
		elseif type(v) == "string" then
			local is_require = LUA_REQUIRE_AS_STRING and v:sub(-1) == ')' and v:sub(1, 8) == 'require('
			if is_require then
				result = result .. v
			else
				result = result .. string.format("%q", v)
			end
		else
			result = result .. tostring(v)
		end
		result = result .. ",\n"
	end

	result = result .. indent .. "}"
	return result
end

local GET_LOCAL_STORAGE = [[
(function() {
	try {
		return window.localStorage.getItem('%s') || '';
	} catch(e) {
		return '';
	}
}) ()
]]

---Load the data from the local storage in HTML5
---@param path string The path to the data in the local storage
---@return table|nil The loaded data
function M.load_html5(path)
	local web_data = html5.run(string.format(GET_LOCAL_STORAGE, path))
	if not web_data or web_data == "" then
		return nil
	end

	local decoded = defold_saver.decode_base64(web_data)
	local is_ok, lua_data = pcall(sys.deserialize, decoded)

	if not is_ok then
		M.logger:error("Can't parse the data from local storage", lua_data)
		return nil
	end

	return lua_data
end


local SET_LOCAL_STORAGE = [[
(function() {
	try {
		window.localStorage.setItem('%s', '%s');
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
	local encoded_data = defold_saver.encode_base64(sys.serialize(data))

	local html_command = string.format(SET_LOCAL_STORAGE, path, encoded_data)
	local is_save_successful = html5.run(html_command)
	return (not not is_save_successful)
end


local REMOVE_LOCAL_STORAGE = [[
(function() {
	try {
		window.localStorage.removeItem('%s');
		return true;
	} catch(e) {
		return false;
	}
})()
]]

---Remove the data from the local storage in HTML5
---@param path string The path to the data in the local storage
---@return boolean true if the data was removed successfully, false otherwise
function M.delete_html5(path)
	local is_delete_successful = html5.run(string.format(REMOVE_LOCAL_STORAGE, path))
	return (not not is_delete_successful)
end


return M
