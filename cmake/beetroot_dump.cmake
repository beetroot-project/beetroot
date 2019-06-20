function(_dumped_instances_clear)
	set_property(GLOBAL PROPERTY __BURAK_DUMPED_INSTANCES "")
endfunction()

function(_dumped_instances_exists __INSTANCE_ID __OUT_EXISTS)
	get_property(__DUMPED_INSTANCES GLOBAL PROPERTY __BURAK_DUMPED_INSTANCES)
	if("${__INSTANCE_ID}" IN_LIST __DUMPED_INSTANCES)
		set(${__OUT_EXISTS} 1 PARENT_SCOPE)
	else()
		set(${__OUT_EXISTS} 0 PARENT_SCOPE)
	endif()
endfunction()

function(_dumped_instances_add __INSTANCE_ID)
	get_property(__DUMPED_INSTANCES GLOBAL PROPERTY __BURAK_DUMPED_INSTANCES)
	list(APPEND __DUMPED_INSTANCES "${__INSTANCE_ID}")
	set_property(GLOBAL PROPERTY __BURAK_DUMPED_INSTANCES ${__DUMPED_INSTANCES})
endfunction()

function(_dump_instance __INSTANCE_ID)
	_dumped_instances_exists(${__INSTANCE_ID} __ALREADY_DONE)
	if(NOT __ALREADY_DONE)
		return()
	endif()
	
	
endfunction()
