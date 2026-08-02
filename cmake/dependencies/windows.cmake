# windows specific dependencies

# Fallback logic to find or build MinHook on Windows
# This file is included from cmake/dependencies/common.cmake

# Try to find an installed MinHook library first
find_library(MINHOOK_LIBRARY
    NAMES MinHook MinHook.lib libMinHook.a libMinHook
    PATHS
    $ENV{VCPKG_ROOT}/installed/*/lib
    ${CMAKE_PREFIX_PATH}
    NO_DEFAULT_PATH
)

if(MINHOOK_LIBRARY)
    message(STATUS "Found MinHook library: ${MINHOOK_LIBRARY}")
    set(MINHOOK_FOUND TRUE)
    # Create an imported target so other CMake files can link to minhook::minhook
    add_library(minhook::minhook UNKNOWN IMPORTED)
    set_target_properties(minhook::minhook PROPERTIES
        IMPORTED_LOCATION "${MINHOOK_LIBRARY}"
    )
    # Try to set include dir if available from vcpkg layout or bundled path
    if(DEFINED ENV{VCPKG_ROOT})
        file(GLOB VCPKG_MINHOOK_INC "$ENV{VCPKG_ROOT}/installed/*/include")
        foreach(_inc ${VCPKG_MINHOOK_INC})
            if(EXISTS "${_inc}/MinHook.h")
                set(MINHOOK_INCLUDE_DIR "${_inc}")
                break()
            endif()
        endforeach()
    endif()
    if(NOT DEFINED MINHOOK_INCLUDE_DIR AND EXISTS "${CMAKE_SOURCE_DIR}/third-party/minhook/include/MinHook.h")
        set(MINHOOK_INCLUDE_DIR "${CMAKE_SOURCE_DIR}/third-party/minhook/include")
    endif()
    if(DEFINED MINHOOK_INCLUDE_DIR)
        set_target_properties(minhook::minhook PROPERTIES
            INTERFACE_INCLUDE_DIRECTORIES "${MINHOOK_INCLUDE_DIR}"
        )
        set(MINHOOK_INCLUDE_DIR ${MINHOOK_INCLUDE_DIR} CACHE INTERNAL "MinHook include dir")
    endif()
    set(MINHOOK_LIBRARIES minhook::minhook CACHE INTERNAL "MinHook library target or path")
else()
    # If not found, try to build MinHook from the bundled third-party source tree
    if(EXISTS "${CMAKE_SOURCE_DIR}/third-party/minhook")
        message(STATUS "MinHook not found by find_library(), building from third-party/minhook sources")
        file(GLOB MINHOOK_SOURCES 
            "${CMAKE_SOURCE_DIR}/third-party/minhook/src/*.c"
            "${CMAKE_SOURCE_DIR}/third-party/minhook/src/hde/*.c"
        )
        if(MINHOOK_SOURCES)
            add_library(MinHook STATIC ${MINHOOK_SOURCES})
            target_include_directories(MinHook PUBLIC "${CMAKE_SOURCE_DIR}/third-party/minhook/include")
            # Provide a target name expected by the rest of the build
            add_library(minhook::minhook ALIAS MinHook)
            # Expose variables consistent with find_package style
            set(MINHOOK_FOUND TRUE)
            set(MINHOOK_LIBRARIES minhook::minhook CACHE INTERNAL "MinHook library target")
            set(MINHOOK_INCLUDE_DIR "${CMAKE_SOURCE_DIR}/third-party/minhook/include" CACHE INTERNAL "MinHook include dir")
        else()
            message(WARNING "MinHook source files not found under third-party/minhook/src; MinHook disabled")
            set(MINHOOK_FOUND FALSE)
        endif()
    else()
        message(WARNING "MinHook library not found and no bundled source present; MinHook-dependent features may be disabled")
        set(MINHOOK_FOUND FALSE)
    endif()
endif()

# Provide a consistent boolean variable
if(NOT DEFINED MINHOOK_FOUND)
    set(MINHOOK_FOUND FALSE)
endif()
