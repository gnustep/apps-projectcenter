#  GNUmakefile
#
#  Copyright (C) 2001 Free Software Foundation, Inc.
#
#  Author: Philippe C.D. Robert <prh@3dkit.org>
#
#  This file is part of GNUstep 
#   
#   This program is free software; you can redistribute it and/or modify
#   it under the terms of the GNU General Public License as published by
#   the Free Software Foundation; either version 2 of the License, or
#   (at your option) any later version.
#   
#   This program is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#   GNU General Public License for more details.
#   
#   You should have received a copy of the GNU General Public License
#   along with this program; if not, write to the Free Software
#   Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.

GNUSTEP_INSTALLATION_DIR = $(GNUSTEP_SYSTEM_ROOT)

include $(GNUSTEP_MAKEFILES)/common.make

BUNDLE_NAME 			= PCBaseFileTypes
BUNDLE_EXTENSION		=.bundle
PCBaseFileTypes_PRINCIPAL_CLASS	= PCBaseFileType
BUNDLE_INSTALL_DIR		=$(GNUSTEP_INSTALLATION_DIR)/Library/ProjectCenter/

PCBaseFileTypes_OBJC_FILES = 		\
	PCBaseFileType.m

PCBaseFileTypes_HEADERS= 		\
	PCBaseFileType.h

PCBaseFileTypes_RESOURCE_FILES = 	\
	cfile.template 			\
	cheader.template 		\
	class.template 			\
	header.template			\
	protocol.template

-include GNUmakefile.preamble

include $(GNUSTEP_MAKEFILES)/bundle.make

-include GNUmakefile.postamble


