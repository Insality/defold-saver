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
			saver.set("foo", "bar")
			saver.set("number", 10)
			saver.set("bool_false", false)
			saver.set("bool_true", true)

			assert(saver.get("foo") == "bar")
			assert(saver.get("number") == 10)
			assert(saver.get("bool_false") == false)
			assert(saver.get("bool_true") == true)
		end)

		it("Should work correct with default values", function()
			assert(saver.get("foo", "default") == "default")
			assert(saver.get("number", 10) == 10)
			assert(saver.get("bool_true", true) == true)
			assert(saver.get("bool_false", false) == false)

			assert(saver.get("not_exist", "default") == "default")

			assert(saver.get("not_exist", true) == true)
			assert(type(saver.get("not_exist", true)) == "boolean")

			local a = saver.get("not_exist", 10)

			assert(saver.get("not_exist", 10) == 10)
			assert(type(saver.get("not_exist", 10)) == "number")

			assert(saver.get("not_exist", "default") == "default")
			assert(type(saver.get("not_exist", "default")) == "string")

			local default_table = { foo = "bar" }
			assert(saver.get("not_exist", default_table) == default_table)
			assert(type(saver.get("not_exist", default_table)) == "table")
		end)
	end)
end
