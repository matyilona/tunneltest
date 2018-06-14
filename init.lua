local settings = dofile( minetest.get_modpath("tunneltest") .. "/tunneltest.conf" )
local N = settings.N
local M = settings.M

local tunneler_utils = dofile( minetest.get_modpath("tunneltest") .. "/tunneler.lua" )

for name, desc in pairs( settings.tunneler_types ) do
	minetest.debug( dump( name ) )
	minetest.debug( dump( desc ) )
	local toolspec = desc.toolspec
	toolspec.stack_max = 1
	toolspec.on_secondary_use = tunneler_utils.config
	toolspec.on_place = tunneler_utils.config
	minetest.register_tool( "tunneltest:"..name, toolspec )
	minetest.register_craft( { output = "tunneltest:"..name, recipe = desc.recipe } )
end

minetest.register_on_player_receive_fields( tunneler_utils.field_handler )

minetest.register_on_dignode( tunneler_utils.on_dig )

--[[
--TODO values from config, multiple versions with different specs, etc.
minetest.register_tool( "tunneltest:tunneler", {
	description = "Tunneler",
	inventory_image = "tunneler16.png",
	wield_scale = {x=2,y=2,z=1},
	tool_capabilities = {
		max_drop_level=3,
		full_punch_interval = 10,
		groupcaps= {
		    cracky={times={[1]=2.00, [2]=0.75, [3]=0.50}, uses=100, maxlevel=2},
		},
	},
	on_place = tunneler_utils.config,
	stack_max = 1,
	on_secondary_use = tunneler_utils.config
})

minetest.register_craft({
	output = "tunneltest:tunneler",
	recipe = {
		{ "default:stone", "default:stone", "default:stone" },
		{ "default:stone", "group:stick",   "" },
		{ "",              "group:stick",   "" },
	}
})
]]
