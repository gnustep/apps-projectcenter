#
# GNUmakefile
#
# Here are the several types of modules (bundles):
#
# Project types:
#	- Aggregate
#	- Application
#	- Bundle
#	- Framework
#	- Library
#	- ResourceSet
#	- Tool
# Editors:
#	- ProjectCenter -- default PC editor
# Parsers:
#	- ObjectiveC -- that's it!
#

PACKAGE_NAME = ProjectCenter
include $(GNUSTEP_MAKEFILES)/common.make

#
# Subprojects
#
SUBPROJECTS = \
        Projects/Aggregate   	\
        Projects/Application 	\
        Projects/Bundle      	\
	Projects/Framework   	\
        Projects/Library     	\
	Projects/ResourceSet 	\
        Projects/Tool        	\
	\
	Editors/ProjectCenter	\
	\
	Parsers/ProjectCenter   \
	\
	Preferences/Build       \
	Preferences/Saving      \
	Preferences/Misc        \
	Preferences/EditorFSC

# Do not compile the Debuggers/ProjectCenter module on MinGW since I'm
# told at the moment it doesn't even compile there.
ifneq ($(GNUSTEP_TARGET_OS), mingw32)
  SUBPROJECTS += Debuggers/ProjectCenter
endif


include $(GNUSTEP_MAKEFILES)/aggregate.make

