local tunneler_huds = {}

local function tunneler_config( tunneler, player, point )
	local meta = tunneler:get_meta()
	--digabel size limited here FIXME
	tunneler_huds[ player:get_player_name() ] = {{},{},{}}
	local digtable = {{},{},{}}
	--setting up formspec, and hud
	local formspec = "size[3,3]position[.9,.9]anchor[1,1]background[-1,-1;5,5;digbg.png;]"
	for i = 1,3 do
		for j = 1,3 do
			--reading meta
			digtable[i][j] = ( meta:get_int("b"..i..j) == 1 )

			--setting formspec
			local s = "nodig.png"
			if digtable[i][j] then
				s = "dig.png"
			end
			formspec = formspec .. "image_button["..(i-1)..","..(j-1)..";1,1;digformspec.png;b"..i..j..";;;;digpressed.png]"

			--setting up hud
			tunneler_huds[ player:get_player_name() ][i][j] = player:hud_add({
				hud_elem_type = "image",
				position = { x=.45, y=.45 },
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
		for i = 1,3 do
			for j = 1,3 do
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


minetest.register_tool( "tunneltest:tunneler", {
	description = "Tunneler",
	inventory_image = "tunneler16.png",
	wield_scale = {x=2,y=2,z=1},
	tool_capabilities = {
		max_drop_level=3,
		full_punch_interval = 10,
		groupcaps= {
		    cracky={times={[1]=2.00, [2]=0.75, [3]=0.50}, uses=0, maxlevel=2},
		},
	},
	on_place = tunneler_config,
	stack_max = 1,
	on_secondary_use = tunneler_config
})

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

	--FIXME limited size
	--dig everything else
	for i = 1,3 do
		for j = 1,3 do
			if meta:get_int( "b"..i..j ) == 1 then
				local newpos = vector.new( pos )
				newpos = vector.add( newpos, vector.multiply( horizontal, (2-i)))
				newpos = vector.add(newpos, vector.multiply(vector.new(0,1,0), (2-j)))
				minetest.node_dig( newpos, minetest.get_node(newpos), player )
			end
		end
	end
	--reset original dig flag
	meta:set_int("used",0)
	player:set_wielded_item( tunneler )
end)
