#
# GNUmakefile - BundleProject
#

include $(GNUSTEP_MAKEFILES)/common.make

#
# Bundle
#
BUNDLE_NAME = Bundle
BUNDLE_EXTENSION = .project
Bundle_PRINCIPAL_CLASS = PCBundleProj


#
# Additional libraries
#
Bundle_LIBRARIES_DEPEND_UPON += -lProjectCenter 

#
# Resource files
#
Bundle_RESOURCE_FILES = \
  Resources/PC.project \
  Resources/Inspector.gorm

#
# Header files
#
Bundle_HEADERS = \
  PCBundleProj.h \
  PCBundleProject.h

#
# Class files
#

Bundle_OBJC_FILES= \
  PCBundleProj.m \
  PCBundleProject.m

include ../GNUmakefile.bundles
include $(GNUSTEP_MAKEFILES)/bundle.make
