#
# GNUmakefile
#

include $(GNUSTEP_MAKEFILES)/common.make
GNUSTEP_INSTALLATION_DIR = $(GNUSTEP_SYSTEM_ROOT)

#
# Main application
#
VERSION = 0.4.1
PACKAGE_NAME = ProjectCenter
APP_NAME = ProjectCenter
ProjectCenter_APPLICATION_ICON = Images/ProjectCenter.tiff

#
# Subprojects
#
SUBPROJECTS = \
        Library \
	Modules \

#
# Resource files
#
ProjectCenter_RESOURCE_FILES = \
Resources/ProjectCenter.gorm \
Resources/LogPanel.gorm \
Resources/Preferences.gorm \
Resources/Info-gnustep.plist \
Images/ProjectCenter.tiff \
Images/FileC.tiff \
Images/FileCH.tiff \
Images/FileH.tiff \
Images/FileHH.tiff \
Images/FileM.tiff \
Images/FileMH.tiff \
Images/FileRTF.tiff \
Images/FileProject.tiff \
Images/Build.tiff \
Images/Clean.tiff \
Images/Debug.tiff \
Images/Files.tiff \
Images/Find.tiff \
Images/Inspector.tiff \
Images/Install.tiff \
Images/MultiFiles.tiff \
Images/Options.tiff \
Images/Run.tiff \
Images/Stop.tiff \
Images/ProjectCenter_add.tiff \
Images/ProjectCenter_cvs.tiff \
Images/ProjectCenter_dist.tiff \
Images/ProjectCenter_documentation.tiff \
Images/ProjectCenter_profile.tiff \
Images/ProjectCenter_rpm.tiff \
Images/ProjectCenter_uml.tiff \
Images/classSuitcase.tiff \
Images/classSuitcaseH.tiff \
Images/genericSuitcase.tiff \
Images/genericSuitcaseH.tiff \
Images/headerSuitcase.tiff \
Images/headerSuitcaseH.tiff \
Images/helpSuitcase.tiff \
Images/helpSuitcaseH.tiff \
Images/iconSuitcase.tiff \
Images/iconSuitcaseH.tiff \
Images/librarySuitcase.tiff \
Images/librarySuitcaseH.tiff \
Images/nibSuitcase.tiff \
Images/nibSuitcaseH.tiff \
Images/otherSuitcase.tiff \
Images/otherSuitcaseH.tiff \
Images/projectSuitcase.tiff \
Images/projectSuitcaseH.tiff \
Images/soundSuitcase.tiff \
Images/soundSuitcaseH.tiff \
Images/subprojectSuitcase.tiff \
Images/subprojectSuitcaseH.tiff \
Modules/AggregateProject/AggregateProject.bundle \
Modules/ApplicationProject/ApplicationProject.bundle \
Modules/BundleProject/BundleProject.bundle \
Modules/LibraryProject/LibraryProject.bundle \
Modules/RenaissanceProject/RenaissanceProject.bundle \
Modules/ToolProject/ToolProject.bundle 

#
# Header files
#
ProjectCenter_HEADERS = \
PCAppController.h \
PCInfoController.h \
PCLogController.h \
PCMenuController.h \
PCPrefController.h

#
# Class files
#
ProjectCenter_OBJC_FILES = \
PCAppController.m \
PCInfoController.m \
PCLogController.m \
PCMenuController.m \
PCPrefController.m \
ProjectCenter_main.m

-include GNUmakefile.preamble
include $(GNUSTEP_MAKEFILES)/aggregate.make
include $(GNUSTEP_MAKEFILES)/application.make
-include GNUmakefile.postamble
