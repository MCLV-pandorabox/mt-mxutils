local modname = assert(core.get_current_modname())
local modstorage = core.get_mod_storage()
local mod_channel
local mxdata = {}



core.register_on_shutdown(function()
	print("[mx] shutdown client")
end)
local id = nil
local log = function(param)
    minetest.log("action", param)
end

local print = function(param)
    --core.log(param)
    --minetest.log("action", param)
    log(param)
end
local logdump=function(param) 
    log(dump(param))
    return dump(param)
end
function split(s, sep)
    local fields = {}
    
    local sep = sep or " "
    local pattern = string.format("([^%s]+)", sep)
    string.gsub(s, pattern, function(c) fields[#fields + 1] = c end)
    
    return fields
end
local strtopos=function(str)
	local fields={}
	local x,y,z = split(str,",")
	return {x=x,y=y,z=z}
end
local ls = function(param)
    local str = ""
    if type(param) == "table" then
		for k,v in pairs(param) do
			if type(v) ~= "string"  then
				str=str .. k .. " = " .. type(v) .."\n" 
			else
				str=str .. k .. " = " .. v .."\n"
			end
		end
	elseif type(param) == "function" then
		str = str .. "show function here tosstring maybe?" .. tostring(param)
	elseif type(param) == "string" then
		str = str .. "\"".. param .."\""
	elseif type(param) == "boolean" then
		str = str ..  tostring(param) 
	elseif type(param) == "number" then
		str = str ..  tostring(param) 
	else
		str = str .. "have no clue what to do with type: " .. type(param)
	end
	log("ls:\n".. str)
	return str
end
do
	local server_info = core.get_server_info()
	print("Server version: " .. server_info.protocol_version)
	print("Server ip: " .. server_info.ip)
	print("Server address: " .. server_info.address)
	print("Server port: " .. server_info.port)

	print("CSM restrictions: " .. dump(core.get_csm_restrictions()))

	local l1, l2 = core.get_language()
	print("Configured language: " .. l1 .. " / " .. l2)
end

mod_channel = core.mod_channel_join("experimental_mxutil")

core.after(4, function()
	if mod_channel:is_writeable() then
		mod_channel:send_all("mxutil talk to experimental")
	end
end)

core.after(5, function()
	if core.localplayer then
		print("armor: " .. dump(core.localplayer:get_armor_groups()))
		id = core.localplayer:hud_add({
				hud_elem_type = "text",
				name = "example",
				number = 0xff0000,
				position = {x=0, y=2},
				offset = {x=8, y=-8},
				text = "You are using the mxutil mod",
				scale = {x=200, y=60},
				alignment = {x=1, y=-1},
		})
	end
end)

core.register_on_modchannel_message(function(channel, sender, message)
	print("[mx][modchannels] Received message `" .. message .. "` on channel `"
			.. channel .. "` from sender `" .. sender .. "`")
	core.after(1, function()
		mod_channel:send_all("CSM mxutil received " .. message)
	end)
end)

core.register_on_modchannel_signal(function(channel, signal)
	print("[mx][modchannels] Received signal id `" .. signal .. "` on channel `"
			.. channel)
end)

core.register_on_inventory_open(function(inventory)
	print("[mx] INVENTORY OPEN")
	mxdata['inventory']=inventory
	--print(dump(inventory))
	return false
end)

core.register_on_placenode(function(pointed_thing, node)
	print("The local player place a node!")
	print("pointed_thing :" .. dump(pointed_thing))
	print("node placed :" .. dump(node))
	return false
end)

core.register_on_item_use(function(itemstack, pointed_thing)
	print("The local player used an item!")
	print("pointed_thing :" .. dump(pointed_thing))
	print("item = " .. itemstack:get_name())

	if not itemstack:is_empty() then
		return false
	end

	local pos = core.camera:get_pos()
	local pos2 = vector.add(pos, vector.multiply(core.camera:get_look_dir(), 100))

	local rc = core.raycast(pos, pos2)
	local i = rc:next()
	print("[mx] raycast next: " .. dump(i))
	if i and pos and i.above and i.under then
		print("[mx] line of sight: " .. (core.line_of_sight(pos, i.above) and "yes" or "no"))

		local n1 = core.find_nodes_in_area(pos, i.under, {"default:stone"})
		local n2 = core.find_nodes_in_area_under_air(pos, i.under, {"default:stone"})
		print(("[mx] found %s nodes, %s nodes under air"):format(
				n1 and #n1 or "?", n2 and #n2 or "?"))
	end

	return false
end)

-- This is an example function to ensure it's working properly, should be removed before merge
core.register_on_receiving_chat_message(function(message)
	print("[mx] Received message " .. message)
	return false
end)

-- This is an example function to ensure it's working properly, should be removed before merge
core.register_on_sending_chat_message(function(message)
	print("[mx] Sending message " .. message)
	return false
end)

core.register_on_chatcommand(function(command, params)
	print("[mx] caught command '"..command.."'. Parameters: '"..params.."'")
end)

-- This is an example function to ensure it's working properly, should be removed before merge
core.register_on_hp_modification(function(hp)
	print("[mx] HP modified " .. hp)
end)

-- This is an example function to ensure it's working properly, should be removed before merge
core.register_on_damage_taken(function(hp)
	print("[mx] Damage taken " .. hp)
end)

-- This is an example function to ensure it's working properly, should be removed before merge
core.register_chatcommand("dumpcore", {
	func = function(param)
		if param ~= "" then 
			log("frigtastic")
			return true, logdump(core)
		end
		return true, logdump(_G)
	end,
})
core.register_chatcommand("dump", {
	func = function(param)
		if param ~= "" then 
			log("frigtastic")
			return true, logdump(assert(loadstring(param))())
		end
		return true, logdump(_G)
	end,
})
core.register_chatcommand("pos",{
	func = function(param)
	local player=core.localplayer
	local pos=core.localplayer:get_pos()
	local str = math.floor(pos.x).. ',' .. math.floor(pos.y)..','..math.floor(pos.z)
	log("Current Position: " .. str)
	return true, str
	end
})


core.register_chatcommand("mx",{
	func = function(param)
		if param == "compass" then
			ls(minetest.settings:get("ccompass_teleport_nodes"))
		end
	end
})
core.register_chatcommand("ls", {
	func = function(param)
	
		if param ~= "" then 
			log("ls")
			return true, ls(assert(loadstring("return " .. param))() )
			
			-- I thought the CSM env was incredibly restrictive, turns out
			--  the loadstring is the one doing the restricting. 
			--  some things just can't be run in there
			--return true, ls(mxdata['inventory'][param])
			--return true, ls(minetest.localplayer:get_wield_index())
		end
		return true, ls(_G)
	end,
})
core.register_chatcommand("inventory", {
	func = function(param) 
		print(dump(mxdata['inventory']))
		--print(ls( core ))
	end
})
core.register_chatcommand("wieldinfo", {
	func = function(param) 
		--print(dump(mxdata['inventory']))
		print(dump( core.localplayer:get_wielded_item():to_table() ))  --this is userdata, I wonder if we always have a to_table() thatd be great
	end
})

local function mxutil_minimap()
	local minimap = core.ui.minimap
	if not minimap then
		print("[mx] Minimap is disabled. Skipping.")
		return
	end
	minimap:set_mode(4)
	minimap:show()
	minimap:set_pos({x=5, y=50, z=5})
	minimap:set_shape(math.random(0, 1))

	print("[mx] Minimap: mode => " .. dump(minimap:get_mode()) ..
			" position => " .. dump(minimap:get_pos()) ..
			" angle => " .. dump(minimap:get_angle()))
end

core.after(2, function()
	print("[mx] loaded " .. modname .. " mod")
	modstorage:set_string("current_mod", modname)
	assert(modstorage:get_string("current_mod") == modname)
	mxutil_minimap()
end)

core.after(5, function()
	if core.ui.minimap then
		core.ui.minimap:show()
	end

	print("[mx] Time of day " .. core.get_timeofday())

	print("[mx] Node level: " .. core.get_node_level({x=0, y=20, z=0}) ..
		" max level " .. core.get_node_max_level({x=0, y=20, z=0}))

	print("[mx] Find node near: " .. dump(core.find_node_near({x=0, y=20, z=0}, 10,
		{"group:tree", "default:dirt", "default:stone"})))
end)

core.register_on_dignode(function(pos, node)
	print("The local player dug a node!")
	print("\ndig pos: " .. dump(pos))
	print("node:" .. dump(node))
	return false
end)

core.register_on_punchnode(function(pos, node)
	print("The local player punched a node!")
	local itemstack = core.localplayer:get_wielded_item()
	print(dump(itemstack:to_table()))
	print("\npunch pos: " .. pos.x .."," .. pos.y ..",".. pos.z)
	print("node:" .. dump(node))
	local meta = core.get_meta(pos)
	print("punched meta: " .. (meta and dump(meta:to_table()) or "(missing)"))
	return false
end)

core.register_chatcommand("homew", {
	func = function(param)
		minetest.send_chat_message("/home")
	end,
})
core.register_chatcommand("privs", {
	func = function(param)
		print( core.privs_to_string(minetest.get_privilege_list()))
		return true, core.privs_to_string(minetest.get_privilege_list())
	end,
})

core.register_chatcommand("text", {
	func = function(param)
		return core.localplayer:hud_change(id, "text", param)
	end,
})


core.register_on_mods_loaded(function()
	core.log("Yeah mxutil mod is loaded with other CSM mods.")
end)
