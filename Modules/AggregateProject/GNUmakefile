#
# GNUmakefile - Aggregate.project
#

include $(GNUSTEP_MAKEFILES)/common.make

#
# Bundle
#
BUNDLE_NAME = Aggregate
BUNDLE_EXTENSION = .project
Aggregate_PRINCIPAL_CLASS = PCAggregateProj

#
# Additional libraries
#
Aggregate_LIBRARIES_DEPEND_UPON += -lProjectCenter 

#
# Resource files
#
Aggregate_RESOURCE_FILES= \
    Resources/PC.project \
    Resources/Inspector.gorm

#
# Header files
#
Aggregate_HEADERS= \
    PCAggregateProj.h \
    PCAggregateProject.h 

#
# Class files
#
Aggregate_OBJC_FILES= \
    PCAggregateProj.m \
    PCAggregateProject.m 

include ../GNUmakefile.bundles
include $(GNUSTEP_MAKEFILES)/bundle.make
