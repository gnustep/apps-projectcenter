#
# GNUmakefile - ProjectCenter.debugger
#
PACKAGE_NAME = ProjectCenter
include $(GNUSTEP_MAKEFILES)/common.make

#
# Bundle
#
BUNDLE_NAME = ProjectCenter
BUNDLE_EXTENSION = .debugger
ProjectCenter_PRINCIPAL_CLASS = PCDebugger

#
# Additional libraries
#
ProjectCenter_LIBRARIES_DEPEND_UPON +=

#
# Resource files
#
ProjectCenter_RESOURCE_FILES= \
    Resources/PCDebugger.gorm \
    Resources/Info.table
#
# Header files
#
ProjectCenter_HEADERS= \
    PCDebugger.h \
    PCDebugggerView.h 

#
# Class files
#
ProjectCenter_OBJC_FILES= \
    PCDebugger.m \
    PCDebuggerView.m 

include ../../GNUmakefile.bundles
include $(GNUSTEP_MAKEFILES)/bundle.make
