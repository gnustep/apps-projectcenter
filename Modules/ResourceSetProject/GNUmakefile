#
# GNUmakefile - Aggregate.project
#

include $(GNUSTEP_MAKEFILES)/common.make

#
# Bundle
#
BUNDLE_NAME = ResourceSet
BUNDLE_EXTENSION = .project
ResourceSet_PRINCIPAL_CLASS = PCResourceSetProj

#
# Additional libraries
#
ResourceSet_LIBRARIES_DEPEND_UPON += -lProjectCenter 

#
# Resource files
#
ResourceSet_RESOURCE_FILES= \
    Resources/PC.project \
    Resources/Inspector.gorm

#
# Header files
#
ResourceSet_HEADERS= \
    PCResourceSetProj.h \
    PCResourceSetProject.h 

#
# Class files
#
ResourceSet_OBJC_FILES= \
    PCResourceSetProj.m \
    PCResourceSetProject.m 

include ../GNUmakefile.bundles
include $(GNUSTEP_MAKEFILES)/bundle.make
