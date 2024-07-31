local M = {}

---List of migrations
M.migrations = {}


---Add migration to the list
---You should directly point the migration version
---in migration list (array from 1 to N)
---@param migration_list (fun(game_state: saver.game_state, logger: saver.logger): nil)[]
function M.set_migrations(migration_list)
	M.migrations = migration_list
end


---Return amount of migrations
function M.get_count()
	return M.migrations and #M.migrations or 0
end


---Apply the migrations
---@param version number
---@param save_table table
---@param logger saver.logger
---@return boolean success
function M.apply(version, save_table, logger)
	logger:info("Start apply migration to save", { version = version })
	local migration_code = M.migrations[version]

	if not migration_code then
		logger:error("No migration with code", { version = version })
		return false
	end

	migration_code(save_table, logger)
	logger:info("Migration applied to save", { version = version })

	return true
end


return M
