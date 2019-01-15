set(DEFINE_MODIFIERS 
	BLA	SCALAR	STRING	"${WYBOR}-EK"
	WYBOR SCALAR "CHOICE(BLA:BLU:BLI)" "BLI"
	LIBKTO SCALAR STRING "Tata"
#	OPCJA	OPTION	"" 0
#	PRECISION	SCALAR	INTEGER 4
#	PATH	SCALAR	PATH "Taka sobie ścieżka"
#	COMPONENTS	VECTOR	STRING	"filesystem;log"
#	ARCH	SCALAR	CHOICE(GPU;CPU) CPU
#	KILKA_Z_WIELU	VECTOR	CHOICE(RAZ;DWA;TRZY;CZTERY) "DWA;CZTERY"
)
set(DEFINE_PARAMETERS 
	NONSIGINIFICANT	SCALAR	STRING	"foo"
)
set(ENUM_TARGETS fiksik)

#function(declare_dependencies TEMPLATE_NAME)
#	build_target(LIBHELLO KTO ${LIBKTO})
#endfunction()

function(generate_targets TEMPLATE_NAME)
	message(WARNING "Inside fiksik generate_targets trying to define ${HELLO_TARGET_NAME} with BLA=${BLA}")
	add_executable(fiksik "${CMAKE_CURRENT_SOURCE_DIR}/source.cpp")
	target_compile_definitions(fiksik PRIVATE "BLA=${BLA}")
endfunction()

