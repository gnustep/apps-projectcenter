#
#  src makefile for the PCLib
#
#  Copyright (C) 2000 Philippe C.D. Robert
#
#  Written by: Philippe C.D. Robert <robert@iam.unibe.ch>
#
#  This file is part of the ProjectCenter.
#
#  This library is free software; you can redistribute it and/or
#  modify it under the terms of the GNU Library General Public
#  License as published by the Free Software Foundation; either
#  version 2 of the License, or (at your option) any later version.
#
#  This library is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.	 See the GNU
#  Library General Public License for more details.
#
#  You should have received a copy of the GNU Library General Public
#  License along with this library; if not, write to the Free
#  Software Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111 USA.
#

PCLIB_INSTALLATION_DIR = $(GNUSTEP_INSTALLATION_DIR)
GNUSTEP_MAKEFILES = $(GNUSTEP_SYSTEM_ROOT)/Makefiles

include $(GNUSTEP_MAKEFILES)/common.make

include ../Version

srcdir = .

PACKAGE_NAME = PCLib
LIBRARY_VAR = PCLIB

# The library to be compiled
LIBRARY_NAME=libProjectCenter

PCLIB_INSTALL_PREFIX=$(GNUSTEP_INSTALLATION_DIR)

# Grep for these names to build the legally-required "AUTHORS" file.
FILE_AUTHORS = 			\
	"Philippe C.D. Robert"

# The source files

libProjectCenter_MFILES = 	\
	PCBrowserController.m 	\
	PCBundleLoader.m 	\
	PCDataSource.m 		\
	PCEditorView.m		\
	PCFileManager.m 	\
	PCProject.m 		\
	PCProjectBuilder.m 	\
	PCProjectDebugger.m	\
	PCProjectManager.m 	\
	PCServer.m

libProjectCenter_CFILES = 

libProjectCenter_HFILES = 	\
	FileCreator.h 		\
	PCBrowserController.h 	\
	PCBundleLoader.h 	\
	PCDataSource.h 		\
	PCEditorView.h		\
	PCFileManager.h 	\
	PCProject.h 		\
	PCProjectBuilder.h 	\
	PCProjectDebugger.h	\
	PCProjectManager.h 	\
	PCServer.h 		\
	PreferenceController.h 	\
	ProjectBuilder.h 	\
	ProjectCenter.h 	\
	ProjectDebugger.h 	\
	ProjectEditor.h 	\
	ProjectType.h 		\
	Server.h

HEADERS_INSTALL = $(libProjectCenter_HFILES)

# The Objective-C source files to be compiled
libProjectCenter_OBJC_FILES 			= $(libProjectCenter_MFILES)

# The C source files to be compiled
libProjectCenter_C_FILES 			= $(libProjectCenter_CFILES)

# The headers
libProjectCenter_HEADER_FILES_DIR 		= .
libProjectCenter_HEADER_FILES_INSTALL_DIR 	= /ProjectCenter
libProjectCenter_HEADER_FILES 			= $(libProjectCenter_HFILES)

-include GNUmakefile.preamble

include $(GNUSTEP_MAKEFILES)/library.make

-include GNUmakefile.postamble
