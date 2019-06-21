function(_graphviz_preamble)
	get_property(__GRAPH_FILENAME GLOBAL PROPERTY __BURAK_GRAPH_FILENAME)
	file(WRITE "${__GRAPH_FILENAME}" "digraph G {\n")
	
	_dumped_object_clear(INSTANCE)
	_dumped_object_clear(FEATUREBASE)
	_dumped_object_clear(FILE)	
endfunction()

function(_graphviz_epilogue)
	get_property(__GRAPH_FILENAME GLOBAL PROPERTY __BURAK_GRAPH_FILENAME)
	file(APPEND "${__GRAPH_FILENAME}" "}\n")
endfunction()

function(_dumped_instances_clear)
	set_property(GLOBAL PROPERTY __BURAK_DUMPED_INSTANCES "")
endfunction()

macro(_dumped_instances_exists __INSTANCE_ID __OUT_EXISTS)
	_dumped_object_exists(INSTANCE ${__INSTANCE_ID} ${__OUT_EXISTS})
endmacro()

macro(_dumped_featurebase_exists __FEATUREBASE_ID __OUT_EXISTS)
	_dumped_object_exists(FEATUREBASE ${__FEATUREBASE_ID} ${__OUT_EXISTS})
endmacro()

macro(_dumped_file_exists __FILEHASH __OUT_EXISTS)
	_dumped_object_exists(FILE ${__FILEHASH} ${__OUT_EXISTS})
endmacro()

function(_dumped_object_clear __OBJECT_TYPE)
	set_property(GLOBAL PROPERTY __BURAK_DUMPED_${__OBJECT_TYPE}S "")	
endfunction()

function(_dumped_object_exists __OBJECT_TYPE __KEY __OUT_EXISTS)
	get_property(__DUMPED_LIST GLOBAL PROPERTY __BURAK_DUMPED_${__OBJECT_TYPE}S)
	if("${__KEY}" IN_LIST __DUMPED_LIST)
		set(${__OUT_EXISTS} 1 PARENT_SCOPE)
	else()
		set(${__OUT_EXISTS} 0 PARENT_SCOPE)
	endif()
endfunction()

function(_dumped_object_add __OBJECT_TYPE __KEY)
	get_property(__DUMPED_OBJECTS GLOBAL PROPERTY __BURAK_DUMPED_${__OBJECT_TYPE}S)
	list(APPEND __DUMPED_OBJECTS "${__KEY}")
	set_property(GLOBAL PROPERTY __BURAK_DUMPED_${__OBJECT_TYPE}S ${__DUMPED_OBJECTS})
endfunction()

function(_dump_instance __INSTANCE_ID)
	_dumped_instances_exists(${__INSTANCE_ID} __ALREADY_DONE)
	if(__ALREADY_DONE)
		return()
	endif()
	_dumped_object_add(INSTANCE ${__INSTANCE_ID})
	
	#TO Include inside the box:
	#PROMISE_PARAMS   - List of parameters that matching target must match in order to satisfy our promise
	#LINKPARS         - Serialized list of link parameters that are passed to that instance. 
	
	_retrieve_instance_args(${__INSTANCE_ID} PROMISE_PARAMS __PARAMS)
	_pretty_print_args(__PARAMS 16 __OUT1)
	_retrieve_instance_args(${__INSTANCE_ID} LINKPARS __LINKPARAMS)
	_pretty_print_args(__LINKPARAMS 16 __OUT2)
	_retrieve_instance_data(${__INSTANCE_ID} WAS_PROMISE __WAS_PROMISE)
	_retrieve_instance_data(${__INSTANCE_ID} I_TARGET_NAME __TARGET_NAME)
	_retrieve_instance_data(${__INSTANCE_ID} FEATUREBASE __FEATUREBASE_ID)
	if(__WAS_PROMISE)
		set(__DASHES ", style=dashed")
	else()
		set(__DASHES )
	endif()
	if(NOT "${__TARGET_NAME}" STREQUAL "")
		set(__XLABEL ", xlabel=\"${__TARGET_NAME}\"")
	else()
		set(__XLABEL )
	endif()
	
	get_property(__GRAPH_FILENAME GLOBAL PROPERTY __BURAK_GRAPH_FILENAME)
	
	#Format: {bold - instanceid | pars | italic: linkpars}
	
	file(APPEND "${__GRAPH_FILENAME}" "i${__INSTANCE_ID} [shape=Mrecord${__DASHES}${__XLABEL}, label=< <TABLE BORDER=\"0\" CELLBORDER=\"0\" CELLSPACING=\"0\" ><TR><TD><B>${__INSTANCE_ID}</B></TD></TR><TR><TD> ${__OUT1} </TD></TR><TR><TD> <I> ${__OUT2}  </I> </TD></TR> </TABLE> >]\n")
	
	_dump_featurebase(${__FEATUREBASE_ID})
	file(APPEND "${__GRAPH_FILENAME}" "i${__INSTANCE_ID} -> t${__FEATUREBASE_ID} [style=bold, arrowhead=none${__DASHES}]\n")
endfunction()

function(_dump_featurebase __FEATUREBASE_ID)
	_dumped_featurebase_exists(${__FEATUREBASE_ID} __ALREADY_DONE)
	if(__ALREADY_DONE)
		return()
	endif()
	_dumped_object_add(FEATUREBASE ${__FEATUREBASE_ID})

	#TO Include inside the box:
	#PROMISE_PARAMS   - List of parameters that matching target must match in order to satisfy our promise
	#LINKPARS         - Serialized list of link parameters that are passed to that instance. 
	
	_retrieve_featurebase_args(${__FEATUREBASE_ID} MODIFIERS __PARAMS)
	_pretty_print_args(__PARAMS 16 __OUT1)
	_retrieve_featurebase_args(${__FEATUREBASE_ID} F_FEATURES __FEATURES)
	_pretty_print_args(__FEATURES 16 __OUT2)
	_retrieve_featurebase_data(${__FEATUREBASE_ID} F_PATH __PATH)
	
	
	get_property(__GRAPH_FILENAME GLOBAL PROPERTY __BURAK_GRAPH_FILENAME)
	
	#Format: {bold - featurebase | pars | italic: linkpars}
	
	#TODO: Wstaw linię, która odgraniczy pars od features
	file(APPEND "${__GRAPH_FILENAME}" "t${__FEATUREBASE_ID} [shape=Mrecord, label=< <TABLE BORDER=\"0\" CELLBORDER=\"0\" CELLSPACING=\"0\" ><TR><TD>${__INSTANCE_ID}</TD></TR><TR><TD> ${__OUT1} </TD></TR><TR><TD> ${__OUT2}  </TD></TR> </TABLE> >]\n")
	
	_retrieve_featurebase_data(${__FEATUREBASE_ID} DEP_INSTANCES __DEPENDENCIES)
	foreach(__INSTANCE_ID IN LISTS __DEPENDENCIES)
		_dump_instance("${__INSTANCE_ID}")
		file(APPEND "${__GRAPH_FILENAME}" "t${__FEATUREBASE_ID} -> i${__INSTANCE_ID}\n")
	endforeach()
	_make_path_hash("${__PATH}" __FILEHASH)
	_dump_file("${__PATH}")
	file(APPEND "${__GRAPH_FILENAME}" "t${__FEATUREBASE_ID} -> p${__FILEHASH} [style=bold, arrowhead=none]\n")
	
endfunction()

function(_dump_file __PATH)
	_dumped_file_exists(${__FILEHASH} __ALREADY_DONE)
	if(__ALREADY_DONE)
		return()
	endif()
	_dumped_object_add(FILE ${__FILEHASH})
	_get_relative_path("${__PATH}" __RELPATH)
	
	#TO Include inside the box:
	#filename (relative to the superbuild root)
	
	get_property(__GRAPH_FILENAME GLOBAL PROPERTY __BURAK_GRAPH_FILENAME)
	
	file(APPEND "${__GRAPH_FILENAME}" "p${__FILEHASH} [shape=note, label=\"${__RELPATH}\"]\n")
endfunction()


#The most important thing it does is to make sure the line width is not exceeded.
function(_pretty_print_args __ARGS_REF __MAX_WIDTH __OUT_TXT)
	set(__OUT)
	set(__OUT_LINE)
	set(__CUR_WIDTH 0)
	foreach(__ARG IN LISTS ${__ARGS_REF})
		set(__TOKEN "${__ARG}=${${__ARGS_REF}_${__ARG}}")
		string(LENGTH "${__TOKEN}" __STRLEN)
		math(EXPR __NEW_WIDTH "${__CUR_WIDTH}+${__STRLEN}")
		if(${__NEW_WIDTH} GREATER ${__MAX_WIDTH} AND NOT "${__OUT_LINE}" STREQUAL "")
			if(NOT "${__OUT}" STREQUAL "")
				set(__OUT "${__OUT}</TD></TR><TR><TD>")
			endif()
			set(__OUT "${__OUT}${__OUT_LINE}")
			set(__OUT_LINE)
		endif()
		if(NOT "${__OUT_LINE}" STREQUAL "")
			set(__OUT_LINE "${__OUT_LINE} ")
		endif()
		set(__OUT_LINE "${__OUT_LINE}${__TOKEN}")
	endforeach()
	if(NOT "${__OUT_LINE}" STREQUAL "")
		set(__OUT "${__OUT}</TD></TR><TR><TD>${__OUT_LINE}")
	endif()
	set(${__OUT_TXT} "${__OUT}" PARENT_SCOPE)
endfunction()
