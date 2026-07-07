# SPDX-FileCopyrightText: 2026 AnicetusCer
# SPDX-License-Identifier: GPL-3.0-or-later

cmake_minimum_required(VERSION 3.21)

project(imboard VERSION 0.2.2 LANGUAGES CXX)

include(CTest)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

if(CMAKE_CXX_COMPILER_ID MATCHES "GNU|Clang")
    add_compile_options(-Wall -Wextra -Wpedantic)
endif()

find_package(Qt6 6.4 REQUIRED COMPONENTS DBus Quick Qml Widgets)
find_package(LayerShellQt QUIET)

qt_standard_project_setup(REQUIRES 6.4)

if(QT_KNOWN_POLICY_QTP0001)
    qt_policy(SET QTP0001 NEW)
endif()
if(QT_KNOWN_POLICY_QTP0004)
    qt_policy(SET QTP0004 NEW)
endif()

qt_add_executable(imboard
    src/main.cpp
    src/appmetadata.h
    src/appearancestore.cpp
    src/appearancestore.h
    src/compatibilitystore.cpp
    src/compatibilitystore.h
    src/keyboardlayoutstore.cpp
    src/keyboardlayoutstore.h
    src/inputcontroller.cpp
    src/inputcontroller.h
    src/portalinputbackend.cpp
    src/portalinputbackend.h
    src/customkeystore.cpp
    src/customkeystore.h
    src/instancecontroller.cpp
    src/instancecontroller.h
    src/signalhandler.cpp
    src/signalhandler.h
    src/smoketestcontroller.cpp
    src/smoketestcontroller.h
    src/startupmanager.cpp
    src/startupmanager.h
    src/surfacecontroller.cpp
    src/surfacecontroller.h
)

qt_add_qml_module(imboard
    URI Imboard
    VERSION 1.0
    RESOURCE_PREFIX /
    NO_CACHEGEN
    NO_IMPORT_SCAN
    QML_FILES
        qml/Main.qml
        qml/AlphaBoard.qml
        qml/AboutPopup.qml
        qml/AppearancePopup.qml
        qml/ConfigPopup.qml
        qml/CompatibilityWarningPopup.qml
        qml/DeveloperCustomPage.qml
        qml/DeveloperPad.qml
        qml/DeveloperStandardPage.qml
        qml/KeyboardSurface.qml
        qml/KeyCap.qml
        qml/LayoutPopup.qml
        qml/PermissionSetupPopup.qml
        qml/RemoveAccessPopup.qml
        qml/StartupPromptPopup.qml
)

qt_add_resources(imboard twemoji_assets
    PREFIX "/Imboard/assets/twemoji"
    BASE assets/twemoji
    FILES
        assets/twemoji/1f389.png
        assets/twemoji/1f41b.png
        assets/twemoji/1f440.png
        assets/twemoji/1f44d.png
        assets/twemoji/1f44e.png
        assets/twemoji/1f4a1.png
        assets/twemoji/1f4cc.png
        assets/twemoji/1f525.png
        assets/twemoji/1f602.png
        assets/twemoji/1f680.png
        assets/twemoji/1f6e0.png
        assets/twemoji/1f914.png
        assets/twemoji/26a0.png
        assets/twemoji/2705.png
        assets/twemoji/274c.png
        assets/twemoji/2764.png
)

set(KEYBOARD_LAYOUT_FILES
    layouts/gb.json
    layouts/us.json
)

qt_add_resources(imboard keyboard_layouts
    PREFIX "/Imboard/layouts"
    BASE layouts
    FILES ${KEYBOARD_LAYOUT_FILES}
)

target_link_libraries(imboard PRIVATE Qt6::DBus Qt6::Quick Qt6::Qml Qt6::Widgets)
if(TARGET LayerShellQt::Interface)
    target_link_libraries(imboard PRIVATE LayerShellQt::Interface)
    target_compile_definitions(imboard PRIVATE IMBOARD_HAVE_LAYER_SHELL)
endif()

if(BUILD_TESTING)
    find_package(Qt6 6.4 REQUIRED COMPONENTS Test)

    qt_add_executable(customkeystore-test
        tests/customkeystore_test.cpp
        src/customkeystore.cpp
        src/customkeystore.h
    )
    target_include_directories(customkeystore-test PRIVATE src)
    target_link_libraries(customkeystore-test PRIVATE Qt6::Core Qt6::Test)

    add_test(NAME customkeystore-persistence COMMAND customkeystore-test)
    set_tests_properties(customkeystore-persistence PROPERTIES
        ENVIRONMENT "XDG_CONFIG_HOME=${CMAKE_CURRENT_BINARY_DIR}/test-config-customkeys"
        TIMEOUT 5
    )

    qt_add_executable(appearancestore-test
        tests/appearancestore_test.cpp
        src/appearancestore.cpp
        src/appearancestore.h
    )
    target_include_directories(appearancestore-test PRIVATE src)
    target_link_libraries(appearancestore-test PRIVATE Qt6::Gui Qt6::Test)

    add_test(NAME appearance-persistence COMMAND appearancestore-test)
    set_tests_properties(appearance-persistence PROPERTIES
        ENVIRONMENT "XDG_CONFIG_HOME=${CMAKE_CURRENT_BINARY_DIR}/test-config-appearance"
        TIMEOUT 5
    )

    qt_add_executable(compatibilitystore-test
        tests/compatibilitystore_test.cpp
        src/appmetadata.h
        src/compatibilitystore.cpp
        src/compatibilitystore.h
    )
    target_include_directories(compatibilitystore-test PRIVATE src)
    target_link_libraries(compatibilitystore-test PRIVATE Qt6::Core Qt6::Test)

    add_test(NAME compatibility-warning-persistence COMMAND compatibilitystore-test)
    set_tests_properties(compatibility-warning-persistence PROPERTIES
        ENVIRONMENT "XDG_CONFIG_HOME=${CMAKE_CURRENT_BINARY_DIR}/test-config-compatibility"
        TIMEOUT 5
    )

    qt_add_executable(keyboardlayoutstore-test
        tests/keyboardlayoutstore_test.cpp
        src/keyboardlayoutstore.cpp
        src/keyboardlayoutstore.h
    )
    target_include_directories(keyboardlayoutstore-test PRIVATE src)
    target_link_libraries(keyboardlayoutstore-test PRIVATE Qt6::Core Qt6::Test)
    qt_add_resources(keyboardlayoutstore-test keyboard_layout_test_resources
        PREFIX "/Imboard/layouts"
        BASE layouts
        FILES ${KEYBOARD_LAYOUT_FILES}
    )

    add_test(NAME keyboard-layout-persistence COMMAND keyboardlayoutstore-test)
    set_tests_properties(keyboard-layout-persistence PROPERTIES
        ENVIRONMENT "XDG_CONFIG_HOME=${CMAKE_CURRENT_BINARY_DIR}/test-config-keyboard-layout"
        TIMEOUT 5
    )

    qt_add_executable(startupmanager-test
        tests/startupmanager_test.cpp
        src/appmetadata.h
        src/startupmanager.cpp
        src/startupmanager.h
    )
    target_include_directories(startupmanager-test PRIVATE src)
    target_link_libraries(startupmanager-test PRIVATE Qt6::Core Qt6::DBus Qt6::Test)

    add_test(NAME startup-entry-lifecycle COMMAND startupmanager-test)
    set_tests_properties(startup-entry-lifecycle PROPERTIES
        ENVIRONMENT "XDG_CONFIG_HOME=${CMAKE_CURRENT_BINARY_DIR}/test-config-startup"
        TIMEOUT 5
    )

    qt_add_executable(portalinputbackend-test
        tests/portalinputbackend_test.cpp
        src/portalinputbackend.cpp
        src/portalinputbackend.h
    )
    target_include_directories(portalinputbackend-test PRIVATE src)
    target_link_libraries(portalinputbackend-test PRIVATE Qt6::Core Qt6::DBus Qt6::Test)

    add_test(NAME portal-permission-forget COMMAND portalinputbackend-test)
    set_tests_properties(portal-permission-forget PROPERTIES
        ENVIRONMENT "XDG_CONFIG_HOME=${CMAKE_CURRENT_BINARY_DIR}/test-config-portal"
        TIMEOUT 5
    )

    qt_add_executable(inputcontroller-test
        tests/inputcontroller_test.cpp
        src/inputcontroller.cpp
        src/inputcontroller.h
        src/portalinputbackend.cpp
        src/portalinputbackend.h
    )
    target_include_directories(inputcontroller-test PRIVATE src)
    target_link_libraries(inputcontroller-test PRIVATE Qt6::Core Qt6::DBus Qt6::Gui Qt6::Test)

    add_test(NAME input-action-validation COMMAND inputcontroller-test)
    set_tests_properties(input-action-validation PROPERTIES
        ENVIRONMENT "XDG_CONFIG_HOME=${CMAKE_CURRENT_BINARY_DIR}/test-config-input-controller"
        TIMEOUT 5
    )

    add_test(NAME imboard-qml-smoke
             COMMAND bash ${CMAKE_CURRENT_SOURCE_DIR}/tests/qml_smoke.sh
                     $<TARGET_FILE:imboard>)
    set_tests_properties(imboard-qml-smoke PROPERTIES
        TIMEOUT 5
    )

    add_test(NAME imboard-lifecycle
             COMMAND bash ${CMAKE_CURRENT_SOURCE_DIR}/tests/lifecycle.sh
                     $<TARGET_FILE:imboard>)
    set_tests_properties(imboard-lifecycle PROPERTIES TIMEOUT 15)

endif()

install(TARGETS imboard RUNTIME DESTINATION bin)
install(FILES packaging/io.github.anicetuscer.imboard.desktop
        DESTINATION share/applications)
install(FILES packaging/io.github.anicetuscer.imboard.metainfo.xml
        DESTINATION share/metainfo)
install(FILES packaging/io.github.anicetuscer.imboard.svg
        DESTINATION share/icons/hicolor/scalable/apps)
