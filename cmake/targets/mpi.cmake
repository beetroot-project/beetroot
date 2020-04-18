set(ENUM_TARGETS OpenMP::OpenMP_FORTRAN OpenMP::OpenMP_CXX)

set(FILE_OPTIONS
	NICE_NAME "MPI library"
)

set(DEFINE_EXTERNAL_PROJECT 
	ASSUME_INSTALLED
	NAME OpenMP
	APT_PACKAGES mpi-default-dev
	SPACK_PACKAGES openmpi
)

function(generate_targets TARGET_NAME TEMPLATE_NAME)
   find_package(${EP_NAME}) 
endfunction()

