local properties_saver_slots = require("saver.properties_panel.property_saver_slots")

local M = {}


---@param saver saver
---@param druid druid.instance
---@param properties_panel druid.widget.properties_panel
function M.render_properties_panel(saver, druid, properties_panel)
	properties_panel:next_scene()
	properties_panel:set_header("Saver Panel")

	properties_panel:add_button(function(button)
		button:set_text_property("Game State")
		button:set_text_button("Save")
		button.button.on_click:subscribe(function()
			saver.save_game_state()
		end)
	end)

	properties_panel:add_button(function(button)
		button:set_text_property("Game State")
		button:set_text_button("Inspect")
		button.button.on_click:subscribe(function()
			properties_panel:next_scene()
			properties_panel:set_header("Game State")
			properties_panel:render_lua_table(saver.get_game_state())
		end)
	end)

	properties_panel:add_widget(function()
		local three_buttons = druid:new_widget(properties_saver_slots, "property_saver_slots", "root")
		three_buttons:set_text_property("Save Slot")

		three_buttons.button_1.on_click:subscribe(function()
			saver.save_game_state("saver_slot_1")
		end)
		three_buttons.button_2.on_click:subscribe(function()
			saver.save_game_state("saver_slot_2")
		end)
		three_buttons.button_3.on_click:subscribe(function()
			saver.save_game_state("saver_slot_3")
		end)

		return three_buttons
	end)

	properties_panel:add_widget(function()
		local three_buttons = druid:new_widget(properties_saver_slots, "property_saver_slots", "root")
		three_buttons:set_text_property("Load Slot")

		three_buttons.button_1.on_click:subscribe(function()
			saver.load_game_state("saver_slot_1")
			sys.reboot()
		end)
		three_buttons.button_2.on_click:subscribe(function()
			saver.load_game_state("saver_slot_2")
			sys.reboot()
		end)
		three_buttons.button_3.on_click:subscribe(function()
			saver.load_game_state("saver_slot_3")
			sys.reboot()
		end)

		return three_buttons
	end)

	properties_panel:add_widget(function()
		local three_buttons = druid:new_widget(properties_saver_slots, "property_saver_slots", "root")
		three_buttons:set_text_property("Delete Slot")

		three_buttons.button_1.on_click:subscribe(function()
			print("Hold button to delete slot 1")
		end)
		three_buttons.button_1.on_long_click:subscribe(function()
			saver.delete_game_state("saver_slot_1")
			sys.reboot()
		end)

		three_buttons.button_2.on_click:subscribe(function()
			print("Hold button to delete slot 2")
		end)
		three_buttons.button_2.on_long_click:subscribe(function()
			saver.delete_game_state("saver_slot_2")
			sys.reboot()
		end)

		three_buttons.button_3.on_click:subscribe(function()
			print("Hold button to delete slot 3")
		end)
		three_buttons.button_3.on_long_click:subscribe(function()
			saver.delete_game_state("saver_slot_3")
			sys.reboot()
		end)

		return three_buttons
	end)

	properties_panel:add_button(function(button)
		button:set_text_property("Game State")
		button:set_text_button("pprint")
		button.button.on_click:subscribe(function()
			pprint(saver.get_game_state())
		end)
	end)

	properties_panel:add_input(function(input)
		input:set_text_property("Autosave")
		input.on_change_value:subscribe(function(value)
			value = tonumber(value) or 0
			print("Autosave timer: " .. value)
			saver.set_autosave_timer(value)
		end)
		input:set_text_value(saver.get_autosave_timer())
	end)

	properties_panel:add_text(function(text)
		text:set_text_property("Version")
		text:set_text_value(tostring(saver.get_save_version()))
	end)
end


return M
