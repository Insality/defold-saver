return function()
	-- Move storage functions to the saver module
	-- Storage module is deprecated
	describe("Defold Saver Storage", function()
		local saver = {} ---@type saver

		before(function()
			saver = require("saver.saver")

			saver.delete_game_state()
			saver.init()
		end)

		it("Should able to use storage", function()
			saver.set_value("foo", "bar")
			saver.set_value("number", 10)
			saver.set_value("bool_false", false)
			saver.set_value("bool_true", true)

			assert(saver.get_value("foo") == "bar")
			assert(saver.get_value("number") == 10)
			assert(saver.get_value("bool_false") == false)
			assert(saver.get_value("bool_true") == true)
		end)

		it("Should work correct with default values", function()
			assert(saver.get_value("foo", "default") == "default")
			assert(saver.get_value("number", 10) == 10)
			assert(saver.get_value("bool_true", true) == true)
			assert(saver.get_value("bool_false", false) == false)

			assert(saver.get_value("not_exist", "default") == "default")

			assert(saver.get_value("not_exist", true) == true)
			assert(type(saver.get_value("not_exist", true)) == "boolean")

			local a = saver.get_value("not_exist", 10)
			assert(a == 10)
			assert(type(a) == "number")

			assert(saver.get_value("not_exist", "default") == "default")
			assert(type(saver.get_value("not_exist", "default")) == "string")

			local default_table = { foo = "bar" }
			assert(saver.get_value("not_exist", default_table) == default_table)
			assert(type(saver.get_value("not_exist", default_table)) == "table")
		end)

		it("Should handle nil values correctly", function()
			-- Setting nil value should effectively remove the key
			saver.set_value("to_be_nil", "value")
			assert(saver.get_value("to_be_nil") == "value")

			saver.set_value("to_be_nil", nil)
			assert(saver.get_value("to_be_nil") == nil)
			assert(saver.get_value("to_be_nil", "default") == "default")
		end)

		it("Should handle edge cases with key names", function()
			-- Empty key
			saver.set_value("", "empty_key")
			assert(saver.get_value("") == "empty_key")

			-- Key with special characters
			saver.set_value("special!@#$%^&*()_+", "special_chars")
			assert(saver.get_value("special!@#$%^&*()_+") == "special_chars")

			-- Very long key
			local long_key = string.rep("a", 100)
			saver.set_value(long_key, "long_key")
			assert(saver.get_value(long_key) == "long_key")
		end)

		it("Should handle type changes", function()
			-- Change value type
			saver.set_value("type_change", "string")
			assert(saver.get_value("type_change") == "string")

			saver.set_value("type_change", 123)
			assert(saver.get_value("type_change") == 123)

			saver.set_value("type_change", true)
			assert(saver.get_value("type_change") == true)

			saver.set_value("type_change", { nested = "table" })
			assert(type(saver.get_value("type_change")) == "table")
			assert(saver.get_value("type_change").nested == "table")
		end)

		it("Should handle nested tables", function()
			-- Test deeply nested tables
			local deep_table = {
				level1 = {
					level2 = {
						level3 = {
							level4 = {
								value = "deep"
							}
						}
					}
				}
			}

			saver.set_value("deep", deep_table)
			local loaded = saver.get_value("deep")

			assert(loaded.level1.level2.level3.level4.value == "deep")
		end)

		it("Should handle edge cases with values", function()
			-- Empty table
			saver.set_value("empty_table", {})
			assert(type(saver.get_value("empty_table")) == "table")

			-- Table with numeric keys
			local array_table = {"one", "two", "three"}
			saver.set_value("array", array_table)
			local loaded_array = saver.get_value("array")
			assert(loaded_array[1] == "one")
			assert(loaded_array[2] == "two")
			assert(loaded_array[3] == "three")

			-- Empty string
			saver.set_value("empty_string", "")
			assert(saver.get_value("empty_string") == "")
		end)

		it("Should handle is_value_exists", function()
			saver.set_value("foo", "bar")
			assert(saver.is_value_exists("foo"))
			assert(not saver.is_value_exists("not_exist"))
		end)
	end)
end
