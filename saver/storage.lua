--- Storage module
--- This module is used to store the key-value data in the persistent storage.
--- The data is stored in the `M.state` table. And it can be saved to the file.
--- The value can be a string, number or boolean.

local TYPE_STRING = "string"
local TYPE_NUMBER = "number"
local TYPE_BOOLEAN = "boolean"
local TYPE_TABLE = "table"

---Persist data between game sessions
---@class saver.storage.state
---@field storage table<string, saver.storage.value> @The storage data

---One of the values in the storage
---@class saver.storage.value
---@field s_value string|nil
---@field i_value number|nil
---@field b_value boolean|nil
---@field t_value table|nil

---@class saver.storage
local M = {}

-- Persistent storage
---@type saver.storage.state
M.state = nil

function M.reset_state()
	M.state = {
		storage = {} -- Keeps all the data
	}
end
M.reset_state()


---Get the value from the storage.
---@param name string The storage field name
---@param default_value string|number|boolean|table|nil The default value
---@return string|number|boolean|table|nil
function M.get(name, default_value)
	local storage = M.state.storage

	local value = storage[name]
	if not value then
		return default_value
	end

	return value.s_value or value.i_value or value.t_value or value.b_value
end


---Get the number from the storage.
---@param name string The storage field name
---@param default_value number|nil The default value. If not set, then it will be 0.
---@return number
function M.get_number(name, default_value)
	default_value = default_value or 0

	local value = M.get(name, default_value)
	if type(value) == TYPE_NUMBER then
		---@cast value number
		return value
	end
	return default_value
end


---Get the string from the storage.
---@param name string The storage field name
---@param default_value string|nil The default value. If not set, then it will be an empty string.
---@return string
function M.get_string(name, default_value)
	default_value = default_value or ""

	local value = M.get(name, default_value)
	if type(value) == TYPE_STRING then
		---@cast value string
		return value
	end
	return default_value
end


---Get the boolean from the storage.
---@param name string The storage field name
---@param default_value boolean|nil The default value. If not set, then it will be `false`.
---@return boolean
function M.get_boolean(name, default_value)
	default_value = default_value or false

	local value = M.get(name, default_value)
	if type(value) == TYPE_BOOLEAN then
		---@cast value boolean
		return value
	end
	return default_value
end


---Get the table from the storage.
---@param name string The storage field name
---@param default_value table|nil The default value. If not set, then it will be an empty table.
---@return table
function M.get_table(name, default_value)
	default_value = default_value or {}

	local value = M.get(name, default_value)
	if type(value) == TYPE_TABLE then
		---@cast value table
		return value
	end
	return default_value
end


---Set the value to storage
---@param id string The record id
---@param value string|number|boolean|table value
---@return boolean @true if the value was set, nil otherwise
function M.set(id, value)
	local v = M.state.storage[id] or {}

	if type(value) == TYPE_STRING then
		---@cast value string
		v.s_value = value
		v.i_value = nil
		v.b_value = nil
		v.t_value = nil
	end
	if type(value) == TYPE_NUMBER then
		---@cast value number
		v.i_value = value
		v.s_value = nil
		v.b_value = nil
		v.t_value = nil
	end
	if type(value) == TYPE_BOOLEAN then
		---@cast value boolean
		v.b_value = value
		v.s_value = nil
		v.i_value = nil
		v.t_value = nil
		end
	if type(value) == TYPE_TABLE then
		---@cast value table
		v.t_value = value
		v.s_value = nil
		v.i_value = nil
		v.b_value = nil
	end

	if next(v) == nil then
		return false
	end

	M.state.storage[id] = v
	return true
end


---Delete the value from the storage
---@param id string The record id
function M.delete(id)
	M.state.storage[id] = nil
end


---Check if the value exists in the storage
---@param id string The record id
---@return boolean @true if the value exists, false otherwise
function M.is_exists(id)
	return M.state.storage[id] ~= nil
end


return M
