#
# GNUmakefile - LibraryProject
#

include $(GNUSTEP_MAKEFILES)/common.make

#
# Bundle
#
BUNDLE_NAME = Library
BUNDLE_EXTENSION = .project
Library_PRINCIPAL_CLASS = PCLibProj


#
# Additional libraries
#
Library_LIBRARIES_DEPEND_UPON += -lProjectCenter 

#
# Resource files
#
Library_RESOURCE_FILES= \
  Resources/PC.project \
  Resources/Version \
  Resources/Inspector.gorm

#
# Header files
#
Library_HEADERS= \
  PCLibProj.h \
  PCLibProject.h 

#
# Class files
#
Library_OBJC_FILES= \
  PCLibProj.m \
  PCLibProject.m 

include ../GNUmakefile.bundles
include $(GNUSTEP_MAKEFILES)/bundle.make

