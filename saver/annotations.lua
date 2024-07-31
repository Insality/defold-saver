---Download Defold annotations from here: https://github.com/astrochili/defold-annotations/releases/

---Persist data between game sessions
---@class saver.storage.state
---@field storage table<string, saver.storage.value> @The storage data

---One of the values in the storage
---@class saver.storage.value
---@field s_value string|nil
---@field i_value number|nil
---@field b_value boolean|nil

---Persist data between game sessions
---@class saver.state
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
