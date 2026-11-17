return function()
	describe("Defold Migrations", function()
		local saver --[[@as saver]]

		before(function()
			saver = require("saver.saver")
		end)

		it("Should to able set migrations", function ()
			saver.delete_game_state()
			saver.set_migrations({
				function (save_table, logger)
					save_table.foo = "bar"
				end,
				function (save_table, logger)
					save_table.foo = "bar2"
				end,
			})

			saver.init()
			saver.apply_migrations()

			local save_table = saver.get_game_state()
			-- We have empty save, so migrations should not apply
			assert(save_table.foo == nil)

			saver.save_game_state()
		end)

		it("Should run migrations on the existing profile", function ()
			saver.set_migrations({
				function (save_table, logger)
					save_table.foo = "bar"
				end,
				function (save_table, logger)
					save_table.foo = "bar2"
				end,
				-- New migration added
				function (save_table, logger)
					save_table.foo = "bar3"
				end
			})

			saver.init()
			saver.apply_migrations()

			local save_table = saver.get_game_state()
			-- We have created a save where 2 migrations already exists and add 3 migration
			pprint(save_table)
			assert(save_table.foo == "bar3")

			saver.delete_game_state()
		end)

		it("Should not run migrations twice after an older game version loads the save", function ()
			local function create_migrations(count)
				local list = {}
				for index = 1, count do
					table.insert(list, function (save_table, logger)
						save_table.foo = "bar" .. index
					end)
				end
				return list
			end

			-- A new save on the newer game: 3 migrations
			saver.delete_game_state()
			saver.set_migrations(create_migrations(3))
			saver.init()
			saver.apply_migrations()
			saver.save_game_state()

			-- The older game with 1 migration loads it
			saver.set_migrations(create_migrations(1))
			saver.init()
			saver.apply_migrations()
			saver.save_game_state()

			-- Back on the newer game: migrations 2 and 3 are already applied
			saver.set_migrations(create_migrations(3))
			saver.init()
			saver.apply_migrations()

			assert(saver.get_game_state().foo == nil)

			saver.delete_game_state()
		end)
	end)
end
