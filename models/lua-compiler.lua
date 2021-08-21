local M = {}

--#region Global data
local mod_data
---@type table <number, LuaEntity>
local players_opened_compile = {}
---@type table <number, function>
local compiled = {}
---@type table <number, string>
local compilers_text
---@type table <number, string>
local players_copyboard = {}
--#endregion


--#region Constants
local RED_COLOR = {1, 0, 0}
--#endregion


if script.mod_name ~= "lua-compiler" then
	remote.remove_interface("disable-lua-compiler")
	remote.add_interface("disable-lua-compiler", {})
end


--#region utils

local function destroyGUI(player)
	local zLua_compiler_frame = player.gui.screen.zLua_compiler
	if zLua_compiler_frame then
		zLua_compiler_frame.destroy()
	end
end

local function on_click_on_compiler(player, entity)
	local unit_number = entity.unit_number
	local screenGui = player.gui.screen
	if screenGui.zLua_compiler then
		local player_index = player.index
		local text = screenGui.zLua_compiler.list.scroll_pane["zLua_program-input"].text
		if text ~= '' then
			compilers_text[unit_number] = text
			f = load(text)
			if type(f) == "function" then
				compiled[unit_number] = f
			end
			players_opened_compile[player_index] = nil
			screenGui.zLua_compiler.destroy()
		else
			compilers_text[unit_number] = ''
			compiled[unit_number] = nil
		end
		return
	end

	local compiler_text = compilers_text[unit_number]

	local frame = screenGui.add{type = "frame", name = "zLua_compiler", caption = {"item-name.zLua-compiler"}}
	local list = frame.add{type = "table", name = "list", column_count = 1}

	local flow1 = list.add{type = "table", name = "buttons_row", column_count = 5, vertical_centering = true}
	local content = {type = "sprite-button"}
	if compiler_text then
		content.name = "zLua_run"
		content.sprite = "microcontroller-play-sprite"
		flow1.add(content)
	else
		content.name = "zLua_refresh"
		content.sprite = "refresh"
		flow1.add(content)
	end
	if entity.rotatable then
		content.name = "zLua_power-on"
		content.sprite = "power-on"
		flow1.add(content)
	else
		content.name = "zLua_power-off"
		content.sprite = "power-off"
		flow1.add(content)
	end
	content.name = "zLua_copy"
	content.sprite = "microcontroller-copy-sprite"
	flow1.add(content)
	content.name = "zLua_paste"
	content.sprite = "microcontroller-paste-sprite"
	flow1.add(content)
	content.name = "zLua_close-compiler"
	content.sprite = "microcontroller-exit-sprite"
	flow1.add(content)

	local scroll_pane = list.add{type = "scroll-pane", name = "scroll_pane"}
	local textbox = scroll_pane.add{type = "text-box", name = "zLua_program-input", style = "lua_program_input"}
	textbox.text = compiler_text or "local compiler = ...\ngame.print(compiler.name)"

	list.add{type = "label", name = "error_message", caption = "", style = "bold_red_label"}
end

local function clear_compiler_data(event)
	local unit_number = event.entity.unit_number
	compiled[unit_number] = nil
	compilers_text[unit_number] = nil
end

--#endregion


--#region Events

local function left_mouse_click(event)
	local player = game.get_player(event.player_index)
	local entity = player.selected

	if entity.name == "zLua-compiler" then
		if not entity.destructible then
			if entity.rotatable then
				local f = compiled[entity.unit_number]
				if f then
					local is_ok, error = pcall(compiled[entity.unit_number], entity)
					if not is_ok then
						player.print(error, RED_COLOR)
					end
					return
				end
			end
		else
			entity.destructible = false
			entity.minable = false
			entity.rotatable = false
			entity.operable = false
		end

		if not player.admin then
			entity.operable = false
			player.print({"command-output.parameters-require-admin"})
			return
		end
		on_click_on_compiler(player, entity)
		players_opened_compile[player.index] = entity
	end
end

local function on_gui_text_changed(event)
	local element = event.element
	if element.name ~= "zLua_program-input" then return end

	local button = element.parent.parent.buttons_row.zLua_run
	if button then
		button.name = "zLua_refresh"
		button.sprite = "refresh"
	end
end

local function on_entity_settings_pasted(event)
	local player = game.get_player(event.player_index)
	if not player.admin then return end
	local source = event.source
	local destination = event.destination
	if destination.name ~= source.name then return end

	if source.name == "zLua-compiler" then
		local sun = source.unit_number
		local dun = destination.unit_number
		compilers_text[dun] = compilers_text[sun]
		compiled[dun] = compiled[sun]
	end
end

local function on_player_removed(event)
	players_opened_compile[event.player_index] = nil
end

local function on_player_far_from_compiler(event)
	local player_index = event.player_index
	local player = game.get_player(player_index)
	destroyGUI(player)
	players_opened_compile[player_index] = nil
end

local function on_player_left_game(event)
	local player_index = event.player_index
	players_copyboard[player_index] = nil
	players_opened_compile[player_index] = nil
end

local function on_player_joined_game(event)
	players_copyboard[event.player_index] = nil
end

local function on_player_rotated_entity(event)
	local entity = event.entity
	if entity.name ~= "zLua-compiler" then return end
	local player = game.get_player(event.player_index)
	if not player.admin then return end

	on_click_on_compiler(player, entity)
end

local function on_gui_click(event)
	local player_index = event.player_index
	local player = game.get_player(player_index)
	local element = event.element
	local element_name, count = (element.name):gsub("zLua_", '')
	if count == 0 then return end

	if element_name == "run" then
		local entity = players_opened_compile[player_index]
		local error_message_GUI = element.parent.parent.error_message
		local is_ok, error = pcall(compiled[entity.unit_number], entity)
		if not is_ok then
			error_message_GUI.caption = error
			local power_element = element.parent.parent.buttons_row["zLua_power-on"]
			if power_element then
				power_element.name = "zLua_power-off"
				power_element.sprite = "power-off"
				entity.rotatable = false
			end
		else
			error_message_GUI.caption = ""
		end
	elseif element_name == "refresh" then
		local unit_number = players_opened_compile[player_index].unit_number
		local text = element.parent.parent.scroll_pane["zLua_program-input"].text
		if text ~= '' then
			local f = load(text)
			local error_message_GUI = element.parent.parent.error_message
			if type(f) == "function" then
				compiled[unit_number] = f
				element.name = "zLua_run"
				element.sprite = "microcontroller-play-sprite"
			else
				compiled[unit_number] = nil
				error_message_GUI.caption = {"lua-compiler.cant-compile"}
			end
		else
			compilers_text[unit_number] = ''
			compiled[unit_number] = nil
		end
	elseif element_name == "close-compiler" then
		if element.parent.parent.buttons_row.zLua_refresh then
			local text = element.parent.parent.scroll_pane["zLua_program-input"].text
			local unit_number = players_opened_compile[player_index].unit_number
			compilers_text[unit_number] = text
			if text ~= '' then
				local f = load(text)
				if type(f) == "function" then
					compiled[unit_number] = f
				end
			else
				compiled[unit_number] = nil
			end
		end
		player.gui.screen.zLua_compiler.destroy()
	elseif element_name == "power-on" then
		local entity = players_opened_compile[player_index]
		element.name = "zLua_power-off"
		element.sprite = "power-off"
		entity.rotatable = false
	elseif element_name == "power-off" then
		local entity = players_opened_compile[player_index]
		element.name = "zLua_power-on"
		element.sprite = "power-on"
		entity.rotatable = true
		player.print({"lua-compiler.rotate-hint"})
	elseif element_name == "copy" then
		players_copyboard[player_index] = element.parent.parent.scroll_pane["zLua_program-input"].text
	elseif element_name == "paste" then
		local text = players_copyboard[player_index]
		if text == nil then return end
		element.parent.parent.scroll_pane["zLua_program-input"].text = text
		local unit_number = players_opened_compile[player_index].unit_number
		if text ~= '' then
			local f = load(text)
			local error_message_GUI = element.parent.parent.error_message
			if type(f) == "function" then
				compiled[unit_number] = f
				local refresh_element = element.parent.parent.buttons_row.zLua_refresh
				if refresh_element then
					refresh_element.name = "zLua_run"
					refresh_element.sprite = "microcontroller-play-sprite"
				end
			else
				compiled[unit_number] = nil
				error_message_GUI.caption = {"lua-compiler.cant-compile"}
			end
		else
			compilers_text[unit_number] = ''
			compiled[unit_number] = nil
		end
	--TODO: add undo
	end
end

--#endregion


--#region Pre-game stage

local function check_all_compilers()
	for unit_number, text in pairs(compilers_text) do
		local f = load(text)
		if type(f) == "function" then
			compiled[unit_number] = f
		end
	end
end

local function link_data()
	mod_data = global["lua-compiler"]
	players_opened_compile = mod_data.players_opened_compile
	compilers_text = mod_data.compilers_text
	players_copyboard = mod_data.players_copyboard
end

local function update_global_data()
	global["lua-compiler"] = global["lua-compiler"] or {}
	mod_data = global["lua-compiler"]
	mod_data.compilers_text = mod_data.compilers_text or {}
	mod_data.players_opened_compile = {}
	mod_data.players_copyboard = {}

	link_data()

	local filters = {{filter = "name", name = "zLua-compiler"}}
	script.set_event_filter(defines.events.on_player_mined_entity, filters)
	script.set_event_filter(defines.events.on_entity_died, filters)
	script.set_event_filter(defines.events.on_robot_mined_entity, filters)
	script.set_event_filter(defines.events.script_raised_destroy, filters)

	for _, player in pairs(game.players) do
		destroyGUI(player)
	end
	for unit_number, entity in pairs(compilers_text) do
		if not (entity and entity.valid) then
			compilers_text[unit_number] = nil
			compiled[unit_number] = nil
		end
	end
end

M.on_init = update_global_data
M.on_configuration_changed = update_global_data
M.on_load = function()
	link_data()
	check_all_compilers()
end
M.add_remote_interface = function()
	-- https://lua-api.factorio.com/latest/LuaRemote.html
	remote.remove_interface("lua-compiler") -- For safety
	remote.add_interface("lua-compiler", {
		get_source = function()
			return script.mod_name
		end,
		execute_compiler = function(entity)
			compiled[entity.unit_number](entity)
		end,
		get_mod_data = function()
			return mod_data
		end,
		add_compiler = function(entity, text)
			local f = load(text)
			if type(f) == "function" then
				local unit_number = entity.unit_number
				compiled[unit_number] = f
				compilers_text[unit_number] = text
				entity.destructible = false
				entity.minable = false
				entity.rotatable = false
				entity.operable = true
				return unit_number
			else
				return false
			end
		end,
		close_complier_gui = destroyGUI,
		open_complier_gui = function(player, entity)
			destroyGUI(player)
			on_click_on_compiler(player, entity)
		end
	})
end

--#endregion


M.events = {
	[defines.events.on_gui_click] = function(event)
		pcall(on_gui_click, event)
	end,
	[defines.events.on_entity_settings_pasted] = function(event)
		pcall(on_entity_settings_pasted, event)
	end,
	["open-gui"] = function(event)
		pcall(left_mouse_click, event)
	end,
	[defines.events.on_gui_text_changed] = function(event)
		pcall(on_gui_text_changed, event)
	end,
	[defines.events.on_player_joined_game] = on_player_joined_game,
	[defines.events.on_player_removed] = on_player_removed,
	[defines.events.on_player_respawned] = function(event)
		pcall(on_player_far_from_compiler, event)
	end,
	[defines.events.on_player_respawned] = function(event)
		pcall(on_player_far_from_compiler, event)
	end,
	[defines.events.on_player_left_game] = function(event)
		pcall(on_player_left_game, event)
	end,
	[defines.events.on_player_rotated_entity] = function(event)
		pcall(on_player_rotated_entity, event)
	end,
	[defines.events.on_player_demoted] = function(event)
		pcall(destroyGUI, game.get_player(event.player_index))
	end,
	[defines.events.on_player_mined_entity] = clear_compiler_data,
	[defines.events.on_entity_died] = clear_compiler_data,
	[defines.events.on_robot_mined_entity] = clear_compiler_data,
	[defines.events.script_raised_destroy] = clear_compiler_data,
}

return M
