return function()
	describe("Defold Saver", function()
		local saver ---@type saver
		local state = {
			value = 0
		}

		local load_game_state = function()
			saver.init()
			--saver.set_logger(nil)
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

		it("Should handle invalid paths gracefully", function()
			-- Try to save to an invalid directory path
			local save_result = saver.save_file_by_path({ test = "data" }, "/invalid/directory/path/file.json")
			assert(save_result == false, "Should return false when saving to invalid path")

			-- Try to load from non-existent path
			local load_result = saver.load_file_by_path("/non/existent/file.json")
			assert(load_result == nil, "Should return nil when loading from non-existent path")
		end)

		it("Should handle edge cases with filenames", function()
			-- Test with empty filename (should fail gracefully)
			local result = saver.save_file_by_name({ test = "data" }, "")
			assert(result == false, "Should handle empty filename gracefully")

			-- Test with very long filename
			local long_filename = string.rep("a", 200) .. ".json"
			local long_result = saver.save_file_by_name({ test = "data" }, long_filename)
			-- We don't assert specific result as it depends on the filesystem,
			-- but it should not crash

			-- Clean up if saved
			saver.delete_file_by_name(long_filename)
		end)

		it("Should handle unusual data types", function()
			-- Test with nil data (should fail gracefully)
			local nil_result = saver.save_file_by_name(nil, "nil_test.json")
			assert(nil_result == false, "Should handle nil data gracefully")
		end)

		it("Should handle edge cases with game state", function()
			-- Test binding nil state
			local original_state = state
			state = nil
			saver.bind_save_state("nil_state", state)

			-- Should not crash when saving
			saver.save_game_state()

			-- Reset state
			state = original_state
			saver.bind_save_state("state", state)

			-- Test loading non-existent game state
			saver.delete_game_state()

			-- Reinitialize default state before loading
			state = { value = 0 }

			saver.init()
			saver.bind_save_state("state", state)
			assert(state.value == 0, "Should initialize with default values when no saved state exists")
		end)
	end)
end
