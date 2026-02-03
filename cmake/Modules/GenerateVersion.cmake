# cmake/Modules/GenerateVersion.cmake
# Generates cmake_config_githash.h from cmake_config_githash.h.in

# Required inputs (passed via -D)
#  - GENERATE_VERSION_SOURCE_DIR
#  - GENERATE_VERSION_BINARY_DIR
#  - VERSION_STRING
# Optional:
#  - DEVELOPMENT_BUILD (TRUE/FALSE)

if(NOT DEFINED GENERATE_VERSION_SOURCE_DIR OR NOT DEFINED GENERATE_VERSION_BINARY_DIR)
	message(FATAL_ERROR "GenerateVersion.cmake: missing GENERATE_VERSION_SOURCE_DIR or GENERATE_VERSION_BINARY_DIR")
endif()

# Sanitize incoming -D values on Windows (VS/Ninja/cmd can preserve quotes)
foreach(_v GENERATE_VERSION_SOURCE_DIR GENERATE_VERSION_BINARY_DIR)
	if(DEFINED ${_v})
		string(REPLACE "\"" "" ${_v} "${${_v}}")
	endif()
endforeach()

# Normalize slashes (helps Windows paths in -P mode)
file(TO_CMAKE_PATH "${GENERATE_VERSION_SOURCE_DIR}" GENERATE_VERSION_SOURCE_DIR)
file(TO_CMAKE_PATH "${GENERATE_VERSION_BINARY_DIR}" GENERATE_VERSION_BINARY_DIR)

if(NOT DEFINED VERSION_STRING)
	set(VERSION_STRING "unknown")
endif()

# Normalize DEVELOPMENT_BUILD to boolean-ish
if(NOT DEFINED DEVELOPMENT_BUILD)
	set(DEVELOPMENT_BUILD FALSE)
endif()

set(VERSION_GITHASH "")

# Only try git if this is a development build
if(DEVELOPMENT_BUILD)
	# Use -C so we don't depend on WORKING_DIRECTORY behavior
	execute_process(
		COMMAND git -C "${GENERATE_VERSION_SOURCE_DIR}" rev-parse --short HEAD
		OUTPUT_VARIABLE GIT_HEAD
		OUTPUT_STRIP_TRAILING_WHITESPACE
		RESULT_VARIABLE GIT_HEAD_RC
		ERROR_QUIET
	)

	if(GIT_HEAD_RC EQUAL 0 AND GIT_HEAD)
		set(VERSION_GITHASH "${VERSION_STRING}-${GIT_HEAD}")

		# Dirty check: returns 0 when clean, nonzero when dirty
		execute_process(
			COMMAND git -C "${GENERATE_VERSION_SOURCE_DIR}" diff-index --quiet HEAD --
			RESULT_VARIABLE GIT_DIRTY_RC
			ERROR_QUIET
		)

		if(NOT GIT_DIRTY_RC EQUAL 0)
			set(VERSION_GITHASH "${VERSION_GITHASH}-dirty")
		endif()

		message(STATUS "*** Detected Git version ${VERSION_GITHASH} ***")
	endif()
endif()

# Fallback when git isn't available / not a repo / not a dev build
if(NOT VERSION_GITHASH)
	set(VERSION_GITHASH "${VERSION_STRING}")
endif()

configure_file(
	"${GENERATE_VERSION_SOURCE_DIR}/cmake_config_githash.h.in"
	"${GENERATE_VERSION_BINARY_DIR}/cmake_config_githash.h"
	@ONLY
)
