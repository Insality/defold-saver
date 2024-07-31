--- Storage module
--- This module is used to store the key-value data in the persistent storage.
--- The data is stored in the `M.state` table. And it can be saved to the file.
--- The value can be a string, number or boolean.

local TYPE_STRING = "string"
local TYPE_NUMBER = "number"
local TYPE_BOOLEAN = "boolean"

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
---@param default_value string|number|boolean|nil The default value
---@return string|number|boolean|nil
function M.get(name, default_value)
	local storage = M.state.storage

	local value = storage[name]
	if not value then
		return default_value
	end

	return value.s_value or value.i_value or value.b_value
end


---Get the number from the storage.
---@param name string The storage field name
---@param default_value number|nil The default value. If not set, then it will be 0.
---@return number
function M.get_number(name, default_value)
	default_value = default_value or 0

	local value = M.get(name, default_value)
	if type(value) == TYPE_NUMBER then
		return value --[[@as number]]
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
		return value --[[@as string]]
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
		return value --[[@as boolean]]
	end
	return default_value
end


---Set the value to storage
---@param id string The record id
---@param value string|number|boolean value
---@return boolean @true if the value was set, nil otherwise
function M.set(id, value)
	local v = M.state.storage[id] or {}

	if type(value) == TYPE_STRING then
		v.s_value = value --[[@as string]]
		v.i_value = nil
		v.b_value = nil
	end
	if type(value) == TYPE_NUMBER then
		v.i_value = value --[[@as number]]
		v.s_value = nil
		v.b_value = nil
	end
	if type(value) == TYPE_BOOLEAN then
		v.b_value = value --[[@as boolean]]
		v.s_value = nil
		v.i_value = nil
	end

	if next(v) == nil then
		return false
	end

	M.state.storage[id] = v
	return true
end


return M
