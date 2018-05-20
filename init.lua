local tunneler_huds = {}
local N = 7
local M = 7

local function tunneler_config( tunneler, player, point )
	local meta = tunneler:get_meta()
	--digabel size limited here FIXME
	tunneler_huds[ player:get_player_name() ] = {}
	local player_hud = tunneler_huds[ player:get_player_name() ]
	local digtable = {}
	for i = 1,N do
		digtable[ #digtable + 1 ] = {}
		player_hud[ #player_hud + 1 ] = {}
	end
	--setting up formspec, and hud
	local formspec = "size["..N..","..M.."]position[1,1]anchor[1,1]background[-1,-1;"..(N+2)..","..(M+2)..";digbg2.png;]"
	for i = 1,N do
		for j = 1,M do
			--reading meta
			--FIXME size limit
			digtable[i][j] = ( meta:get_int("b"..i..j) == 1 )

			--setting formspec
			local s = "nodig.png"
			if digtable[i][j] then
				s = "dig.png"
			end
			--FIXME size limit, new name with leading zeros/separator
			formspec = formspec .. "image_button["..(i-1)..","..(j-1)..";1,1;digformspec.png;b"..i..j..";;;;digpressed.png]"

			--setting up hud
			tunneler_huds[ player:get_player_name() ][i][j] = player:hud_add({
				hud_elem_type = "image",
				position = { x=0, y=0 },
				offset = { x=i*38, y=j*38 },
				text = s,
				scale = {x=2, y=2},
				alignment = { x=.5, y=.5}
			})
		end
	end
	minetest.show_formspec( player:get_player_name(), "tunneltest:tunneler_config", formspec )
	return( tunneler)
end

minetest.register_on_player_receive_fields( function( player, formname, fields )
	-- only handle out own
	if formname ~= "tunneltest:tunneler_config" then
		return false
	end

	--if quitting, remove hud
	if fields["quit"] == "true" then
		for i = 1,N do
			for j = 1,M do
				player:hud_remove( tunneler_huds[ player:get_player_name() ][i][j] )
			end
		end
		return
	end

	--if not quitting, save new values
	local tunneler = player:get_wielded_item()
	local meta = tunneler:get_meta()
	for i,j in pairs(fields) do
		--flip flag for field
		meta:set_int( i, 1-meta:get_int(i) )
		--update hud
		--FIXME size limit to 9, use splicing/leading zeros
		local x = tonumber(i:sub(2,2))
		local y = tonumber(i:sub(3,3))
		local s = "nodig.png"
		if meta:get_int(i) == 1 then
			s = "dig.png"
		end
		player:hud_change( tunneler_huds[ player:get_player_name() ][x][y], "text", s )
	end
	--reset original dig flag (should be 0 already, just to make sure)
	meta:set_int("used",0)
	player:set_wielded_item( tunneler )
end)

minetest.register_on_dignode( function( pos, node, player )
	--see if it's a tunneler
	if player:get_wielded_item():get_name() ~= "tunneltest:tunneler" then
		return
	end

	--set up player/tunneler
	local tunneler = player:get_wielded_item()
	local meta = tunneler:get_meta()

	--if not original dig, return
	if meta:get_int("used") == 1 then
		return
	end

	--all other digs will be nonoriginal
	meta:set_int( "used", 1 )
	player:set_wielded_item( tunneler )

	--calcualte directions
	local look_dir = player:get_look_dir()
	local horizontal = vector.new(0,0,0)
	if math.abs( look_dir.x ) < math.abs( look_dir.z ) then
		horizontal.x = -look_dir.z / math.abs( look_dir.z )
	else
		horizontal.z = look_dir.x / math.abs( look_dir.x )
	end

	local dh = math.floor( N/2 ) + 1
	local dv = math.floor( M/2 ) + 1

	--dig everything else
	for i = 1,N do
		for j = 1,M do
			--FIXME spliceing/leading zeros
			if meta:get_int( "b"..i..j ) == 1 then
				local newpos = vector.new( pos )
				newpos = vector.add( newpos, vector.multiply( horizontal, (dh-i)))
				newpos = vector.add(newpos, vector.multiply(vector.new(0,1,0), (dv-j)))
				minetest.node_dig( newpos, minetest.get_node(newpos), player )
			end
		end
	end
	--reset original dig flag
	meta:set_int("used",0)
	player:set_wielded_item( tunneler )
end)

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
	on_place = tunneler_config,
	stack_max = 1,
	on_secondary_use = tunneler_config
})

minetest.register_craft({
	output = "tunneltest:tunneler",
	recipe = {
		{ "default:stone", "default:stone", "default:stone" },
		{ "default:stone", "group:stick", "" },
		{ "", "group:stick", "" },
	}
})
