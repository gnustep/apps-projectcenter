#
# GNUmakefile - RenaissanceProject
#

include $(GNUSTEP_MAKEFILES)/common.make

#
# Bundle
#

BUNDLE_NAME = Renaissance
BUNDLE_EXTENSION = .project
Renaissance_PRINCIPAL_CLASS = PCRenaissanceProj


#
# Additional libraries
#

Renaissance_LIBRARIES_DEPEND_UPON += -lProjectCenter 

#
# Resource files
#

Renaissance_RESOURCE_FILES= \
  Resources/PC.project \
  Resources/main.m \
  Resources/AppController.m \
  Resources/AppController.h \
  Resources/Main.gsmarkup \
  Resources/MainMenu-GNUstep.gsmarkup \
  Resources/MainMenu-OSX.gsmarkup \
  Resources/Inspector.gorm


#
# Header files
#

Renaissance_HEADERS= \
  PCRenaissanceProj.h \
  PCRenaissanceProject.h \
  PCRenaissanceProject+Inspector.h 

#
# Class files
#

Renaissance_OBJC_FILES= \
  PCRenaissanceProj.m \
  PCRenaissanceProject.m \
  PCRenaissanceProject+Inspector.m 

include ../GNUmakefile.bundles
include $(GNUSTEP_MAKEFILES)/bundle.make

