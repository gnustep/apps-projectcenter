#
# GNUmakefile - ApplicationProject
#

include $(GNUSTEP_MAKEFILES)/common.make

#
# Bundle
#
BUNDLE_NAME = Application
BUNDLE_EXTENSION = .project
Application_PRINCIPAL_CLASS = PCAppProj


#
# Additional libraries
#
Application_LIBRARIES_DEPEND_UPON += -lProjectCenter 

#
# Resource files
#
Application_RESOURCE_FILES= \
  Resources/AppController.h \
  Resources/AppController.m \
  Resources/main.m \
  Resources/PC.project \
  Resources/Main.gorm \
  Resources/Inspector.gorm

#
# Header files
#
Application_HEADERS= \
  PCAppProj.h \
  PCAppProject.h \
  PCAppProject+Inspector.h 

#
# Class files
#
Application_OBJC_FILES= \
  PCAppProj.m \
  PCAppProject.m \
  PCAppProject+Inspector.m 

include ../GNUmakefile.bundles
include $(GNUSTEP_MAKEFILES)/bundle.make

