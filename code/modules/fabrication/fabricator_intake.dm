#define SUBSTANCE_TAKEN_NONE -1
#define SUBSTANCE_TAKEN_SOME  0
#define SUBSTANCE_TAKEN_FULL  1
#define SUBSTANCE_TAKEN_ALL   2

/obj/machinery/fabricator/proc/take_reagents(var/obj/item/thing, var/mob/user, var/destructive = FALSE)
	if(!thing.reagents || (!destructive && !ATOM_IS_OPEN_CONTAINER(thing)))
		return SUBSTANCE_TAKEN_NONE
	for(var/R in thing.reagents.reagent_volumes)
		if(!base_storage_capacity[R])
			continue
		var/taking_reagent = min(REAGENT_VOLUME(thing.reagents, R), storage_capacity[R] - stored_material[R])
		if(taking_reagent <= 0)
			continue
		thing.reagents.remove_reagent(R, taking_reagent)
		stored_material[R] += taking_reagent
		// If we're destroying this, take everything.
		if(destructive)
			. = SUBSTANCE_TAKEN_ALL
			continue
		// Otherwise take the first applicable and useful reagent.
		if(stored_material[R] == storage_capacity[R])
			return SUBSTANCE_TAKEN_FULL
		else if(thing.reagents.total_volume > 0)
			return SUBSTANCE_TAKEN_SOME
		else
			return SUBSTANCE_TAKEN_ALL
	return SUBSTANCE_TAKEN_NONE

/obj/machinery/fabricator/proc/take_materials(var/obj/item/thing, var/mob/user)
	. = SUBSTANCE_TAKEN_NONE
	var/stacks_used = 1
	var/mat_colour = thing.color
	for(var/mat in thing.matter)
		var/decl/material/material_def = SSmaterials.get_material_datum(mat)
		if(!material_def || !base_storage_capacity[material_def.type])
			continue
		var/taking_material = min(thing.matter[mat], storage_capacity[material_def.type] - stored_material[material_def.type])
		if(taking_material <= 0)
			continue
		if(!mat_colour)
			mat_colour = material_def.icon_colour
		stored_material[material_def.type] += taking_material
		stacks_used = max(stacks_used, ceil(taking_material/SHEET_MATERIAL_AMOUNT))
		if(storage_capacity[material_def.type] == stored_material[material_def.type])
			. = SUBSTANCE_TAKEN_FULL
		else if(. != SUBSTANCE_TAKEN_FULL)
			. = SUBSTANCE_TAKEN_ALL
	if(. != SUBSTANCE_TAKEN_NONE)
		if(mat_colour)
			var/image/adding_mat_overlay = image(icon, "[base_icon_state]_mat")
			adding_mat_overlay.color = mat_colour
			material_overlays += adding_mat_overlay
			update_icon()
			addtimer(CALLBACK(src, /obj/machinery/fabricator/proc/remove_mat_overlay, adding_mat_overlay), 1 SECOND)
		if(istype(thing, /obj/item/stack))
			var/obj/item/stack/S = thing
			S.use(stacks_used)
			if(S.amount <= 0 || QDELETED(S))
				. = SUBSTANCE_TAKEN_ALL
			else if(. != SUBSTANCE_TAKEN_FULL)
				. = SUBSTANCE_TAKEN_SOME

/obj/machinery/fabricator/proc/show_intake_message(var/mob/user, var/value, var/obj/item/thing)
	if(value == SUBSTANCE_TAKEN_FULL)
		to_chat(user, SPAN_NOTICE("You fill \the [src] to capacity with \the [thing]."))
	else if(value == SUBSTANCE_TAKEN_SOME)
		to_chat(user, SPAN_NOTICE("You fill \the [src] from \the [thing]."))
	else if(value == SUBSTANCE_TAKEN_ALL)
		to_chat(user, SPAN_NOTICE("You dump \the [thing] into \the [src]."))
	else
		to_chat(user, SPAN_WARNING("\The [src] cannot process \the [thing]."))

/obj/machinery/fabricator/attackby(var/obj/item/O, var/mob/user)
	if(component_attackby(O, user))
		return TRUE
	if(panel_open && (isMultitool(O) || isWirecutter(O)))
		attack_hand(user)
		return TRUE
	if((obj_flags & OBJ_FLAG_ANCHORABLE) && isWrench(O))
		return ..()
	if(stat & (NOPOWER | BROKEN))
		return

	// Gate some simple interactions beind intent so people can still feed lathes disks.
	if(user.a_intent != I_HURT)

		// Set or update our local network.
		if(isMultitool(O))
			var/datum/extension/local_network_member/fabnet = get_extension(src, /datum/extension/local_network_member)
			fabnet.get_new_tag(user)
			return

		// Install new designs.
		if(istype(O, /obj/item/disk/design_disk))
			var/obj/item/disk/design_disk/disk = O
			if(!disk.blueprint)
				to_chat(usr, SPAN_WARNING("\The [O] is blank."))
				return
			if(disk.blueprint in installed_designs)
				to_chat(usr, SPAN_WARNING("\The [src] is already loaded with the blueprint stored on \the [O]."))
				return
			installed_designs += disk.blueprint
			design_cache |= disk.blueprint
			visible_message(SPAN_NOTICE("\The [user] inserts \the [O] into \the [src], and after a second or so of loud clicking, the fabricator beeps and spits it out again."))
			return

	// Take reagents, if any are applicable.
	var/reagents_taken = take_reagents(O, user)
	if(reagents_taken != SUBSTANCE_TAKEN_NONE && !has_recycler)
		show_intake_message(user, reagents_taken, O)
		updateUsrDialog()
		return TRUE
	// Take everything if we have a recycler.
	if(has_recycler && !is_robot_module(O) && user.unEquip(O))
		var/result = max(take_materials(O, user), max(reagents_taken, take_reagents(O, user, TRUE)))
		show_intake_message(user, result, O)
		if(result == SUBSTANCE_TAKEN_NONE)
			user.put_in_active_hand(O)
			return TRUE
		if(istype(O, /obj/item/stack))
			var/obj/item/stack/stack = O
			if(!QDELETED(stack) && stack.amount > 0)
				user.put_in_active_hand(stack)
		else
			qdel(O)
		updateUsrDialog()
		return TRUE
	. = ..()

/obj/machinery/fabricator/physical_attack_hand(mob/user)
	if(fab_status_flags & FAB_SHOCKED)
		shock(user, 50)
		return TRUE

/obj/machinery/fabricator/interface_interact(mob/user)
	if((fab_status_flags & FAB_DISABLED) && !panel_open)
		to_chat(user, SPAN_WARNING("\The [src] is disabled!"))
		return TRUE
	interact(user)
	return TRUE

#undef SUBSTANCE_TAKEN_FULL
#undef SUBSTANCE_TAKEN_NONE
#undef SUBSTANCE_TAKEN_SOME
#undef SUBSTANCE_TAKEN_ALL