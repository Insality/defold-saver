return function()
	describe("Defold Saver", function()
		local saver = {} --[[@as saver]]
		local state = {
			value = 0
		}

		local load_game_state = function()
			saver.init()
			saver.set_logger(nil)
			saver.bind_save_state("state", state)
		end

		before(function()
			saver = require("saver.saver")
			saver.delete_game_state()
			load_game_state()
		end)

		it("Should save and load the state", function()
			state.value = state.value + 1
			saver.save_game_state()

			state.value = state.value + 1
			state.value = state.value + 1
			assert(state.value == 3)

			load_game_state()
			assert(state.value == 1)
		end)

		it("Should save files in different formats", function()
			saver.save_file_by_name({ foo = "bar" }, "test.json")
			local data = saver.load_file_by_name("test.json")
			assert(data.foo == "bar")

			saver.save_file_by_name({ foo = "bar2" }, "cache/test2.json")
			local data2 = saver.load_file_by_name("cache/test2.json")
			assert(data2.foo == "bar2")

			saver.save_file_by_name({ foo = "bar3" }, "cache/test3")
			local data3 = saver.load_file_by_name("cache/test3")
			assert(data3.foo == "bar3")

			saver.save_file_by_name({ foo = "bar4" }, "cache/test4.lua")
			local data4 = saver.load_file_by_name("cache/test4.lua")
			assert(data4.foo == "bar4")
		end)

		it("Should delete files", function()
			saver.delete_file_by_name("test.json")
			local data = saver.load_file_by_name("test.json")
			assert(data == nil)

			saver.delete_file_by_name("cache/test2.json")
			local data2 = saver.load_file_by_name("cache/test2.json")
			assert(data2 == nil)

			saver.delete_file_by_name("cache/test3")
			local data3 = saver.load_file_by_name("cache/test3")
			assert(data3 == nil)

			saver.delete_file_by_name("cache/test4.lua")
			local data4 = saver.load_file_by_name("cache/test4.lua")
			assert(data4 == nil)
		end)

		it("Should not load corrupted files", function()
			local folder = saver.get_current_game_project_folder()
			if folder then
				local corrupted_json = folder .. "/test/files/corrupted.json"
				local corrupted_lua = folder .. "/test/files/corrupted.lua"

				local data = saver.load_file_by_path(corrupted_json)
				assert(data == nil)

				local data2 = saver.load_file_by_path(corrupted_lua)
				assert(data2 == nil)
			end
		end)
	end)
end
