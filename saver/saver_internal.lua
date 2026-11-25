local M = {}

--- Use empty function to save a bit of memory
local EMPTY_FUNCTION = function(_, message, context) end

--- Sort keys of different types in a stable order
local function compare_keys_as_strings(a, b)
	return tostring(a) < tostring(b)
end

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

M.LUA_REQUIRE_AS_STRING = sys.get_config_int("saver.lua_require_as_string", 0) == 1

-- Persistent storage for saver table
M.state = nil

--- File format constants
M.FORMAT = {
	JSON = "json",
	LUA = "lua",
	SERIALIZED = "serialized", -- For Lua tables (with userdata) saved using sys.save/sys.load
}

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
---@return string? The JSON encoded string
function M.json_encode(data)
	local encoded_data = json.encode(data)
	if encoded_data then
		return encoded_data
	end

	M.logger:error("Failed to encode the data to JSON", data)
	return nil
end


---@param version string The version string in format "major.minor.patch" or "major.minor" or "major"
---@return number
function M.parse_game_version(version)
	local sMajor, sMinor, sPatch, sPrereleaseAndBuild = version:match("^(%d+)%.?(%d*)%.?(%d*)(.-)$")
	assert(type(sMajor) == 'string', ("Could not extract version number(s) from %q"):format(version))

	local major, minor, patch = tonumber(sMajor), tonumber(sMinor), tonumber(sPatch)
	return major * 10000 + (minor or 0) * 100 + (patch or 0)
end


---Detect file format based on file path and content type
---@param filepath string The file path
---@return string format The file format (json, lua, serialized)
function M.detect_format(filepath)
	if filepath:sub(-5) == ".json" then
		return M.FORMAT.JSON
	elseif filepath:sub(-4) == ".lua" then
		return M.FORMAT.LUA
	else
		return M.FORMAT.SERIALIZED
	end
end


---Save data in JSON format
---@param data table The data to save
---@param filepath string The file path
---@return boolean success Whether the save was successful
function M.save_json(data, filepath)
	-- Encode before the file open: a failed encode keeps the previous file
	local is_encoded, encoded_data = pcall(M.json_encode, data)
	if not is_encoded or not encoded_data then
		M.logger:error("Can't encode the data to JSON", { filepath = filepath, error = encoded_data })
		return false
	end

	return M.write_file(encoded_data, filepath)
end


---Load data in JSON format
---@param filepath string The file path
---@return table|nil data The loaded data or nil if failed
function M.load_json(filepath)
	local file = io.open(filepath)
	if not file then
		M.logger:debug("JSON file does not exist", filepath)
		return nil
	end

	local file_data = file:read("*all")
	file:close()

	if not file_data then
		M.logger:error("Empty JSON file", filepath)
		return nil
	end

	local is_ok, result_or_error = pcall(json.decode, file_data)
	if not is_ok then
		M.logger:error("Can't parse the JSON file", result_or_error)
		return nil
	end

	return result_or_error
end


---Save data in Lua format
---@param data table The data to save
---@param filepath string The file path
---@return boolean success Whether the save was successful
function M.save_lua(data, filepath)
	return M.write_file("return " .. M.table_to_lua_string(data), filepath)
end


---Load data in Lua format
---@param filepath string The file path
---@return table|nil data The loaded data or nil if failed
function M.load_lua(filepath)
	local file = io.open(filepath)
	if not file then
		M.logger:debug("Lua file does not exist", filepath)
		return nil
	end

	local file_data = file:read("*all")
	file:close()

	if not file_data then
		M.logger:error("Empty Lua file", filepath)
		return nil
	end

	if M.LUA_REQUIRE_AS_STRING then
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

	return nil
end


---Save data in serialized format (for Lua tables with userdata)
---@param data table The data to save
---@param filepath string The file path
---@return boolean success Whether the save was successful
function M.save_serialized(data, filepath)
	local success, result = pcall(sys.save, filepath, data)
	if not success then
		M.logger:error("Failed to save serialized file", { filepath = filepath, error = result })
		return false
	end
	return result
end


---Load data in serialized format (for Lua tables with userdata)
---@param filepath string The file path
---@return table|nil data The loaded data or nil if failed
function M.load_serialized(filepath)
	if not sys.exists(filepath) then
		M.logger:debug("Serialized file does not exist", filepath)
		return nil
	end

	local success, result = pcall(sys.load, filepath)
	if not success then
		M.logger:error("Failed to load serialized file", { filepath = filepath, error = result })
		return nil
	end
	return result
end


---Save raw binary data
---@param data string The binary data to save
---@param filepath string The file path
---@return boolean success Whether the save was successful
function M.save_binary(data, filepath)
	return M.write_file(data, filepath)
end


---Write the string to the file. Fails if the file can't be opened, written or closed (no free space for example)
---@param data string The data to write
---@param filepath string The file path
---@return boolean success Whether the file was written
function M.write_file(data, filepath)
	local file = io.open(filepath, "wb")
	if not file then
		M.logger:error("Can't open file for writing", filepath)
		return false
	end

	local is_written, write_error = file:write(data)
	local is_closed, close_error = file:close()
	if not is_written or not is_closed then
		M.logger:error("Can't write the file", { filepath = filepath, error = write_error or close_error })
		return false
	end

	return true
end


---Load raw binary data
---@param filepath string The file path
---@return string|nil data The loaded data or nil if failed
function M.load_binary(filepath)
	local file = io.open(filepath, "rb")
	if not file then
		M.logger:debug("Binary file does not exist", filepath)
		return nil
	end

	local data = file:read("*all")
	file:close()
	return data
end


---Load the file from internal save directory
---@param filepath string The save file path in save directory
---@return table|nil result The loaded data, or nil if the file can't be loaded
function M.load_file_by_path(filepath)
	local format = M.detect_format(filepath)

	if format == M.FORMAT.JSON then
		return M.load_json(filepath)
	elseif format == M.FORMAT.LUA then
		return M.load_lua(filepath)
	elseif format == M.FORMAT.SERIALIZED then
		return M.load_serialized(filepath)
	end

	return nil
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


---Checks if the file exists at the specified path.
---@param filepath string The absolute path to the file to check. Contains the file name and extension.
---@return boolean is_exists true if the file exists, false otherwise
function M.is_file_exists_by_path(filepath)
	if html5 then
		return M.load_html5(filepath) ~= nil
	end

	local file = io.open(filepath)
	if not file then
		return false
	end

	file:close()
	return true
end


---Save the data in save directory
---@param data table|string The save data table or binary data
---@param filepath string The save file path in save directory
---@param format string|nil Explicit format override (json, lua, serialized, binary)
---@return boolean true if the file was saved successfully, false otherwise
function M.save_file_by_path(data, filepath, format)
	-- If the game is running in HTML5, then save the data to the local storage
	if html5 then
		return M.save_html5(data, filepath)
	end

	format = format or M.detect_format(filepath)

	if format == M.FORMAT.JSON then
		---@cast data table
		return M.save_json(data, filepath)
	elseif format == M.FORMAT.LUA then
		---@cast data table
		return M.save_lua(data, filepath)
	elseif format == M.FORMAT.SERIALIZED then
		---@cast data table
		return M.save_serialized(data, filepath)
	end

	M.logger:error("Unknown format for saving", format)
	return false
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
	local buffer = {}
	M.write_lua_table(buffer, tbl, indent or "", is_array)
	return table.concat(buffer)
end


---Append the table as lua string parts to the buffer. One concat at the end instead of a new string per value
---@param buffer string[] The parts of the lua string
---@param tbl table The table to convert
---@param indent string The indentation string
---@param is_array boolean|nil If the table is an array
function M.write_lua_table(buffer, tbl, indent, is_array)
	local item_indent = indent .. "    "
	buffer[#buffer + 1] = "{\n"

	-- Split numeric and string keys
	local array_part = {}
	local dict_part = {}
	local array_length = #tbl
	for k, v in pairs(tbl) do
		if type(k) == "number" and k > 0 and k <= array_length then
			array_part[k] = v
		else
			dict_part[k] = v
		end
	end

	-- Process array part first to maintain order
	for i = 1, #array_part do
		local v = array_part[i]
		buffer[#buffer + 1] = item_indent

		-- Add value based on its type
		if type(v) == "table" then
			-- Check if nested table is array-like
			M.write_lua_table(buffer, v, item_indent, #v > 0)
		elseif type(v) == "string" then
			buffer[#buffer + 1] = string.format("%q", v)
		else
			buffer[#buffer + 1] = tostring(v)
		end
		buffer[#buffer + 1] = ",\n"
	end

	-- Get and sort dictionary keys
	local sorted_keys = {}
	for k in pairs(dict_part) do
		table.insert(sorted_keys, k)
	end
	table.sort(sorted_keys, compare_keys_as_strings)

	-- Process dictionary part with sorted keys
	for index = 1, #sorted_keys do
		local k = sorted_keys[index]
		local v = dict_part[k]
		buffer[#buffer + 1] = item_indent

		-- Format key
		if type(k) == "string" then
			-- Check if key needs to be quoted
			if k:match("[^%w_]") then
				buffer[#buffer + 1] = "[" .. string.format("%q", k) .. "]"
			else
				buffer[#buffer + 1] = k
			end
		else
			buffer[#buffer + 1] = "[" .. tostring(k) .. "]"
		end
		buffer[#buffer + 1] = " = "

		-- Format value
		if type(v) == "table" then
			M.write_lua_table(buffer, v, item_indent, #v > 0)
		elseif type(v) == "string" then
			local is_require = M.LUA_REQUIRE_AS_STRING and v:sub(-1) == ')' and v:sub(1, 8) == 'require('
			if is_require then
				buffer[#buffer + 1] = v
			else
				buffer[#buffer + 1] = string.format("%q", v)
			end
		else
			buffer[#buffer + 1] = tostring(v)
		end
		buffer[#buffer + 1] = ",\n"
	end

	buffer[#buffer + 1] = indent .. "}"
end

--- html5.run returns the script result as a string: "true" or "false"
local HTML5_TRUE = "true"

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
---@param load_as_binary_data boolean|nil If true, then the data will be loaded as binary data
---@return table|nil data The loaded data
function M.load_html5(path, load_as_binary_data)
	local web_data = html5.run(string.format(GET_LOCAL_STORAGE, path))
	if not web_data or web_data == "" then
		M.logger:debug("No data in local storage", path)
		return nil
	end

	local decoded = defold_saver.decode_base64(web_data)

	if load_as_binary_data then
		return decoded
	end

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
---@param data table|string The data to save. If string it's a binary data
---@param path string The path to the data in the local storage
---@return boolean true if the data was saved successfully, false otherwise
function M.save_html5(data, path)
	if type(data) ~= "table" then
		-- For non-table data (like raw binary), we need to encode it to base64 first
		local encoded_data = defold_saver.encode_base64(data)
		local html_command = string.format(SET_LOCAL_STORAGE, path, encoded_data)
		return html5.run(html_command) == HTML5_TRUE
	end

	-- For tables, use the existing serialization
	local encoded_data = defold_saver.encode_base64(sys.serialize(data))
	local html_command = string.format(SET_LOCAL_STORAGE, path, encoded_data)
	return html5.run(html_command) == HTML5_TRUE
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
	return html5.run(string.format(REMOVE_LOCAL_STORAGE, path)) == HTML5_TRUE
end


return M
