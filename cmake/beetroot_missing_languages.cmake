function(missing_language __LANG __REQUIRED_BY)
   if("${__LANG}" STREQUAL "Fortran")
		missing_dependency(
			DESCRIPTION "Fortran compiler"
			REQUIRED_BY "${__REQUIRED_BY}"
			SPACK_PACKAGES gcc
			APT_PACKAGES gfortran
		)
	elseif("${__LANG}" STREQUAL "CUDA")
		missing_dependency(
			DESCRIPTION "CUDA framework"
			REQUIRED_BY "${__REQUIRED_BY}"
			SPACK_PACKAGES cuda
			APT_PACKAGES cuda
		)
	elseif("${__LANG}" STREQUAL "CXX")
		missing_dependency(
			DESCRIPTION "C++"
			REQUIRED_BY "${__REQUIRED_BY}"
			SPACK_PACKAGES gcc
			APT_PACKAGES gcc
		)
   else()
      message("FATAL_ERROR" "Internal Beetroot error: Unknown language ${__LANG}. Current version of Beetroot does not support unknown CMake languages.")
   endif()
endfunction()
