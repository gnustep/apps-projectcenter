#
# GNUmakefile - Interface preferences
#
PACKAGE_NAME = Interface
include $(GNUSTEP_MAKEFILES)/common.make

#
# Bundle
#
BUNDLE_NAME = Interface
BUNDLE_EXTENSION = .preferences
Interface_PRINCIPAL_CLASS = PCInterfacePrefs


#
# Additional libraries
#
Interface_LIBRARIES_DEPEND_UPON +=

#
# Resource files
#
Interface_RESOURCE_FILES= \
  Resources/InterfacePrefs.gorm \
  Resources/Info.table

#
# Header files
#
Interface_HEADERS= \
  PCInterfacePrefs.h

#
# Class files
#
Interface_OBJC_FILES= \
  PCInterfacePrefs.m

include ../../GNUmakefile.bundles
include $(GNUSTEP_MAKEFILES)/bundle.make

