cmake_minimum_required(VERSION 3.14)
project(runner LANGUAGES CXX)

# Define the application target. To change its name, change BINARY_NAME in the
# top-level CMakeLists.txt, not the value here, or `flutter run` will no longer
# work.
#
# Any new source files that you add to the application should be added here.
add_executable(${BINARY_NAME} WIN32
  "flutter_window.cpp"
  "main.cpp"
  "social_webview.cpp"
  "utils.cpp"
  "win32_window.cpp"
  "${FLUTTER_MANAGED_DIR}/generated_plugin_registrant.cc"
  "Runner.rc"
  "runner.exe.manifest"
)

# WebView2 SDK (NuGet) — 소셜 로그인 인터셉터용 임베디드 브라우저
include(FetchContent)
FetchContent_Declare(webview2
  URL "https://www.nuget.org/api/v2/package/Microsoft.Web.WebView2/1.0.2592.51"
)
FetchContent_MakeAvailable(webview2)

# Apply the standard set of build settings. This can be removed for applications
# that need different build settings.
apply_standard_settings(${BINARY_NAME})

# Add preprocessor definitions for the build version.
target_compile_definitions(${BINARY_NAME} PRIVATE "FLUTTER_VERSION=\"${FLUTTER_VERSION}\"")
target_compile_definitions(${BINARY_NAME} PRIVATE "FLUTTER_VERSION_MAJOR=${FLUTTER_VERSION_MAJOR}")
target_compile_definitions(${BINARY_NAME} PRIVATE "FLUTTER_VERSION_MINOR=${FLUTTER_VERSION_MINOR}")
target_compile_definitions(${BINARY_NAME} PRIVATE "FLUTTER_VERSION_PATCH=${FLUTTER_VERSION_PATCH}")
target_compile_definitions(${BINARY_NAME} PRIVATE "FLUTTER_VERSION_BUILD=${FLUTTER_VERSION_BUILD}")

# Disable Windows macros that collide with C++ standard library functions.
target_compile_definitions(${BINARY_NAME} PRIVATE "NOMINMAX")

# Add dependency libraries and include directories. Add any application-specific
# dependencies here.
target_link_libraries(${BINARY_NAME} PRIVATE flutter flutter_wrapper_app)
target_link_libraries(${BINARY_NAME} PRIVATE "dwmapi.lib")
target_include_directories(${BINARY_NAME} PRIVATE "${CMAKE_SOURCE_DIR}")

# WebView2 헤더/로더 (정적 로더 링크 — 런타임은 시스템 WebView2 Runtime 사용)
target_include_directories(${BINARY_NAME} PRIVATE
  "${webview2_SOURCE_DIR}/build/native/include")
target_link_libraries(${BINARY_NAME} PRIVATE
  "${webview2_SOURCE_DIR}/build/native/x64/WebView2LoaderStatic.lib")

# Run the Flutter tool portions of the build. This must not be removed.
add_dependencies(${BINARY_NAME} flutter_assemble)

# 클린 머신에서도 실행되도록 MSVC 런타임 DLL(vcruntime140*, msvcp140)을 동봉.
# (UCRT 은 Windows 10+ 기본 내장이라 제외)
# _SKIP=TRUE: install() 규칙은 만들지 않고 변수만 채워, 아래 post-build 복사만 사용
# (install 규칙을 만들면 Flutter 의 INSTALL 단계에서 실패함).
set(CMAKE_INSTALL_UCRT_LIBRARIES FALSE)
set(CMAKE_INSTALL_SYSTEM_RUNTIME_LIBS_SKIP TRUE)
include(InstallRequiredSystemLibraries)
if(CMAKE_INSTALL_SYSTEM_RUNTIME_LIBS)
  add_custom_command(TARGET ${BINARY_NAME} POST_BUILD
    COMMAND ${CMAKE_COMMAND} -E copy_if_different
      ${CMAKE_INSTALL_SYSTEM_RUNTIME_LIBS}
      "$<TARGET_FILE_DIR:${BINARY_NAME}>"
    COMMAND_EXPAND_LISTS
  )
endif()
