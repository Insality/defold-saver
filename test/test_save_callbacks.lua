return function()
	describe("Defold Saver Save Callbacks", function()
		local saver ---@type saver
		local saver_internal = require("saver.saver_internal")
		local json_encode = saver_internal.json_encode
		local state = {
			value = 0
		}

		before(function()
			saver = require("saver.saver")
			saver.delete_game_state()
			saver.delete_file_by_name("callback_test.json")
			saver.delete_file_by_name("callback_test_copy")
			saver.init()
			saver.bind_save_state("state", state)
			state.value = 0
		end)

		after(function()
			saver.before_save_callback = nil
			saver.after_save_callback = nil
			saver_internal.json_encode = json_encode
			saver.set_autosave_timer(0)
			saver.delete_game_state()
			saver.delete_file_by_name("callback_test.json")
			saver.delete_file_by_name("callback_test_copy")
		end)

		it("Should call after_save_callback after the file write", function()
			local calls = {}
			saver.before_save_callback = function()
				table.insert(calls, "before")
			end
			saver.after_save_callback = function(is_saved, save_name)
				table.insert(calls, "after")
				assert(is_saved == true)
				assert(save_name == "game")
				local saved_data = saver.load_file_by_name(save_name)
				assert(saved_data.state.value == 5, "The file is written before the callback")
			end

			state.value = 5
			local is_saved = saver.save_game_state()

			assert(is_saved == true)
			assert(#calls == 2)
			assert(calls[1] == "before")
			assert(calls[2] == "after")
		end)

		it("Should pass the save name to after_save_callback", function()
			local saved_name = nil
			saver.after_save_callback = function(is_saved, save_name)
				saved_name = save_name
			end

			saver.save_game_state("callback_test.json")
			assert(saved_name == "callback_test.json")
		end)

		it("Should call after_save_callback with false on a failed write and keep the previous file", function()
			state.value = 1
			assert(saver.save_game_state("callback_test.json") == true)

			local results = {}
			saver.after_save_callback = function(is_saved)
				table.insert(results, is_saved)
			end
			saver_internal.json_encode = function()
				error("Encode failed")
			end

			state.value = 2
			local is_saved = saver.save_game_state("callback_test.json")

			assert(is_saved == false)
			assert(#results == 1)
			assert(results[1] == false)
			local saved_data = saver.load_file_by_name("callback_test.json")
			assert(saved_data.state.value == 1, "A failed encode should not touch the previous file")
		end)

		it("Should fail the save when the JSON encode returns nil", function()
			local result = nil
			saver.after_save_callback = function(is_saved)
				result = is_saved
			end
			saver_internal.json_encode = function()
				return nil
			end

			assert(saver.save_game_state("callback_test.json") == false)
			assert(result == false)
		end)

		it("Should allow a save from inside after_save_callback", function()
			local saved_names = {}
			saver.after_save_callback = function(is_saved, save_name)
				table.insert(saved_names, save_name)
				if save_name == "game" then
					assert(saver.save_game_state("callback_test_copy") == true)
				end
			end

			state.value = 3
			assert(saver.save_game_state() == true)

			assert(#saved_names == 2)
			assert(saved_names[1] == "game")
			assert(saved_names[2] == "callback_test_copy")
			assert(saver.load_file_by_name("callback_test_copy").state.value == 3)
		end)

		it("Should keep the autosave running when a save callback fails", function()
			saver.set_autosave_timer(2)
			saver.before_save_callback = function()
				error("Callback failed")
			end

			-- Make the next timer tick the autosave tick
			saver.autosave_timer_counter = 0.001
			saver.last_autosave_time = socket.gettime() - 1
			local is_ok = pcall(saver.on_autosave_timer)

			assert(is_ok == false)
			assert(saver.autosave_timer_counter == 2, "The next autosave is scheduled")
		end)

		it("Should keep the Lua format output", function()
			local lua_string = saver_internal.table_to_lua_string({ 1, "two", { x = 1 }, key = true, ["with space"] = "value", nested = { 3, 4 } })
			local expected = table.concat({
				"{",
				"    1,",
				"    \"two\",",
				"    {",
				"        x = 1,",
				"    },",
				"    key = true,",
				"    nested = {",
				"        3,",
				"        4,",
				"    },",
				"    [\"with space\"] = \"value\",",
				"}",
			}, "\n")

			assert(lua_string == expected)
		end)
	end)
end
