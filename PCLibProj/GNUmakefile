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

BUNDLE_NAME = PCLibProj
BUNDLE_EXTENSION=.bundle
BUNDLE_INSTALL_DIR=$(GNUSTEP_INSTALLATION_DIR)/Library/ProjectCenter/

PCLibProj_OBJC_FILES = 		\
	PCLibProj.m 		\
	PCLibMakefileFactory.m 	\
	PCLibProject.m

PCLibProj_HEADERS= 		\
	PCLibMakefileFactory.h 	\
	PCLibProj.h 		\
	PCLibProject.h

PCLibProj_PRINCIPAL_CLASS = PCLibProj

PCLibProj_RESOURCE_FILES = 	\
	PC.proj			\
	Version			\
	LibProject.gmodel

-include GNUmakefile.preamble

-include GNUmakefile.local

include $(GNUSTEP_MAKEFILES)/bundle.make

-include GNUmakefile.postamble

