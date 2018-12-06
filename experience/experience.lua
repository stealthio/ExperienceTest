EXP_STORAGE = minetest.get_mod_storage()

local huds = {}

local dig_experience_table = {
	["default:dirt"] = 0,
	["default:dirt_with_snow"] = 0,
	["default:torch"] = 0,
	["default:tree"] = 2,
	["default:pine_tree"] = 2,
	["default:stone_with_coal"] = 3,
	["default:stone_with_copper"] = 5,
	["default:stone_with_iron"] = 7,
	["default:stone_with_gold"] = 10,
	["default:stone_with_diamond"] = 20,
	["default:stone_with_mese"] = 50
}

minetest.register_chatcommand("set_level", {
	params = "<player> <value>",
	description = "Sets the players level to the given value",
	func = function(name, param)
		local playername, value = string.match(param, "([^ ]+) (-?%d+)")
		if not playername or not value then
			return false, ("* Insufficient or wrong parameters")
		end
		
		local player = minetest.get_player_by_name(playername)
		if not player then
			return false, ("* Player" .. playername .. "not found")
		end
		local meta = player:get_meta()
		meta:set_int("level", value)
		update_hud(player)
		return true, "* " .. playername .. ("'s level set to") .. value
		end,
})

minetest.register_on_newplayer(function(player)
	if not player then
		return
	end
	
	local meta = player:get_meta()
	meta:set_int("experience", 0)
	meta:set_int("level", 1)
end)

minetest.register_on_joinplayer(function(player)
	if not player then
		return
	end
	
	load_from_file(player)
	
	local meta = player:get_meta()
	local experience_text = "Experience: " .. meta:get_int("experience") .. "/" .. get_required_experience(player)
	local level_text = "Level: " .. meta:get_int("level")
	
	local experience_display = player:hud_add({
		hud_elem_type = "text",
		position = {x = 1, y = 0.75},
		offset = {x = -120, y = -25},
		text = experience_text,
		alignment = -1,
		scale = {x = 150, y = 30},
		number = 0xFFFFFFF,
	})
	
	local level_display = player:hud_add({
		hud_elem_type = "text",
		position = {x = 1, y = 0.75},
		offset = {x = -120, y = 25},
		text = level_text,
		alignment = -1,
		scale = {x = 150, y = 30},
		number = 0xFFFFFFF,
	})
	
	huds[player:get_player_name() .. "_exp"] = experience_display
	huds[player:get_player_name() .. "_lvl"] = level_display
end)

minetest.register_on_dieplayer(function(player)
	if not player then
		return
	end
	
	local meta = player:get_meta()
	local currExp = meta:get_int("experience")
	meta:set_int("experience", math.floor(currExp / 2))
	update_hud(player)
end)

minetest.register_on_leaveplayer(function(player)
	save_to_file(player)
	huds[player:get_player_name() .. "_exp"] = nil
	huds[player:get_player_name() .. "_lvl"] = nil
end)

function save_to_file(player)
	if not player then
		return
	end

	local meta = player:get_meta()
	EXP_STORAGE:set_int(player:get_player_name().."_exp", meta:get_int("experience"))
	EXP_STORAGE:set_int(player:get_player_name().."_lvl", meta:get_int("level"))
end

function load_from_file(player)
	if not player then
		return
	end

	local meta = player:get_meta()
	local exp = EXP_STORAGE:get_int(player:get_player_name().."_exp")
	local lvl = EXP_STORAGE:get_int(player:get_player_name().."_lvl")
	if exp then
		meta:set_int("experience", exp)
	else 
		meta:set_int("experience", 0)
	end
	if lvl then
		meta:set_int("level", lvl)
	else
		meta:set_int("level", 1)
	end
end

function update_hud(player)
	if not player then
		return
	end
	
	local player_name = player:get_player_name()
	local meta = player:get_meta()
	local experience_text = "Experience: " .. meta:get_int("experience") .. "/" .. get_required_experience(player)
	local level_text = "Level: " .. meta:get_int("level")
	
	local exp_display = huds[player_name .. "_exp"]
	if exp_display then
		player:hud_change(exp_display, "text", experience_text)
	else
		exp_display = {}
		huds[player_name .. "_exp"] = exp_display
	end
	
	local lvl_display = huds[player_name .. "_lvl"]
	if lvl_display then
		player:hud_change(lvl_display, "text", level_text)
	else
		lvl_display = {}
		huds[player_name .. "_lvl"] = lvl_display
	end
end

function add_experience(player, amount)
	if not player then
		return
	end
	
	local meta = player:get_meta()
	local oldExp = meta:get_int("experience")
	meta:set_int("experience", oldExp + amount)
	
	if (meta:get_int("experience") > get_required_experience(player)) then
		level_up(player)
	end
	update_hud(player)
end

function level_up(player)
	if not player then
		return
	end
	local meta = player:get_meta()
	meta:set_int("experience", meta:get_int("experience") - get_required_experience(player))
	meta:set_int("level", meta:get_int("level") + 1)
	
	minetest.show_formspec(player:get_player_name(), "experience:levelup_dialogue",
		"size[5,5]"..
		"button_exit[0,0;5,1;armor;Damage resistance]"..
		"button_exit[0,1;5,1;health;Health upgrade]"..
		"button_exit[0,2;5,1;jump;Jump upgrade]"..
		"button_exit[0,3;5,1;speed;Speed upgrade]"..
		"button_exit[0,4;5,1;exit;Skip]")
	
	save_to_file(player)
end

minetest.register_on_player_receive_fields(function(player,formname,fields)
    if formname~="experience:levelup_dialogue" then
        return false
    end
    if fields['health'] then
        raisehealth(player)
    elseif fields['speed'] then
        raisespeed(player)
    elseif fields['jump'] then
        raisejump(player)
    elseif fields['armor'] then
        raisearmor(player)
    end
    return true
end)

function raisearmor(player)
    local armor=EXP_STORAGE:get_float(player:get_player_name()..'_armor')
    EXP_STORAGE:set_float(player:get_player_name()..'_armor',armor+.25)
end

function raisespeed(player)
    local p=player:get_physics_override()
    p.speed=p.speed+0.2
    player:set_physics_override(p)
    EXP_STORAGE:set_float(player:get_player_name()..'_speed_override',p.speed)
end

function raisejump(player)
    local p=player:get_physics_override()
    p.jump=p.jump+0.25
    player:set_physics_override(p)
    EXP_STORAGE:set_float(player:get_player_name()..'_jump_override',p.jump)
end

function raisehealth(player)
    local newhp=tonumber(player:get_properties()['hp_max'])+2
    if newhp>20 then
        newhp=20
    end
    player:set_properties({hp_max=newhp,})
    EXP_STORAGE:set_float(player:get_player_name()..'_health_override',newhp)
end

function get_required_experience(player)
	if not player then
		return
	end
	
	local meta = player:get_meta()
	local required_exp = (meta:get_int("level") * 5) * meta:get_int("level")
	return required_exp
end

minetest.register_on_dignode(function(pos, oldnode, digger)
	if not digger then
		return
	end
	local exp_to_gain = dig_experience_table[oldnode.name]
	if not exp_to_gain then
		exp_to_gain = 1
	end
	add_experience(digger, exp_to_gain)
end)