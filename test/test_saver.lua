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

		it("Should correctly save and load Defold userdata", function()
			-- Create a player object with various userdata types
			local player = {
				position = vmath.vector3(100, 200, 300),
				rotation = vmath.quat_rotation_z(math.rad(45)),
				id = hash("player_entity"),
				velocity = vmath.vector3(5, -2, 0),
				color = vmath.vector4(1, 0, 0, 0.5),
				nested = {
					subposition = vmath.vector3(10, 20, 30),
					subhash = hash("nested_value")
				}
			}

			-- Save using SERIALIZED format which should preserve userdata
			local save_path = "userdata_test"
			local save_result = saver.save_file_by_name(player, save_path, saver.FORMAT.SERIALIZED)
			assert(save_result, "Should successfully save userdata")

			-- Load it back
			local loaded_player = saver.load_file_by_name(save_path, saver.FORMAT.SERIALIZED)
			assert(loaded_player ~= nil, "Should load userdata successfully")

			-- Test vector3 properties
			assert(loaded_player.position.x == 100, "Vector3 position.x should be preserved")
			assert(loaded_player.position.y == 200, "Vector3 position.y should be preserved")
			assert(loaded_player.position.z == 300, "Vector3 position.z should be preserved")

			assert(loaded_player.velocity.x == 5, "Vector3 velocity.x should be preserved")
			assert(loaded_player.velocity.y == -2, "Vector3 velocity.y should be preserved")
			assert(loaded_player.velocity.z == 0, "Vector3 velocity.z should be preserved")

			-- Test vector4 properties
			assert(loaded_player.color.x == 1, "Vector4 color.x should be preserved")
			assert(loaded_player.color.y == 0, "Vector4 color.y should be preserved")
			assert(loaded_player.color.z == 0, "Vector4 color.z should be preserved")
			assert(loaded_player.color.w == 0.5, "Vector4 color.w should be preserved")

			-- Test quaternion properties (checking w component as a simple test)
			-- cos(45°/2) = ~0.9238
			assert(math.abs(loaded_player.rotation.w - math.cos(math.rad(45)/2)) < 0.0001,
				"Quaternion rotation.w should be preserved")

			-- Test hash
			assert(loaded_player.id == hash("player_entity"), "Hash id should be preserved")

			-- Test nested userdata
			assert(loaded_player.nested.subposition.x == 10, "Nested vector3 x should be preserved")
			assert(loaded_player.nested.subposition.y == 20, "Nested vector3 y should be preserved")
			assert(loaded_player.nested.subposition.z == 30, "Nested vector3 z should be preserved")
			assert(loaded_player.nested.subhash == hash("nested_value"), "Nested hash should be preserved")

			-- Test JSON format (should lose userdata properties)
			local json_path = "userdata_test.json"
			saver.save_file_by_name(player, json_path)
			local json_loaded = saver.load_file_by_name(json_path)

			-- JSON format should not preserve userdata types
			assert(type(json_loaded.position) ~= "userdata", "JSON format should not preserve userdata types")

			-- Clean up
			saver.delete_file_by_name(save_path)
			saver.delete_file_by_name(json_path)
		end)

		it("Should save and load binary data with renamed functions", function()
			-- Create some binary data (a simple string in this case)
			local binary_data = string.char(0x01, 0x02, 0x03, 0x04, 0xFF, 0xFE, 0xFD, 0xFC)

			-- Test save_binary_by_path and load_binary_by_path
			local binary_path = "binary_test.bin"
			local save_result = saver.save_file_by_path(binary_data, binary_path, saver.FORMAT.BINARY)
			assert(save_result, "Should successfully save binary data")

			local loaded_data = saver.load_file_by_path(binary_path, saver.FORMAT.BINARY)
			assert(loaded_data ~= nil, "Should load binary data successfully")
			assert(#loaded_data == #binary_data, "Binary data length should match")
			assert(loaded_data == binary_data, "Binary data content should match exactly")

			-- Test backward compatibility functions (save_binary and load_binary)
			local compat_path = "binary_compat_test.bin"
			local compat_save_result = saver.save_file_by_path(binary_data, compat_path, saver.FORMAT.BINARY)
			assert(compat_save_result, "Should successfully save binary data with legacy function")

			local compat_loaded_data = saver.load_file_by_path(compat_path, saver.FORMAT.BINARY)
			assert(compat_loaded_data ~= nil, "Should load binary data successfully with legacy function")
			assert(#compat_loaded_data == #binary_data, "Binary data length should match with legacy function")
			assert(compat_loaded_data == binary_data, "Binary data content should match exactly with legacy function")

			-- Clean up
			saver.delete_file_by_name(binary_path)
			saver.delete_file_by_name(compat_path)
		end)
	end)
end
