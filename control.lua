local event_handler = require("event_handler")

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

event_handler.add_libraries(modules)
