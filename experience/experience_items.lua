minetest.register_craftitem("experience:small_experience_orb", {
	description = "Minor Experience Orb",
	inventory_image = "experience_small_experience_orb.png",
	on_use = function(itemstack, user, pointed_thing)
		add_experience(user, 10)
		itemstack:take_item()
		return itemstack
	end,
})

minetest.register_craftitem("experience:medium_experience_orb", {
	description = "Experience Orb",
	inventory_image = "experience_medium_experience_orb.png",
	on_use = function(itemstack, user, pointed_thing)
		add_experience(user, 25)
		itemstack:take_item()
		return itemstack
	end,
})

minetest.register_craftitem("experience:large_experience_orb", {
	description = "Major Experience Orb",
	inventory_image = "experience_large_experience_orb.png",
	on_use = function(itemstack, user, pointed_thing)
		add_experience(user, 100)
		itemstack:take_item()
		return itemstack
	end,
})