#   GNUmakefile 
#
#   Copyright (C) 2000 Philippe C.D. Robert
#
#   Author:  Philippe C.D. Robert <phr@projectcenter.ch>
#   Date: 2000
#   
#   This file is part of ProjectCenter
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

include $(GNUSTEP_MAKEFILES)/common.make

BUNDLE_NAME 		= PCBundleProj
BUNDLE_EXTENSION	=.bundle
BUNDLE_INSTALL_DIR	=$(GNUSTEP_INSTALLATION_DIR)/Library/ProjectCenter/

PCBundleProj_OBJC_FILES = 		\
	PCBundleProj.m 			\
	PCBundleMakefileFactory.m 	\
	PCBundleProject.m 

PCBundleProj_HEADERS= 			\
	PCBundleMakefileFactory.h 	\
	PCBundleProj.h 			\
	PCBundleProject.h

PCBundleProj_PRINCIPAL_CLASS = PCBundleProj

PCBundleProj_RESOURCE_FILES = 	\
	PC.proj

-include GNUmakefile.preamble

include $(GNUSTEP_MAKEFILES)/bundle.make

-include GNUmakefile.postamble

