if script.active_mods["lua-compiler"] then
	local event_handler = require("event_handler")
	event_handler.add_lib(require("__lua-compiler__/models/lua-compiler"))
end
