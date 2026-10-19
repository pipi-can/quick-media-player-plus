cmake_minimum_required(VERSION 3.16)

project(quick-media-player VERSION 0.1 LANGUAGES CXX)

set(CMAKE_AUTOMOC ON)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

find_package(Qt6 REQUIRED COMPONENTS Quick Core5Compat)


qt_add_executable(appquick-media-player
    main.cpp
    includes/utils/logger.h
    sources/utils/logger.cpp
)

qt_add_qml_module(appquick-media-player
    URI quick-media-player
    VERSION 1.0
    QML_FILES
        qml/main.qml
        qml/utils/Utils.qml
        qml/layouts/FramelessWindow.qml
        qml/layouts/CustomComponents/ColorImage.qml
        qml/layouts/CustomComponents/MultiStateItem.qml
        qml/layouts/CustomComponents/MouseStateItem.qml
        qml/layouts/CustomComponents/Seprator.qml
        qml/layouts/TitleBarLayout/TitleBar.qml
    RESOURCES
        resources/AppIcons/MainIcon.svg
        resources/TitleBarIcons/minimize.svg
        resources/TitleBarIcons/maximize.svg
        resources/TitleBarIcons/normalize.svg
        resources/TitleBarIcons/close.svg
        resources/TitleBarIcons/theme.svg
        resources/TitleBarIcons/settings.svg
)

# Qt for iOS sets MACOSX_BUNDLE_GUI_IDENTIFIER automatically since Qt 6.1.
# If you are developing for iOS or macOS you should consider setting an
# explicit, fixed bundle identifier manually though.
set_target_properties(appquick-media-player PROPERTIES
#    MACOSX_BUNDLE_GUI_IDENTIFIER com.example.appquick-media-player
    MACOSX_BUNDLE_BUNDLE_VERSION ${PROJECT_VERSION}
    MACOSX_BUNDLE_SHORT_VERSION_STRING ${PROJECT_VERSION_MAJOR}.${PROJECT_VERSION_MINOR}
    MACOSX_BUNDLE TRUE
    WIN32_EXECUTABLE TRUE
)

target_include_directories(appquick-media-player
    PRIVATE
        ${CMAKE_CURRENT_SOURCE_DIR}/includes
)

target_link_libraries(appquick-media-player
    PRIVATE Qt6::Quick Qt6::Core5Compat
)

include(GNUInstallDirs)
install(TARGETS appquick-media-player
    BUNDLE DESTINATION .
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
)
