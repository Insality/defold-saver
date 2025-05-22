---@class druid.widget.property_three_buttons: druid.widget
---@field root node
---@field container druid.container
---@field text_name druid.text
---@field button_1 druid.button
---@field text_button_1 druid.text
---@field button_2 druid.button
---@field text_button_2 druid.text
---@field button_3 druid.button
---@field text_button_3 druid.text
local M = {}


function M:init()
	self.root = self:get_node("root")
	self.text_name = self.druid:new_text("text_name")
		:set_text_adjust("scale_then_trim", 0.3)

	self.selected_nodes = {
		self:get_node("selected_1"),
		self:get_node("selected_2"),
		self:get_node("selected_3"),
	}
	gui.set_alpha(self.selected_nodes[1], 0)
	gui.set_alpha(self.selected_nodes[2], 0)
	gui.set_alpha(self.selected_nodes[3], 0)

	self.button_1 = self.druid:new_button("button_1", self.on_click, 1)
	self.text_button_1 = self.druid:new_text("text_button_1")

	self.button_2 = self.druid:new_button("button_2", self.on_click, 2)
	self.text_button_2 = self.druid:new_text("text_button_2")

	self.button_3 = self.druid:new_button("button_3", self.on_click, 3)
	self.text_button_3 = self.druid:new_text("text_button_3")

	self.container = self.druid:new_container(self.root)
	self.container:add_container("text_name", nil, function(_, size)
		self.text_name:set_size(size)
	end)
	self.container:add_container("E_Anchor")
end


function M:on_click(index)
	gui.set_alpha(self.selected_nodes[index], 1)
	gui.animate(self.selected_nodes[index], "color.w", 0, gui.EASING_INSINE, 0.16)
end


---@param text string
---@return druid.widget.property_three_buttons
function M:set_text_property(text)
	self.text_name:set_text(text)
	return self
end


return M
