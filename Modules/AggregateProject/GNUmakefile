#
# GNUmakefile
#
include $(GNUSTEP_MAKEFILES)/common.make


#
# Bundle
#
PACKAGE_NAME = AggregateProject
BUNDLE_NAME = AggregateProject
AggregateProject_PRINCIPAL_CLASS = PCAggregateProj

#
# Additional libraries
#
AggregateProject_LIBRARIES_DEPEND_UPON += -lProjectCenter 

#
# Resource files
#
AggregateProject_RESOURCE_FILES= \
Resources/PC.project \
Resources/Inspector.gorm

#
# Header files
#
AggregateProject_HEADERS= \
PCAggregateProj.h \
PCAggregateProject.h 

#
# Class files
#
AggregateProject_OBJC_FILES= \
PCAggregateProj.m \
PCAggregateProject.m 

#
# C files
#

AggregateProject_C_FILES= 

include ../GNUmakefile.bundles
include $(GNUSTEP_MAKEFILES)/bundle.make
