#
# GNUmakefile - ToolProject
#

include $(GNUSTEP_MAKEFILES)/common.make

#
# Bundle
#
BUNDLE_NAME = Tool
BUNDLE_EXTENSION = .project
Tool_PRINCIPAL_CLASS = PCToolProj

#
# Additional libraries
#
Tool_LIBRARIES_DEPEND_UPON += -lProjectCenter 

#
# Resource files
#
Tool_RESOURCE_FILES= \
  Resources/PC.project \
  Resources/main.m \
  Resources/Inspector.gorm

#
# Header files
#
Tool_HEADERS= \
  PCToolProj.h \
  PCToolProject.h 

#
# Class files
#
Tool_OBJC_FILES= \
  PCToolProj.m \
  PCToolProject.m 

include ../GNUmakefile.bundles
include $(GNUSTEP_MAKEFILES)/bundle.make
