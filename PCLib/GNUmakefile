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

# Install into the system root by default
PCLIB_INSTALLATION_DIR = $(GNUSTEP_LOCAL_ROOT)
GNUSTEP_MAKEFILES = $(GNUSTEP_SYSTEM_ROOT)/Makefiles

include $(GNUSTEP_MAKEFILES)/common.make

include ../Version

srcdir = .

PACKAGE_NAME = PCLib
LIBRARY_VAR = PCLIB

# The library to be compiled
LIBRARY_NAME=libPC

PCLIB_INSTALL_PREFIX=$(GNUSTEP_LOCAL_ROOT)

# Grep for these names to build the legally-required "AUTHORS" file.
FILE_AUTHORS = 			\
	"Philippe C.D. Robert"

# The source files

libPC_MFILES = 			\
	PCBrowserController.m 	\
	PCBundleLoader.m 	\
	PCDataSource.m 		\
	PCFileManager.m 	\
	PCProject.m 		\
	PCProjectBuilder.m 	\
	PCProjectManager.m 	\
	PCServer.m

libPC_CFILES = 

libPC_HFILES = 			\
	FileCreator.h 		\
	PCBrowserController.h 	\
	PCBundleLoader.h 	\
	PCDataSource.h 		\
	PCFileManager.h 	\
	PCProject.h 		\
	PCProjectBuilder.h 	\
	PCProjectManager.h 	\
	PCServer.h 		\
	PreferenceController.h 	\
	ProjectBuilder.h 	\
	ProjectCenter.h 	\
	ProjectDebugger.h 	\
	ProjectEditor.h 	\
	ProjectType.h 		\
	Server.h

HEADERS_INSTALL = $(libPC_HFILES)

# The Objective-C source files to be compiled
libPC_OBJC_FILES 		= $(libPC_MFILES)

# The C source files to be compiled
libPC_C_FILES 			= $(libPC_CFILES)

# The headers
libPC_HEADER_FILES_DIR 		= .
libPC_HEADER_FILES_INSTALL_DIR 	= /ProjectCenter
libPC_HEADER_FILES 		= $(libPC_HFILES)

-include GNUmakefile.preamble

include $(GNUSTEP_MAKEFILES)/library.make



