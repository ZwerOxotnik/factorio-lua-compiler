require("prototypes.style")
local GRAPHICS_PATH = "__lua-compiler__/graphics/"

local new_combinator = table.deepcopy(data.raw['constant-combinator']['constant-combinator'])
new_combinator.name = "zLua-compiler"
new_combinator.minable = {
	hardness = 0.1,
	mining_time = 0.1,
	result = new_combinator.name
}

if data.raw["custom-input"]["open-gui"] == nil then
	data.raw["custom-input"]["open-gui"] = {
		type = "custom-input",
		name = "open-gui",
		key_sequence = "",
		linked_game_control = "open-gui"
	}
end

data:extend{
	new_combinator, {
		type = "item",
		name = new_combinator.name,
		place_result = new_combinator.name,
		icon = "__base__/graphics/icons/constant-combinator.png",
    icon_size = 64, icon_mipmaps = 4,
		stack_size = 100,
		subgroup = "circuit-network",
		order = 'zz'
	}, {
		type = "sprite",
		name = "microcontroller-play-sprite",
		filename = GRAPHICS_PATH .. "play.png",
		width = 32,
		height = 32
	}, {
		type = "sprite",
		name = "microcontroller-exit-sprite",
		filename = GRAPHICS_PATH .. "cancel.png",
		width = 32,
		height = 32
	}, {
		type = "sprite",
		name = "microcontroller-copy-sprite",
		filename = GRAPHICS_PATH .. "copy.png",
		width = 32,
		height = 32
	}, {
		type = "sprite",
		name = "microcontroller-paste-sprite",
		filename = GRAPHICS_PATH .. "draft.png",
		width = 32,
		height = 32
	}, {
		type = "sprite",
		name = "refresh",
		filename = GRAPHICS_PATH .. "refresh.png",
		width = 32,
		height = 32
	}, {
		type = "sprite",
		name = "power-on",
		filename = GRAPHICS_PATH .. "power-on.png",
		width = 32,
		height = 32
	}, {
		type = "sprite",
		name = "power-off",
		filename = GRAPHICS_PATH .. "power-off.png",
		width = 32,
		height = 32
	}
}
