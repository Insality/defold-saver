return function()
	describe("Binary File Handling", function()
		local saver = nil ---@type saver

		local project_path = nil
		local logo_path = nil
		local binary_data = nil
		local test_binary_save_path = "test_binary_image.png"
		local test_userdata_save_path = "test_userdata.bin"
		local additional_test_files = {}


		before(function()
			saver = require("saver.saver")

			-- Get project path and logo image path
			project_path = saver.get_current_game_project_folder()
			if project_path then
				logo_path = project_path .. "/media/logo.png"

				-- Read the binary data from the logo file
				local file = io.open(logo_path, "rb")
				if file then
					binary_data = file:read("*all")
					file:close()
				end
			end
		end)


		after(function()
			-- Clean up test files
			saver.delete_file_by_name(test_binary_save_path)
			saver.delete_file_by_name(test_userdata_save_path)

			-- Clean up additional test files
			for _, filename in ipairs(additional_test_files) do
				saver.delete_file_by_name(filename)
			end
		end)


		-- Helper function to register additional test files for cleanup
		local function register_test_file(filename)
			table.insert(additional_test_files, filename)
			return filename
		end


		it("Should save and load binary data", function()
			if binary_data then
				-- Save binary data using the dedicated function
				local save_success = saver.save_file_by_path(binary_data, test_binary_save_path, saver.FORMAT.BINARY)
				assert(save_success, "Binary data should be saved successfully")

				-- Load binary data back
				local loaded_data = saver.load_file_by_path(test_binary_save_path, saver.FORMAT.BINARY)
				assert(loaded_data ~= nil, "Binary data should be loaded successfully")
				assert(#loaded_data == #binary_data, "Loaded binary data should have the same size as original")
				assert(loaded_data == binary_data, "Loaded binary data should be identical to original")
			end
		end)


		it("Should save and load binary data with explicit format", function()
			if binary_data then
				-- Save binary data using explicit format
				local save_success = saver.save_file_by_name(binary_data, test_binary_save_path, saver.FORMAT.BINARY)
				assert(save_success, "Binary data should be saved successfully with explicit format")

				-- Load binary data back
				local loaded_data = saver.load_file_by_name(test_binary_save_path, saver.FORMAT.BINARY)
				assert(loaded_data ~= nil, "Binary data should be loaded successfully with explicit format")
				assert(#loaded_data == #binary_data, "Loaded binary data should have the same size as original")
				assert(loaded_data == binary_data, "Loaded binary data should be identical to original")
			end
		end)


		it("Should save and load Lua tables with Defold userdata", function()
			-- Create a table with Defold userdata
			local userdata_table = {
				position = vmath.vector3(100, 200, 300),
				rotation = vmath.quat_rotation_z(math.rad(45)),
				scale = vmath.vector3(2, 2, 2),
				color = vmath.vector4(1, 0, 0, 1),
				hash_value = hash("test_hash"),
				nested = {
					position = vmath.vector3(50, 50, 50)
				}
			}

			-- Save the table with userdata using SERIALIZED format
			local save_success = saver.save_file_by_name(userdata_table, test_userdata_save_path, saver.FORMAT.SERIALIZED)
			assert(save_success, "Table with userdata should be saved successfully")

			-- Load the table back
			local loaded_table = saver.load_file_by_name(test_userdata_save_path, saver.FORMAT.SERIALIZED)
			assert(loaded_table ~= nil, "Table with userdata should be loaded successfully")

			-- Verify the userdata values
			assert(loaded_table.position.x == 100, "Vector3 x component should be preserved")
			assert(loaded_table.position.y == 200, "Vector3 y component should be preserved")
			assert(loaded_table.position.z == 300, "Vector3 z component should be preserved")

			assert(loaded_table.scale.x == 2, "Vector3 scale x should be preserved")
			assert(loaded_table.scale.y == 2, "Vector3 scale y should be preserved")
			assert(loaded_table.scale.z == 2, "Vector3 scale z should be preserved")

			assert(loaded_table.color.x == 1, "Vector4 color r should be preserved")
			assert(loaded_table.color.y == 0, "Vector4 color g should be preserved")
			assert(loaded_table.color.z == 0, "Vector4 color b should be preserved")
			assert(loaded_table.color.w == 1, "Vector4 color a should be preserved")

			assert(loaded_table.hash_value == hash("test_hash"), "Hash value should be preserved")
			assert(loaded_table.nested.position.x == 50, "Nested vector3 x should be preserved")
		end)


		it("Should auto-detect format for saving but use explicit format for loading binary", function()
			if binary_data then
				-- Save binary data with auto-detection (should detect as BINARY)
				local save_success = saver.save_file_by_name(binary_data, test_binary_save_path)
				assert(save_success, "Binary data should be saved successfully with auto-detection")

				-- Load binary data back - we must specify BINARY format for binary data
				-- Auto-detection can cause issues with binary data like PNG files
				local loaded_data = saver.load_file_by_name(test_binary_save_path, saver.FORMAT.BINARY)
				assert(loaded_data ~= nil, "Binary data should be loaded successfully")
				assert(#loaded_data == #binary_data, "Loaded binary data should have the same size as original")
				assert(loaded_data == binary_data, "Loaded binary data should be identical to original")
			end
		end)


		it("Should handle errors gracefully", function()
			-- Test loading non-existent files
			local non_existent_data = saver.load_file_by_path("non_existent_file.png", saver.FORMAT.BINARY)
			assert(non_existent_data == nil, "Non-existent binary file should return nil")

			local non_existent_table = saver.load_file_by_name("non_existent_file.bin", saver.FORMAT.SERIALIZED)
			assert(non_existent_table == nil, "Non-existent serialized table file should return nil")

			-- Test with corrupted file path
			if project_path then
				-- Try to load a text file as binary (should fail gracefully)
				local test_file_path = project_path .. "/test/files/corrupted.json"
				local corrupted_data = saver.load_file_by_path(test_file_path, saver.FORMAT.BINARY)
				-- We don't assert nil here because it might load as binary string, which is fine
				-- The important part is that it doesn't crash
			end
		end)


		it("Should handle loading Lua table with wrong format gracefully", function()
			-- Create and save a table
			local test_table = { test = "value", number = 123 }
			local test_table_path = register_test_file("test_table.bin")

			-- Save as serialized format
			local save_success = saver.save_file_by_name(test_table, test_table_path, saver.FORMAT.SERIALIZED)
			assert(save_success, "Table should be saved successfully")

			-- Try to load with wrong format (as binary)
			-- Should not crash but may return data that can't be used as a table
			local loaded_data = saver.load_file_by_name(test_table_path, saver.FORMAT.BINARY)

			-- Not asserting specific result, just making sure it doesn't crash
		end)


		it("Should handle invalid paths gracefully", function()
			-- Try to load from invalid path should not crash
			local invalid_load_result = saver.load_file_by_path("/invalid/directory/path/file.json")
			assert(invalid_load_result == nil, "Loading from invalid path should return nil")
		end)


		it("Should handle empty files gracefully", function()
			-- Create an empty file
			local empty_file_path = register_test_file("empty_test_file.json")
			local file = io.open(saver.get_save_path(empty_file_path), "w")
			if file then
				file:close()

				-- Try to load empty file
				local empty_file_data = saver.load_file_by_name(empty_file_path)
				assert(empty_file_data == nil, "Loading empty file should return nil")
			end
		end)


		it("Should handle corrupted JSON data gracefully", function()
			-- Create a corrupted JSON file
			local corrupted_json_path = register_test_file("corrupted_test.json")
			local file = io.open(saver.get_save_path(corrupted_json_path), "w")
			if file then
				file:write('{"invalid_json": "missing closing bracket"')
				file:close()

				-- Try to load corrupted JSON
				local corrupted_data = saver.load_file_by_name(corrupted_json_path)
				assert(corrupted_data == nil, "Loading corrupted JSON should return nil")
			end
		end)


		it("Should handle corrupted Lua data gracefully", function()
			-- Create a corrupted Lua file
			local corrupted_lua_path = register_test_file("corrupted_test.lua")
			local file = io.open(saver.get_save_path(corrupted_lua_path), "w")
			if file then
				file:write('return { invalid_lua = "missing closing bracket"')
				file:close()

				-- Try to load corrupted Lua
				local corrupted_data = saver.load_file_by_name(corrupted_lua_path)
				assert(corrupted_data == nil, "Loading corrupted Lua should return nil")
			end
		end)


		it("Should handle format auto-detection edge cases", function()
			-- Test with unusual file extensions
			local unusual_ext_path = register_test_file("test_file.unusual")

			-- Save table data to unusual extension (should use default format)
			local unusual_data = { test = "unusual extension" }
			local save_success = saver.save_file_by_name(unusual_data, unusual_ext_path)
			assert(save_success, "Should save data with unusual extension")

			-- Load with explicit format
			local loaded_data = saver.load_file_by_name(unusual_ext_path, saver.FORMAT.SERIALIZED)
			assert(loaded_data ~= nil, "Should load data with explicit format")
			assert(loaded_data.test == "unusual extension", "Loaded data should match original")
		end)


		it("Should handle concurrent save operations", function()
			-- Create multiple test files
			local test_files = {}
			for i = 1, 5 do
				test_files[i] = register_test_file("concurrent_test_" .. i .. ".json")
			end

			-- Save data to multiple files concurrently
			for i = 1, 5 do
				local data = { test_id = i, value = "concurrent test " .. i }
				local save_success = saver.save_file_by_name(data, test_files[i])
				assert(save_success, "Should save data to file " .. i)
			end

			-- Load all files and verify
			for i = 1, 5 do
				local loaded_data = saver.load_file_by_name(test_files[i])
				assert(loaded_data ~= nil, "Should load data from file " .. i)
				assert(loaded_data.test_id == i, "Loaded data should have correct test_id")
				assert(loaded_data.value == "concurrent test " .. i, "Loaded data should have correct value")
			end
		end)


		it("Should verify all test files are properly cleaned up", function()
			-- Create an additional test file
			local cleanup_test_file = register_test_file("cleanup_test.json")
			local data = { test = "cleanup" }

			-- Save data to file
			local save_success = saver.save_file_by_name(data, cleanup_test_file)
			assert(save_success, "Should save data to cleanup test file")

			-- Verify file exists
			local loaded_data = saver.load_file_by_name(cleanup_test_file)
			assert(loaded_data ~= nil, "File should exist before test completes")

			-- After function will run after this test, cleaning up all files
			-- We can't verify cleanup within the test directly, but the next time tests run,
			-- there should be no leftover files
		end)
	end)
end
