cmake_minimum_required(VERSION 3.24)
project(AssaultCubeIOS LANGUAGES C CXX)

if(NOT CMAKE_SYSTEM_NAME STREQUAL "iOS")
    message(FATAL_ERROR "This target must be configured with an iOS toolchain (CMAKE_SYSTEM_NAME=iOS).")
endif()

set(AC_ROOT "${CMAKE_CURRENT_LIST_DIR}/../.." CACHE PATH "Path to the AssaultCube repository root")
set(AC_IOS_DEPS_DIR "${CMAKE_CURRENT_LIST_DIR}/../Dependencies" CACHE PATH "Directory containing the extracted iOS dependency artifact")

set(AC_SDL_INCLUDE "${AC_IOS_DEPS_DIR}/SDL2/include")
set(AC_SDL_CONFIG_INCLUDE "${AC_SDL_INCLUDE}/SDL2")
set(AC_GL4ES_INCLUDE "${AC_IOS_DEPS_DIR}/GL4ES/include")
set(AC_AUDIO_INCLUDE "${AC_IOS_DEPS_DIR}/Audio/include")

set(AC_REQUIRED_FILES
    "${AC_IOS_DEPS_DIR}/SDL2/lib/libSDL2.a"
    "${AC_IOS_DEPS_DIR}/SDL2/lib/libSDL2main.a"
    "${AC_IOS_DEPS_DIR}/GL4ES/libGL.a"
    "${AC_IOS_DEPS_DIR}/Audio/lib/libogg.a"
    "${AC_IOS_DEPS_DIR}/Audio/lib/libvorbis.a"
    "${AC_IOS_DEPS_DIR}/Audio/lib/libvorbisfile.a"
)
foreach(AC_REQUIRED_FILE IN LISTS AC_REQUIRED_FILES)
    if(NOT EXISTS "${AC_REQUIRED_FILE}")
        message(FATAL_ERROR "Missing iOS dependency: ${AC_REQUIRED_FILE}. Extract the AssaultCube iOS dependency artifact into ios/Dependencies first.")
    endif()
endforeach()

foreach(AC_REQUIRED_DIR IN ITEMS "${AC_SDL_INCLUDE}" "${AC_SDL_CONFIG_INCLUDE}" "${AC_GL4ES_INCLUDE}" "${AC_AUDIO_INCLUDE}" "${AC_ROOT}/source/enet/include")
    if(NOT IS_DIRECTORY "${AC_REQUIRED_DIR}")
        message(FATAL_ERROR "Missing iOS include directory: ${AC_REQUIRED_DIR}")
    endif()
endforeach()

add_library(AC_SDL2 STATIC IMPORTED GLOBAL)
set_target_properties(AC_SDL2 PROPERTIES IMPORTED_LOCATION "${AC_IOS_DEPS_DIR}/SDL2/lib/libSDL2.a" INTERFACE_INCLUDE_DIRECTORIES "${AC_SDL_INCLUDE}")
add_library(AC_SDL2main STATIC IMPORTED GLOBAL)
set_target_properties(AC_SDL2main PROPERTIES IMPORTED_LOCATION "${AC_IOS_DEPS_DIR}/SDL2/lib/libSDL2main.a" INTERFACE_INCLUDE_DIRECTORIES "${AC_SDL_INCLUDE}")
add_library(AC_GL4ES STATIC IMPORTED GLOBAL)
set_target_properties(AC_GL4ES PROPERTIES IMPORTED_LOCATION "${AC_IOS_DEPS_DIR}/GL4ES/libGL.a" INTERFACE_INCLUDE_DIRECTORIES "${AC_GL4ES_INCLUDE}")
add_library(AC_OGG STATIC IMPORTED GLOBAL)
set_target_properties(AC_OGG PROPERTIES IMPORTED_LOCATION "${AC_IOS_DEPS_DIR}/Audio/lib/libogg.a" INTERFACE_INCLUDE_DIRECTORIES "${AC_AUDIO_INCLUDE}")
add_library(AC_VORBIS STATIC IMPORTED GLOBAL)
set_target_properties(AC_VORBIS PROPERTIES IMPORTED_LOCATION "${AC_IOS_DEPS_DIR}/Audio/lib/libvorbis.a" INTERFACE_INCLUDE_DIRECTORIES "${AC_AUDIO_INCLUDE}")
add_library(AC_VORBISFILE STATIC IMPORTED GLOBAL)
set_target_properties(AC_VORBISFILE PROPERTIES IMPORTED_LOCATION "${AC_IOS_DEPS_DIR}/Audio/lib/libvorbisfile.a" INTERFACE_INCLUDE_DIRECTORIES "${AC_AUDIO_INCLUDE}")

set(AC_ENET_SOURCES
    "${AC_ROOT}/source/enet/callbacks.c"
    "${AC_ROOT}/source/enet/compress.c"
    "${AC_ROOT}/source/enet/host.c"
    "${AC_ROOT}/source/enet/list.c"
    "${AC_ROOT}/source/enet/packet.c"
    "${AC_ROOT}/source/enet/peer.c"
    "${AC_ROOT}/source/enet/protocol.c"
    "${AC_ROOT}/source/enet/unix.c"
    "${AC_ROOT}/source/enet/win32.c"
)
add_library(AC_ENET STATIC ${AC_ENET_SOURCES})
target_include_directories(AC_ENET PUBLIC "${AC_ROOT}/source/enet/include")
set_target_properties(AC_ENET PROPERTIES C_STANDARD 99 C_STANDARD_REQUIRED YES POSITION_INDEPENDENT_CODE YES)

# This list follows the current source/src/Makefile client object list, not
# the older acmobile branch's JNI wrapper or Android-only source selection.
set(AC_ENGINE_SOURCES
    "${AC_ROOT}/source/src/crypto.cpp"
    "${AC_ROOT}/source/src/audiomanager.cpp"
    "${AC_ROOT}/source/src/autodownload.cpp"
    "${AC_ROOT}/source/src/client.cpp"
    "${AC_ROOT}/source/src/clientgame.cpp"
    "${AC_ROOT}/source/src/clients2c.cpp"
    "${AC_ROOT}/source/src/command.cpp"
    "${AC_ROOT}/source/src/console.cpp"
    "${AC_ROOT}/source/src/docs.cpp"
    "${AC_ROOT}/source/src/editing.cpp"
    "${AC_ROOT}/source/src/entities.cpp"
    "${AC_ROOT}/source/src/http.cpp"
    "${AC_ROOT}/source/src/log.cpp"
    "${AC_ROOT}/source/src/main.cpp"
    "${AC_ROOT}/source/src/menus.cpp"
    "${AC_ROOT}/source/src/oggstream.cpp"
    "${AC_ROOT}/source/src/openal.cpp"
    "${AC_ROOT}/source/src/packetqueue.cpp"
    "${AC_ROOT}/source/src/physics.cpp"
    "${AC_ROOT}/source/src/protocol.cpp"
    "${AC_ROOT}/source/src/rendercubes.cpp"
    "${AC_ROOT}/source/src/rendergl.cpp"
    "${AC_ROOT}/source/src/renderhud.cpp"
    "${AC_ROOT}/source/src/rendermodel.cpp"
    "${AC_ROOT}/source/src/renderparticles.cpp"
    "${AC_ROOT}/source/src/rendertext.cpp"
    "${AC_ROOT}/source/src/rndmap.cpp"
    "${AC_ROOT}/source/src/scoreboard.cpp"
    "${AC_ROOT}/source/src/serverms.cpp"
    "${AC_ROOT}/source/src/server.cpp"
    "${AC_ROOT}/source/src/serverbrowser.cpp"
    "${AC_ROOT}/source/src/shadow.cpp"
    "${AC_ROOT}/source/src/soundlocation.cpp"
    "${AC_ROOT}/source/src/soundscheduler.cpp"
    "${AC_ROOT}/source/src/stream.cpp"
    "${AC_ROOT}/source/src/texture.cpp"
    "${AC_ROOT}/source/src/tools.cpp"
    "${AC_ROOT}/source/src/water.cpp"
    "${AC_ROOT}/source/src/weapon.cpp"
    "${AC_ROOT}/source/src/wizard.cpp"
    "${AC_ROOT}/source/src/world.cpp"
    "${AC_ROOT}/source/src/worldio.cpp"
    "${AC_ROOT}/source/src/worldlight.cpp"
    "${AC_ROOT}/source/src/worldocull.cpp"
    "${AC_ROOT}/source/src/worldrender.cpp"
    "${AC_ROOT}/source/src/zip.cpp"
    "${AC_ROOT}/source/src/bot/bot.cpp"
    "${AC_ROOT}/source/src/bot/botmanager.cpp"
    "${AC_ROOT}/source/src/bot/bot_ai.cpp"
    "${AC_ROOT}/source/src/bot/bot_util.cpp"
    "${AC_ROOT}/source/src/bot/bot_waypoint.cpp"
    "${AC_ROOT}/source/src/bot/ac_bot.cpp"
    "${AC_ROOT}/source/src/bot/ac_bot_ai.cpp"
)
foreach(AC_SOURCE IN LISTS AC_ENGINE_SOURCES)
    if(NOT EXISTS "${AC_SOURCE}")
        message(FATAL_ERROR "Engine source file does not exist: ${AC_SOURCE}")
    endif()
endforeach()

add_library(AssaultCubeEngine STATIC ${AC_ENGINE_SOURCES})
target_include_directories(AssaultCubeEngine PUBLIC
    "${AC_ROOT}/source/src"
    "${AC_ROOT}/source/src/bot"
    "${AC_ROOT}/source/include"
    "${AC_ROOT}/source/enet/include"
    "${AC_SDL_INCLUDE}"
    "${AC_SDL_CONFIG_INCLUDE}"
    "${AC_GL4ES_INCLUDE}"
    "${AC_AUDIO_INCLUDE}"
)
target_compile_features(AssaultCubeEngine PUBLIC cxx_std_11)
# Enable the platform-specific SDL2/GL4ES path in source/src/main.cpp.
# Without this definition, the iOS renderer setup and lifecycle handling are compiled out.
target_compile_definitions(AssaultCubeEngine PUBLIC AC_PLATFORM_IOS=1)
# Match the upstream client Makefile: signed char is required, while RTTI and\n# exception behavior should retain the compiler defaults unless iOS proves otherwise.\n# Match the upstream client Makefile: preserve the compiler defaults for RTTI\n# and exceptions, and retain its signed-char behavior.\ntarget_compile_options(AssaultCubeEngine PRIVATE "$<$<COMPILE_LANGUAGE:CXX>:-fsigned-char>")
set_target_properties(AssaultCubeEngine PROPERTIES POSITION_INDEPENDENT_CODE YES)

find_library(AC_ZLIB z REQUIRED)
find_library(AC_OPENAL OpenAL REQUIRED)

# SDL2 is imported as a raw static archive rather than as its original CMake
# target, so explicitly propagate the iOS frameworks that SDL's CMake build
# normally attaches to SDL2-static.
find_library(AC_UIKIT UIKit REQUIRED)
find_library(AC_FOUNDATION Foundation REQUIRED)
find_library(AC_COREGRAPHICS CoreGraphics REQUIRED)
find_library(AC_QUARTZCORE QuartzCore REQUIRED)
find_library(AC_COREAUDIO CoreAudio REQUIRED)
find_library(AC_AUDIOTOOLBOX AudioToolbox REQUIRED)
find_library(AC_AVFOUNDATION AVFoundation REQUIRED)
find_library(AC_COREMOTION CoreMotion REQUIRED)
find_library(AC_COREVIDEO CoreVideo REQUIRED)
find_library(AC_OPENGLES OpenGLES REQUIRED)
find_library(AC_METAL Metal REQUIRED)
find_library(AC_GAMECONTROLLER GameController)
find_library(AC_COREHAPTICS CoreHaptics)

# SDL2's iOS bootstrap is linked transitively so SDL2main remains the single
# UIApplication entry point. Do not define SDL_MAIN_HANDLED in this target.
target_link_libraries(AssaultCubeEngine PUBLIC
    AC_SDL2main AC_SDL2 AC_GL4ES AC_VORBISFILE AC_VORBIS AC_OGG AC_ENET
    ${AC_ZLIB} ${AC_OPENAL}
    ${AC_UIKIT} ${AC_FOUNDATION} ${AC_COREGRAPHICS} ${AC_QUARTZCORE}
    ${AC_COREAUDIO} ${AC_AUDIOTOOLBOX} ${AC_AVFOUNDATION} ${AC_COREMOTION}
    ${AC_COREVIDEO} ${AC_OPENGLES} ${AC_METAL}
)
if(AC_GAMECONTROLLER)
    # SDL itself weak-links GameController so older OS versions remain loadable.
    target_link_options(AssaultCubeEngine PUBLIC "SHELL:-weak_framework GameController")
endif()
if(AC_COREHAPTICS)
    # SDL enables MFi rumble only when CoreHaptics is available and weak-links it.
    target_link_options(AssaultCubeEngine PUBLIC "SHELL:-weak_framework CoreHaptics")
endif()

message(STATUS "Configured AssaultCube native engine sources for iOS ARM64")
message(STATUS "Dependency root: ${AC_IOS_DEPS_DIR}")
