/obj/structure/chemical_tank
	name = "remote chemical tank"
	desc = "A chemical tank that can be remotely connected to the chemical manufacturer."

	var/obj/item/circuit_component/chem/output/linked_output
	var/reagent_flags = TRANSPARENT | DRAINABLE
	var/buffer = 500

/obj/structure/chemical_tank/Initialize(mapload)
	. = ..()
	create_reagents(buffer, reagent_flags)

/obj/structure/chemical_tank/examine(mob/user)
	. = ..()
	. += span_notice("The maximum volume display reads: <b>[reagents.maximum_volume] units</b>.")
	if(linked_output)
		. += span_notice("Is connected to an output device.")

/obj/structure/chemical_tank/AltClick(mob/user)
	. = ..()
	if(!linked_output)
		linked_output = new(src.loc)
		linked_output.chemical_tank = src


/obj/item/circuit_component/chem/output
	display_name = "Tank Output"
	desc = "Linked to a physical object, sends the chemicals to the tank."

	circuit_flags = CIRCUIT_FLAG_INPUT_SIGNAL
	ui_buttons = list(
		"plus" = "add",
		"minus" = "remove"
	)

	var/list/chemical_inputs
	var/datum/port/input/heat_input

	var/obj/structure/chemical_tank/chemical_tank

/obj/item/circuit_component/chem/output/populate_ports()
	chemical_inputs = list()
	AddComponent(/datum/component/circuit_component_add_port, \
		port_list = chemical_inputs, \
		add_action = "add", \
		remove_action = "remove", \
		port_type = PORT_TYPE_ASSOC_LIST(PORT_TYPE_DATUM, PORT_TYPE_NUMBER), \
		prefix = "Chemical Input", \
		minimum_amount = 2 \
	)
	heat_input = add_input_port("Desired Heat", PORT_TYPE_NUMBER, default = 300)


/obj/item/circuit_component/chem/output/input_received(datum/port/input/port, list/return_values)
	if(!chemical_tank)
		return

	var/list/ports = chemical_inputs.Copy()
	var/list/chemical_list = list()
	var/sane_heat = clamp(heat_input.value, 4, 1000)

	for(var/datum/port/input/input_port as anything in ports)
		if(isnull(input_port.value))
			continue
		chemical_list += input_port.value

	chemical_tank.reagents.add_reagent_list(chemical_list, temperature = sane_heat)

/obj/item/circuit_component/chem/output/after_work_call()
	clear_all_temp_ports()
