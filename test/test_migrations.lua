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
	end)
end
