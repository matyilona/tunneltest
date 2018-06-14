local settings = dofile( minetest.get_modpath("tunneltest") .. "/tunneltest.conf" )

local tunneler_huds = {}

local function tunneler_config( tunneler, player, point )
	local meta = tunneler:get_meta()
	local N = tunneler:get_definition()["_N"]
	local M = tunneler:get_definition()["_M"]
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
			digtable[i][j] = ( meta:get_int("b"..i.."-"..j) == 1 )

			--setting formspec
			local s = "nodig.png"
			if digtable[i][j] then
				s = "dig.png"
			end
			formspec = formspec .. "image_button["..(i-1)..","..(j-1)..";1,1;digformspec.png;b"..i.."-"..j..";;;;digpressed.png]"

			--setting up hud
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
	minetest.show_formspec( player:get_player_name(), "tunneltest:tunneler_config", formspec )
	return( tunneler)
end

local function tunneler_field_handler( player, formname, fields )
	-- only handle out own
	if formname ~= "tunneltest:tunneler_config" then
		return false
	end

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
		player:hud_change( tunneler_huds[ player:get_player_name() ][x][y], "text", s )
	end
	--reset original dig flag (should be 0 already, just to make sure)
	meta:set_int("used",0)
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
			--FIXME names in meta
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
