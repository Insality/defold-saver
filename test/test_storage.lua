return function()
	describe("Defold Storage", function()
		local saver ---@type saver
		local storage ---@type saver.storage

		before(function()
			saver = require("saver.saver")
			storage = require("saver.storage")

			saver.delete_game_state()
			saver.init()
		end)

		it("Should able to use storage", function()
			storage.set("foo", "bar")
			storage.set("number", 10)
			storage.set("bool_false", false)
			storage.set("bool_true", true)

			assert(storage.get("foo") == "bar")
			assert(storage.get("number") == 10)
			assert(storage.get("bool_false") == false)
			assert(storage.get("bool_true") == true)
		end)

		it("Should work correct with default values", function()
			assert(storage.get("foo", "default") == "default")
			assert(storage.get("number", 10) == 10)
			assert(storage.get("bool_true", true) == true)
			assert(storage.get("bool_false", false) == false)

			assert(storage.get("not_exist", "default") == "default")
			assert(storage.get_boolean("not_exist", true) == true)
			assert(storage.get_number("not_exist", 10) == 10)
			assert(storage.get_string("not_exist", "default") == "default")
		end)

		it("Should use default values if type mismatch", function()
			storage.set("foo", 10)
			storage.set("number", "bar")
			storage.set("bool_false", "true")
			storage.set("bool_true", 0)

			assert(storage.get_string("foo", "default") == "default")
			assert(storage.get_number("number", 10) == 10)
			assert(storage.get_boolean("bool_false", false) == false)
			assert(storage.get_boolean("bool_true", true) == true)
		end)
	end)
end
