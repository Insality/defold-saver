local saver = require("saver.saver")
local properties_saver_slots = require("saver.properties_panel.property_saver_slots")

local M = {}


---@param druid druid.instance
---@param properties_panel druid.widget.properties_panel
function M.render_properties_panel(druid, properties_panel)
	properties_panel:next_scene()
	properties_panel:set_header("Saver Panel")

	properties_panel:add_button(function(button)
		button:set_text_property("Save Game")
		button:set_text_button("Save")
		button.button.on_click:subscribe(function()
			saver.save_game_state()
		end)
	end)

	properties_panel:add_button(function(button)
		button:set_text_property("Save Folder")
		button:set_text_button("Open")
		button:set_color("#6FA4DC")
		button.button.on_click:subscribe(function()
			M.open_at_desktop(saver.get_save_path())
		end)
	end)

	properties_panel:add_button(function(button)
		button:set_text_property("Inspect State")
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
			sys.reboot("--config=saver.save_name=saver_slot_1", "--config=saver.autosave_timer=0")
		end)
		three_buttons.button_2.on_click:subscribe(function()
			saver.load_game_state("saver_slot_2")
			sys.reboot("--config=saver.save_name=saver_slot_2", "--config=saver.autosave_timer=0")
		end)
		three_buttons.button_3.on_click:subscribe(function()
			saver.load_game_state("saver_slot_3")
			sys.reboot("--config=saver.save_name=saver_slot_3", "--config=saver.autosave_timer=0")
		end)

		return three_buttons
	end)

	properties_panel:add_widget(function()
		local three_buttons = druid:new_widget(properties_saver_slots, "property_saver_slots", "root")
		three_buttons:set_text_property("Delete Slot")

		three_buttons.button_1.on_click:subscribe(function()
			print("You pressed delete button. Hold to confirm.")
		end)
		three_buttons.button_1.on_long_click:subscribe(function()
			saver.delete_game_state("saver_slot_1")
		end)

		three_buttons.button_2.on_click:subscribe(function()
			print("You pressed delete button. Hold to confirm.")
		end)
		three_buttons.button_2.on_long_click:subscribe(function()
			saver.delete_game_state("saver_slot_2")
		end)

		three_buttons.button_3.on_click:subscribe(function()
			print("You pressed delete button. Hold to confirm.")
		end)
		three_buttons.button_3.on_long_click:subscribe(function()
			saver.delete_game_state("saver_slot_3")
		end)

		return three_buttons
	end)

	properties_panel:add_button(function(button)
		button:set_text_property("pprint")
		button:set_text_button("Game State")
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


---@param path string
---@return boolean
function M.open_at_desktop(path)
	local system = sys.get_sys_info().system_name
	if system == "Windows" then
		os.execute(string.format('explorer /select,"%s"', path))
		return true
	elseif system == "Linux" then
		os.execute(string.format("xdg-open %q", path))
		return true
	elseif system == "Darwin" then
		os.execute(string.format("open -R %q", path))
		return true
	end

	return false
end


return M
