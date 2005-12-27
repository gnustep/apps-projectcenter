#
# GNUmakefile - ProjectCenter.parser
#

include $(GNUSTEP_MAKEFILES)/common.make

#
# Bundle
#
BUNDLE_NAME = ProjectCenter
BUNDLE_EXTENSION = .parser
ProjectCenter_PRINCIPAL_CLASS = PCParser

#
# Additional libraries
#
ProjectCenter_LIBRARIES_DEPEND_UPON +=

#
# Resource files
#
ProjectCenter_RESOURCE_FILES= \
    Resources/Info.table

#
# Header files
#
ProjectCenter_HEADERS= \
    PCParser.h \
    CodeHandler.h \
    ObjCCommentHandler.h \
    ObjCMethodHandler.h

#
# Class files
#
ProjectCenter_OBJC_FILES= \
    PCParser.m \
    ObjCCommentHandler.m \
    ObjCMethodHandler.m

include ../../GNUmakefile.bundles
include $(GNUSTEP_MAKEFILES)/bundle.make

