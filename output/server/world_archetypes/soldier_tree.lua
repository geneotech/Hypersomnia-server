is_alert_archetype = {
	node_type = behaviour_node.SELECTOR,
	on_update = function(entity)
		if entity.script.npc.was_seen then
			return behaviour_node.SUCCESS 
		end
		return behaviour_node.FAILURE
	end
}

has_a_weapon_archetype = {
	on_update = function(entity)
		local selected = entity.script.npc:get_selected_item()
		if selected and selected.weapon then
			return behaviour_node.SUCCESS
		end
		return behaviour_node.FAILURE
	end
}

escape_archetype = {
	on_enter = function(entity, task)
		task:interrupt_other_runner(behaviour_node.FAILURE)
		print "entering escape"
		entity.script.npc:start_escape()
	end,
	
	on_update = function(entity)
		entity.script.npc:update_escape()
		return behaviour_node.RUNNING
	end,
	
	on_exit = function(entity, status)
		print "exiting escape"
		entity.script.npc:stop_escape()
	end
}

npc_legs_behaviour_tree = create_behaviour_tree {	
	nodes = {
		legs = {
			node_type = behaviour_node.SELECTOR,
			default_return = behaviour_node.SUCCESS,
			skip_to_running_child = 0
		},
		
		
		get_needed_items = {
			on_update = function(entity, task) 
				local owner_entity_system = entity.script.owner_entity_system
				local npc = entity.script.npc
				
				local item_of_interest = npc:get_closest_needed_item()
				
				if item_of_interest then
					local item_in_range = entity.script.owner_entity_system.all_systems["inventory"]:get_item_in_range(npc.entity, item_of_interest.cpp_entity)
					
					if item_in_range then
						npc:pick(item_in_range)
						print "success picked!"
						return behaviour_node.SUCCESS
					else
						task:interrupt_other_runner(behaviour_node.FAILURE)
						-- out of range, will pick up later on
						npc:pursue_target(item_of_interest)
						npc:update_avoidance()
						return behaviour_node.RUNNING
					end
				else
					-- no items of interest
					return behaviour_node.FAILURE
				end
			end,
			
			on_exit = function(entity, code)
				print "exiting get_needed_items"
				entity.script.npc:stop_pursuit()
				entity.script.npc:exit_avoidance()
			end
		},
		is_alert = clone_table(is_alert_archetype),
		
		player_visible = {
			node_type = behaviour_node.SELECTOR,
			on_update = function(entity) 
				if entity.script.npc.is_seen then
					return behaviour_node.SUCCESS
				else
					return behaviour_node.FAILURE
				end
			end
		},
		
		gun_strategy = {
			on_update = function(entity, task)
				local npc = entity.script.npc
				local selected = npc:get_selected_item()
				
				-- if the hand intelligence picked a gun
				if selected and selected.weapon and selected.weapon.current_rounds > 0 then
					task:interrupt_other_runner(behaviour_node.FAILURE)
					npc:stop_pursuit()
					npc.steering_behaviours.wandering.weight_multiplier = 2.0
					return behaviour_node.RUNNING
				end
				return behaviour_node.FAILURE
			end,
			
			on_exit = function(entity, code)
				print "exiting gun_strategy"
				entity.script.npc.steering_behaviours.wandering.weight_multiplier = 1.0
			end
		},
		
		melee_strategy = {
			on_update = function(entity, task)
				local npc = entity.script.npc
				local selected = npc:get_selected_item()
				
				if selected and selected.weapon then
					task:interrupt_other_runner(behaviour_node.FAILURE)
					npc:pursue_target(npc.closest_enemy)
				
					return behaviour_node.RUNNING
				end
				
				return behaviour_node.FAILURE
			end,
			
			on_exit = function(entity, status)
				print "exiting melee_strategy"
				entity.script.npc:stop_pursuit()
			end
		},
		
		evade = clone_table(escape_archetype),
		escape = clone_table(escape_archetype),
		
		has_a_weapon = clone_table(has_a_weapon_archetype),
		
		is_alert = {
			skip_to_running_child = 0,
			node_type = behaviour_node.SELECTOR,
			
			on_update = function(entity)
				if entity.script.npc.was_seen then
					return behaviour_node.SUCCESS 
				end
				return behaviour_node.FAILURE
			end
		},
		
		go_to_last_seen = {
			on_enter = function(entity, task)
				task:interrupt_other_runner(behaviour_node.FAILURE)
				
				local npc = entity.script.npc
				
				local target_point_pushed_away = 
					npc.owner.owner_entity_system.all_systems.npc.world_object.physics_system
					:push_away_from_walls(npc.last_seen, 100, 10, create_query_filter({ "STATIC_OBJECT" }), entity)
					
				npc.last_seen = target_point_pushed_away
				
				entity.pathfinding:start_pathfinding(target_point_pushed_away)
			end,
			
			on_update = function(entity)
				if entity.pathfinding:is_still_pathfinding() then return behaviour_node.RUNNING end
				return behaviour_node.SUCCESS 
			end,
			
			on_exit = function(entity, status)
				print "exiting go_to_last_seen"
				entity.script.npc:exit_pathfinding()
			end
		},
		
		follow_hint = {
			default_return = behaviour_node.RUNNING,
			
			on_enter = function(entity, task)
				task:interrupt_other_runner(behaviour_node.FAILURE)
				local npc = entity.script.npc
			
				entity.pathfinding.custom_exploration_hint.origin = npc.last_seen
				entity.pathfinding.custom_exploration_hint.target = npc.last_seen + npc.last_seen_vel
				
				entity.pathfinding.favor_velocity_parallellness = true
				entity.pathfinding.custom_exploration_hint.enabled = true
				entity.pathfinding:start_exploring()
			end,
			
			on_exit = function(entity, status)
				print "exiting follow_hint"
				entity.script.npc:exit_pathfinding()
			end
		},
		
		walk_around = {
			default_return = behaviour_node.RUNNING,
			
			on_enter = function(entity, task)
				task:interrupt_other_runner(behaviour_node.FAILURE)
				local npc = entity.script.npc
				npc:start_patrol()
			end,
			
			on_exit = function(entity, status)
				print "exiting walk_around"
				entity.script.npc:exit_patrol()
			end
		}
	},
	
	connections = {
		legs = {
			"get_needed_items", "player_visible", "is_alert", "walk_around"
		},

		player_visible = {
			"gun_strategy", "melee_strategy", "evade"
		},
		
		is_alert = {
			"has_a_weapon", "escape" 	
		},
		
		has_a_weapon = {
			"go_to_last_seen", "follow_hint"
		}
	},
	
	root = "legs"
}


--npc_hands_behaviour_tree = create_behaviour_tree {
--	decorators = {},
--	
--	nodes = {
--		hands = {
--			node_type = behaviour_node.SEQUENCER,
--			default_return = behaviour_node.SUCCESS
--		},
--		
--		player_visible = {
--			on_update = function(entity) 
--				if get_scripted(entity).is_seen then 
--					return behaviour_node.SUCCESS
--				end
--				return behaviour_node.FAILURE
--			end
--		},
--		
--		anything_in_hands = archetyped(anything_in_hands_archetype, { node_type = behaviour_node.SELECTOR, skip_to_running_child = 0 }),
--		
--		melee_range = {
--			on_update = function(entity) 
--				if player.body:exists() then 
--					if (player.body:get().transform.current.pos - entity.transform.current.pos):length() < 100 then
--						entity.gun.trigger_mode = gun_component.MELEE
--						return behaviour_node.RUNNING
--					end
--				end
--				return behaviour_node.FAILURE
--			end,
--			
--			on_exit = function(entity) 
--				entity.gun.trigger_mode = gun_component.NONE
--			end
--			
--		},
--		
--		try_to_shoot = {
--			on_update = function(entity) 
--				if entity.gun.current_rounds > 0 then
--					entity.gun.trigger_mode = gun_component.SHOOT
--					return behaviour_node.RUNNING
--				end
--				
--				return behaviour_node.FAILURE
--			end,
--			
--			on_exit = function(entity) 
--				entity.gun.trigger_mode = gun_component.NONE
--			end
--		},
--	},
--	
--	connections = {
--		hands = {
--			"player_visible", "anything_in_hands"
--		},
--		
--		anything_in_hands = {
--			"melee_range", "try_to_shoot"
--		}
--	},
--	
--	root = "hands"
--}