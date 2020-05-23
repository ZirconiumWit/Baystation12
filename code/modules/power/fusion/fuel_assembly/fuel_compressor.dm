// 5 sheets == ~12500 matter units == ~100u reagents
// Try to avoid letting people produce more material
// with the kinetic harvester than they put into the
// field in the first place.

/obj/machinery/fusion_fuel_compressor
	name = "fuel compressor"
	icon = 'icons/obj/machines/power/fusion.dmi'
	icon_state = "fuel_compressor1"
	density = 1
	anchored = 1
	layer = 4
	construct_state = /decl/machine_construction/default/panel_closed

/obj/machinery/fusion_fuel_compressor/MouseDrop_T(var/atom/movable/target, var/mob/user)
	if(user.incapacitated() || !user.Adjacent(src))
		return
	return do_fuel_compression(target, user)

/obj/machinery/fusion_fuel_compressor/attackby(var/obj/item/thing, var/mob/user)
	return do_fuel_compression(thing, user) || ..()

/obj/machinery/fusion_fuel_compressor/proc/do_fuel_compression(var/obj/item/thing, var/mob/user)
	if(istype(thing) && thing.reagents && thing.reagents.total_volume && ATOM_IS_OPEN_CONTAINER(thing))
		if(LAZYLEN(thing.reagents.reagent_volumes) > 1)
			to_chat(user, "<span class='warning'>The contents of \the [thing] are impure and cannot be used as fuel.</span>")
			return 1
		if(thing.reagents.total_volume < 100)
			to_chat(user, "<span class='warning'>You need at least one hundred units of material to form a fuel rod.</span>")
			return 1
		var/decl/reagent/R = decls_repository.get_decl(thing.reagents.reagent_volumes[1])
		visible_message("<span class='notice'>\The [src] compresses the contents of \the [thing] into a new fuel assembly.</span>")
		var/obj/item/fuel_assembly/F = new(get_turf(src), R.type, R.color)
		thing.reagents.remove_reagent(R.type, 100)
		user.put_in_hands(F)
		return 1
	else if(istype(thing, /obj/machinery/power/supermatter/shard))
		var/obj/item/fuel_assembly/F = new(get_turf(src), MAT_SUPERMATTER)
		visible_message("<span class='notice'>\The [src] compresses the \[thing] into a new fuel assembly.</span>")
		qdel(thing)
		user.put_in_hands(F)
		return 1
	else if(istype(thing, /obj/item/stack/material))
		var/obj/item/stack/material/M = thing
		var/decl/material/mat = M.get_material()
		if(!mat.is_fusion_fuel)
			to_chat(user, "<span class='warning'>It would be pointless to make a fuel rod out of [mat.use_name].</span>")
			return
		if(!M.use(5))
			to_chat(user, "<span class='warning'>You need at least five [mat.sheet_plural_name] to make a fuel rod.</span>")
			return
		var/obj/item/fuel_assembly/F = new(get_turf(src), mat.type)
		visible_message("<span class='notice'>\The [src] compresses the [mat.use_name] into a new fuel assembly.</span>")
		user.put_in_hands(F)
		return 1
	return 0
