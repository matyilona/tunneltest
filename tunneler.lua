--load settings
local settings = dofile( minetest.get_modpath("tunneltest") .. "/tunneltest.conf" )

--store all active hud elements for all players
local tunneler_huds = {}

local function tunneler_config( tunneler, player, point )

	--get parameters of the configured tool
	local meta = tunneler:get_meta()
	local N = tunneler:get_definition()["_N"]
	local M = tunneler:get_definition()["_M"]

	--set up huds for the player
	tunneler_huds[ player:get_player_name() ] = {}
	local player_hud = tunneler_huds[ player:get_player_name() ]

	--tabble to store nodes to dig
	--TODO is it needed? we only ever use one square at a time
	local digtable = {}
	for i = 1,N do
		digtable[ #digtable + 1 ] = {}
		player_hud[ #player_hud + 1 ] = {}
	end

	--setting up formspec, and hud
	local formspec = "size["..N..","..M.."]position[1,1]anchor[1,1]background[-1,-1;"..(N+2)..","..(M+2)..";digbg2.png;]"
	for i = 1,N do
		for j = 1,M do
			--fill digtable
			digtable[i][j] = ( meta:get_int("b"..i.."-"..j) == 1 )

			--setting up formspec
			local img = "digformspec.png"
			--middle is always dug out, have special texture
			if (i == math.ceil( N/2 )) and (j == math.ceil( M/2 )) then
				img = img .. "^dig_mid.png"
			end
			
			formspec = formspec .. "image_button["..(i-1)..","..(j-1)..";1,1;"..img..";b"..i.."-"..j..";;;;digpressed.png]"

			--setting up hud
			--TODO look into huds using overlays (not possible?)
			local s = "dig.png"
			if not digtable[i][j] then
				s = "nodig.png"
			end
			if (i == math.ceil( N/2 )) and (j == math.ceil( M/2 )) then
				s = "middig.png"
			end

			--store all the huds for each player
			tunneler_huds[ player:get_player_name() ][i][j] = player:hud_add({
				hud_elem_type = "image",
				position = settings.hud.pos,
				offset = { x=i*settings.hud.x_offset, y=j*settings.hud.y_offset },
				text = s,
				scale = settings.hud.scale,
				alignment = settings.hud.alignment
			})
		end
	end

	--show the formspec
	minetest.show_formspec( player:get_player_name(), "tunneltest:tunneler_config", formspec )
	return( tunneler)
end

local function tunneler_field_handler( player, formname, fields )
	
	-- only handle our own forms
	if formname ~= "tunneltest:tunneler_config" then
		return false
	end

	--get player/tool data
	local tunneler = player:get_wielded_item()
	local meta = tunneler:get_meta()
	local N = tunneler:get_definition()["_N"]
	local M = tunneler:get_definition()["_M"]

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
	for i,j in pairs(fields) do

		--flip flag for field
		meta:set_int( i, 1-meta:get_int(i) )

		--update hud
		local _, _, x, y = string.find( i, "b(%d+)-(%d+)" )
		x = tonumber(x)
		y = tonumber(y)
		local s = "nodig.png"
		if meta:get_int(i) == 1 then
			s = "dig.png"
		end
		if (x == math.ceil( N/2 )) and (y == math.ceil( M/2 )) then
			s = "middig.png"
		end
		player:hud_change( tunneler_huds[ player:get_player_name() ][x][y], "text", s )
	end

	--reset original dig flag (should be 0 already, just to make sure)
	meta:set_int("used",0)
	--set new wield item
	player:set_wielded_item( tunneler )
end

local function tunneler_on_dig( pos, node, player )

	--see if it's a tunneler
	if string.find(player:get_wielded_item():get_name(), "tunneltest:.*_tunneler") == nil then
		return
	end

	--set up player/tunneler
	local tunneler = player:get_wielded_item()
	local meta = tunneler:get_meta()
	local N = tunneler:get_definition()["_N"]
	local M = tunneler:get_definition()["_M"]

	--if not original dig, return
	if meta:get_int("used") == 1 then
		return
	end

	--all other digs will be nonoriginal
	meta:set_int( "used", 1 )

	--calcualte directions
	--TODO do it with dit_to_facedir facedir_to_dir -> propably more robust
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
			if meta:get_int( "b"..i.."-"..j ) == 1 then
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
end

return( { config=tunneler_config, field_handler=tunneler_field_handler, on_dig=tunneler_on_dig } )
