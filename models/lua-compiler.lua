local M = {}

--#region Storage data
local __mod_data
---@type table<integer, LuaEntity>
local __players_opened_compile
---@type table<integer, function>
local __compiled = {}
---@type table<integer, string>
local __compilers_text
---@type table<integer, string>
local __players_copyboard
--#endregion


--#region Constants
local RED_COLOR = {1, 0, 0}
local DEFAULT_TEXT = "local compiler, player = ...\nplayer.print(compiler.name)"
--#endregion


if script.mod_name ~= "lua-compiler" then
	remote.remove_interface("disable-lua-compiler")
	remote.add_interface("disable-lua-compiler", {})
end


--#region utils

function M.destroy_GUI(player)
	local element = player.gui.screen.zLua_compiler
	if element then
		element.destroy()
	end
end

function M.on_click_on_compiler(player, entity)
	local unit_number = entity.unit_number
	local screenGui = player.gui.screen
	if screenGui.zLua_compiler then
		local player_index = player.index
		local text = screenGui.zLua_compiler.scroll_pane["zLua_program-input"].text
		if text ~= '' then
			__compilers_text[unit_number] = text
			__compiled[unit_number] = load(text)
			__players_opened_compile[player_index] = nil
		else
			__compilers_text[unit_number] = nil
			__compiled[unit_number] = nil
		end
		screenGui.zLua_compiler.destroy()
		return false
	end

	local compiler_text = __compilers_text[unit_number]

	local main_frame = screenGui.add{type = "frame", name = "zLua_compiler", direction = "vertical"}
	local flow = main_frame.add{type = "flow", name = "flow"}
	flow.add{
		type = "label",
		style = "frame_title",
		caption = {"item-name.zLua-compiler"},
		ignored_by_interaction = true
	}
	local drag_handler = flow.add{type = "empty-widget", style = "draggable_space"}
	drag_handler.drag_target = main_frame
	drag_handler.style.right_margin = 0
	drag_handler.style.horizontally_stretchable = true
	drag_handler.style.height = 32
	flow.add{
		type = "sprite-button",
		name = "zLua_close-compiler",
		style = "frame_action_button",
		sprite = "utility/close",
		hovered_sprite = "utility/close_black",
		clicked_sprite = "utility/close_black"
	}

	local is_have_errors = false
	-- Data of the lowest element
	local error_element_data = {type = "label", name = "error_message", caption = "", style = "bold_red_label"}
	if compiler_text then
		if __compiled[unit_number] == nil then
			is_have_errors = true
			error_element_data.caption = {"lua-compiler.cant-compile"}
		end
	end

	local buttons_row = main_frame.add{type = "table", name = "buttons_row", column_count = 8}
	local content = {type = "sprite-button"}
	if compiler_text then
		content.name = "zLua_run"
		content.sprite = "microcontroller-play-sprite"
		buttons_row.add(content)
	else
		content.name = "zLua_refresh"
		content.sprite = "refresh"
		buttons_row.add(content)
	end
	content.name = "zLua_power-off"
	content.sprite = "power-off"
	if entity.rotatable then
		if is_have_errors then
			entity.rotatable = false
		else
			content.name = "zLua_power-on"
			content.sprite = "power-on"
		end
	end
	buttons_row.add(content)
	content.name = "zLua_copy"
	content.sprite = "microcontroller-copy-sprite"
	buttons_row.add(content)
	content.name = "zLua_paste"
	content.sprite = "microcontroller-paste-sprite"
	buttons_row.add(content)

	local scroll_pane = main_frame.add{type = "scroll-pane", name = "scroll_pane"}
	local textbox = scroll_pane.add{type = "text-box", name = "zLua_program-input", style = "lua_program_input"}
	if entity.destructible then
		textbox.text = compiler_text or DEFAULT_TEXT
	else
		textbox.text = compiler_text or ''
	end

	main_frame.add(error_element_data)


	main_frame.force_auto_center()
	return main_frame
end

local function clear_compiler_data(event)
	local unit_number = event.entity.unit_number
	__compiled[unit_number] = nil
	__compilers_text[unit_number] = nil
end

--#endregion


--#region Events

function M.left_mouse_click(event)
	local player = game.get_player(event.player_index)
	local entity = player.selected
	if not (entity and entity.valid) then return end

	if entity.name == "zLua-compiler" then
		local is_destructible = entity.destructible
		if is_destructible == false then
			if entity.rotatable then
				local f = __compiled[entity.unit_number]
				if f then
					local is_ok, error = pcall(f, entity, player)
					if not is_ok then
						player.print(error, RED_COLOR)
					end
					return
				end
			end
		else
			entity.minable = false
			entity.rotatable = false
			entity.operable = false
		end

		if not player.admin then
			entity.operable = false
			player.print({"command-output.parameters-require-admin"})
			return
		end
		local gui = M.on_click_on_compiler(player, entity)
		if gui then
			__players_opened_compile[player.index] = entity
		else
			__players_opened_compile[player.index] = nil
		end

		if is_destructible then
			entity.destructible = false
		end
	end
end

function M.on_gui_text_changed(event)
	local element = event.element
	if element.name ~= "zLua_program-input" then return end

	local button = element.parent.parent.buttons_row.zLua_run
	if button then
		button.name = "zLua_refresh"
		button.sprite = "refresh"
	end
end

function M.on_entity_settings_pasted(event)
	local player = game.get_player(event.player_index)
	if not player.admin then return end
	local source = event.source
	local destination = event.destination
	if destination.name ~= source.name then return end

	if source.name == "zLua-compiler" then
		local sun = source.unit_number
		local dun = destination.unit_number
		__compilers_text[dun] = __compilers_text[sun]
		__compiled[dun] = __compiled[sun]
	end
end

function M.on_player_removed(event)
	__players_opened_compile[event.player_index] = nil
end

function M.on_player_far_from_compiler(event)
	local player_index = event.player_index
	local player = game.get_player(player_index)
	M.destroy_GUI(player)
	__players_opened_compile[player_index] = nil
end

function M.on_player_left_game(event)
	local player_index = event.player_index
	__players_copyboard[player_index] = nil
	__players_opened_compile[player_index] = nil
end

function M.on_player_joined_game(event)
	local player_index = event.player_index
	__players_copyboard[player_index] = nil
	M.destroy_GUI(game.get_player(player_index))
end

function M.on_player_rotated_entity(event)
	local entity = event.entity
	if entity.name ~= "zLua-compiler" then return end
	local player = game.get_player(event.player_index)
	if not player.admin then return end

	local gui = M.on_click_on_compiler(player, entity)
	if gui then
		__players_opened_compile[player.index] = entity
	else
		__players_opened_compile[player.index] = nil
	end
end

local GUIS = {
	["zLua_paste"] = function(element, player)
		local text = __players_copyboard[player.index]
		if text == nil then return end
		local parent = element.parent
		parent.parent.scroll_pane["zLua_program-input"].text = text
		local unit_number = __players_opened_compile[player.index].unit_number
		if text ~= '' then
			local f = load(text)
			local error_message_GUI = parent.parent.error_message
			__compilers_text[unit_number] = text
			__compiled[unit_number] = f
			if type(f) == "function" then
				local refresh_element = parent.buttons_row.zLua_refresh
				if refresh_element then
					refresh_element.name = "zLua_run"
					refresh_element.sprite = "microcontroller-play-sprite"
				end
			else
				error_message_GUI.caption = {"lua-compiler.cant-compile"}
				__players_opened_compile[player.index].rotatable = false
				local power_element = parent.parent.buttons_row["zLua_power-on"]
				if power_element then
					power_element.name = "zLua_power-off"
					power_element.sprite = "power-off"
				end
			end
		else
			__compilers_text[unit_number] = nil
			__compiled[unit_number] = nil
		end
		--TODO: add undo, self destruction
	end,
	["zLua_copy"] = function(element, player)
		__players_copyboard[player.index] = element.parent.parent.scroll_pane["zLua_program-input"].tex
	end,
	["zLua_power-off"] = function(element, player)
		local entity = __players_opened_compile[player.index]
		element.name = "zLua_power-on"
		element.sprite = "power-on"
		entity.rotatable = true
		player.print({"lua-compiler.rotate-hint"})
	end,
	["zLua_power-on"] = function(element, player)
		local entity = __players_opened_compile[player.index]
		element.name = "zLua_power-off"
		element.sprite = "power-off"
		entity.rotatable = false
	end,
	["zLua_close-compiler"] = function(element, player)
		local entity = __players_opened_compile[player.index]
		local zLua_compiler = player.gui.screen.zLua_compiler
		local buttons_row = zLua_compiler.buttons_row
		if entity and entity.valid and buttons_row.zLua_refresh then
			local text = zLua_compiler.scroll_pane["zLua_program-input"].text
			local unit_number = entity.unit_number
			if text ~= '' and text ~= DEFAULT_TEXT then
				local f = load(text)
				__compilers_text[unit_number] = text
				__compiled[unit_number] = f
			else
				__compilers_text[unit_number] = nil
				__compiled[unit_number] = nil
			end
		end
		zLua_compiler.destroy()
	end,
	["zLua_refresh"] = function(element, player)
		local unit_number = __players_opened_compile[player.index].unit_number
		local parent = element.parent
		local text = parent.parent.scroll_pane["zLua_program-input"].text
		if text ~= '' then
			local f = load(text)
			__compilers_text[unit_number] = text
			__compiled[unit_number] = f
			local error_message_GUI = parent.parent.error_message
			if type(f) == "function" then
				element.name = "zLua_run"
				element.sprite = "microcontroller-play-sprite"
			else
				error_message_GUI.caption = {"lua-compiler.cant-compile"}
			end
		else
			__compilers_text[unit_number] = nil
			__compiled[unit_number] = nil
			player.print({"lua-compiler.no-code"})
			local power_element = parent.parent.buttons_row["zLua_power-on"]
			if power_element then
				power_element.name = "zLua_power-off"
				power_element.sprite = "power-off"
				__players_opened_compile[player.index].rotatable = false
			end
		end
	end,
	["zLua_run"] = function(element, player)
		local entity = __players_opened_compile[player.index]
		local error_message_GUI = element.parent.parent.error_message
		local is_ok, error = pcall(__compiled[entity.unit_number], entity, player)
		if not is_ok then
			error_message_GUI.caption = error
			local power_element = element.parent.buttons_row["zLua_power-on"]
			if power_element then
				power_element.name = "zLua_power-off"
				power_element.sprite = "power-off"
				entity.rotatable = false
			end
		else
			error_message_GUI.caption = ""
		end
	end
}
function M.on_gui_click(event)
	local element = event.element
	local f = GUIS[element.name]
	if f then f(element, game.get_player(event.player_index)) end
end

--#endregion


--#region Pre-game stage

function M.check_all_compilers()
	for unit_number, text in pairs(__compilers_text) do
		__compiled[unit_number] = load(text)
	end
end

function M.link_data()
	__mod_data = storage["lua-compiler"]
	__players_opened_compile = __mod_data.players_opened_compile
	__compilers_text = __mod_data.compilers_text
	__players_copyboard = __mod_data.players_copyboard
end

function M.set_filters()
	local filters = {{filter = "name", name = "zLua-compiler"}}
	script.set_event_filter(defines.events.on_player_mined_entity, filters)
	script.set_event_filter(defines.events.on_entity_died, filters)
	script.set_event_filter(defines.events.on_robot_mined_entity, filters)
	script.set_event_filter(defines.events.script_raised_destroy, filters)
end

function M.update_global_data()
	storage["lua-compiler"] = storage["lua-compiler"] or {}
	__mod_data = storage["lua-compiler"]
	__mod_data.compilers_text = __mod_data.compilers_text or {}
	__mod_data.players_opened_compile = {}
	__mod_data.players_copyboard = {}

	M.link_data()

	for _, player in pairs(game.players) do
		M.destroy_GUI(player)
	end
	for unit_number, entity in pairs(__compilers_text) do
		if not (entity and entity.valid) then
			__compilers_text[unit_number] = nil
			__compiled[unit_number] = nil
		end
	end

	M.set_filters()
	M.check_all_compilers()
end

M.on_init = M.update_global_data
M.on_configuration_changed = M.update_global_data
M.on_load = function()
	M.link_data()
	M.set_filters()
	M.check_all_compilers()
end
M.add_remote_interface = function()
	-- https://lua-api.factorio.com/latest/LuaRemote.html
	remote.remove_interface("lua-compiler") -- For safety
	remote.add_interface("lua-compiler", {
		get_source = function()
			return script.mod_name
		end,
		get_mod_data = function()
			return __mod_data
		end,
		execute_compiler = function(entity, player)
			local f = __compiled[entity.unit_number]
			if f ~= nil then
				f(entity, player)
			end
		end,
		add_compiler = function(entity, text)
			local unit_number = entity.unit_number
			local f = load(text)
			__compiled[unit_number] = f
			if type(f) == "function" then
				__compilers_text[unit_number] = text
				entity.destructible = false
				entity.minable = false
				entity.rotatable = false
				entity.operable = true
			end
			return f
		end,
		change_text = function(entity, text)
			local unit_number = entity.unit_number
			local f = load(text)
			__compiled[unit_number] = f
			if type(f) == "function" then
				__compilers_text[unit_number] = text
			end
			return f
		end,
		get_function = function(entity)
			return __compiled[entity.unit_number]
		end,
		close_complier_gui = M.destroy_GUI,
		open_complier_gui = function(player, entity)
			M.destroy_GUI(player)
			local gui = M.on_click_on_compiler(player, entity)
			if gui then
				__players_opened_compile[player.index] = entity
			else
				__players_opened_compile[player.index] = nil
			end
		end
	})
end

--#endregion

function M.pcall_event(event, f)
	local is_ok, message = pcall(f, event)
	if not is_ok then
		local player = game.get_player(event.player_index)
		if not (player and player.valid) then return end
		player.print(message, {1, 0, 0})
	end
end


M.events = {
	[defines.events.on_gui_click] = function(event)
		M.pcall_event(event, M.on_gui_click)
	end,
	[defines.events.on_entity_settings_pasted] = function(event)
		M.pcall_event(event, M.on_entity_settings_pasted)
	end,
	["open-gui"] = function(event)
		M.pcall_event(event, M.left_mouse_click)
	end,
	[defines.events.on_gui_text_changed] = function(event)
		M.pcall_event(event, M.on_gui_text_changed)
	end,
	[defines.events.on_player_joined_game] = M.on_player_joined_game,
	[defines.events.on_player_removed] = M.on_player_removed,
	[defines.events.on_player_respawned] = function(event)
		M.pcall_event(event, M.on_player_far_from_compiler)
	end,
	[defines.events.on_player_left_game] = function(event)
		M.pcall_event(event, M.on_player_left_game)
	end,
	[defines.events.on_player_rotated_entity] = function(event)
		M.pcall_event(event, M.on_player_rotated_entity)
	end,
	[defines.events.on_player_demoted] = function(event)
		pcall(M.destroy_GUI, game.get_player(event.player_index))
	end,
	[defines.events.on_player_mined_entity] = clear_compiler_data,
	[defines.events.on_entity_died] = clear_compiler_data,
	[defines.events.on_robot_mined_entity] = clear_compiler_data,
	[defines.events.script_raised_destroy] = clear_compiler_data,
}

return M
