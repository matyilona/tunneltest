minetest.register_tool( "tunneltest:tunneler", {
	description = "For tunneling",
	inventory_image = "tunneler.png",
	wield_scale = {x=2,y=2,z=1},
	tool_capabilities = {
		max_drop_level=3,
		full_punch_interval = 10,
		groupcaps= {
		    cracky={times={[1]=2.00, [2]=0.75, [3]=0.50}, uses=0, maxlevel=2},
		},
	}
})

minetest.register_on_dignode( function( pos, node, player )
	if player:get_wielded_item():get_name() ~= "tunneltest:tunneler" then
		return
	end

	local tunneler = player:get_wielded_item()
	local meta = tunneler:get_meta()
	if meta:get_int("used") > 1 then
		meta:set_int("used",0)
		player:set_wielded_item( tunneler )
		return
	end
	pos.y = pos.y - 1
	meta:set_int( "used", meta:get_int("used") + 1 )
	player:set_wielded_item( tunneler )
	minetest.node_dig( pos, minetest.get_node(pos), player )
end)
