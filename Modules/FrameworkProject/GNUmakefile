#
# GNUmakefile - FrameworkProject
#

include $(GNUSTEP_MAKEFILES)/common.make

#
# Bundle
#
BUNDLE_NAME = Framework
BUNDLE_EXTENSION = .project
Framework_PRINCIPAL_CLASS = PCFrameworkProj


#
# Additional libraries
#
Framework_LIBRARIES_DEPEND_UPON += -lProjectCenter 

#
# Resource files
#
Framework_RESOURCE_FILES= \
  Resources/PC.project \
  Resources/Inspector.gorm

#
# Header files
#
Framework_HEADERS= \
  PCFrameworkProj.h \
  PCFrameworkProject.h 

#
# Class files
#
Framework_OBJC_FILES= \
  PCFrameworkProj.m \
  PCFrameworkProject.m 

include ../GNUmakefile.bundles
include $(GNUSTEP_MAKEFILES)/bundle.make

