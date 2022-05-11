---@type table<string, module>
local modules = {}
modules["lua-compiler"] = require("models/lua-compiler")
local module = modules["lua-compiler"]

if remote.interfaces["disable-lua-compiler"] then
	module.events = nil
	module.on_nth_tick = nil
	module.commands = nil
	module.on_load = nil
	module.add_remote_interface = nil
	module.add_commands = nil
end


local event_handler
if script.active_mods["zk-lib"] then
	event_handler = require("__zk-lib__/static-libs/lualibs/event_handler_vZO.lua")
else
	event_handler = require("event_handler")
end
event_handler.add_libraries(modules)

if script.active_mods["gvv"] then require("__gvv__.gvv")() end
