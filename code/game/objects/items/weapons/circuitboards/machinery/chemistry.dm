/obj/item/stock_parts/circuitboard/reagent_heater
	name = T_BOARD("chemical heater")
	build_path = /obj/machinery/reagent_temperature
	board_type = "machine"
	origin_tech = list(TECH_POWER = 2, TECH_ENGINEERING = 1)
	req_components = list(
		/obj/item/stock_parts/micro_laser = 1,
		/obj/item/stock_parts/capacitor = 1
	)
	additional_spawn_components = list(
		/obj/item/stock_parts/console_screen = 1,
		/obj/item/stock_parts/keyboard = 1,
		/obj/item/stock_parts/power/apc/buildable = 1
	)

/obj/item/stock_parts/circuitboard/reagent_heater/cooler
	name = T_BOARD("chemical cooler")
	build_path = /obj/machinery/reagent_temperature/cooler
