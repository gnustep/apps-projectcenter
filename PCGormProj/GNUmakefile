#   GNUmakefile 
#
#   Copyright (C) 2000 Philippe C.D. Robert, Pierre-Yves Rivaille
#
#   Author:  Philippe C.D. Robert <phr@projectcenter.ch>
#   Date: 2000
#   Author:  Pierre-Yves Rivaille <pyrivail@ens-lyon.fr>
#   Date: 07/2001
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

BUNDLE_NAME 		= PCGormProj
BUNDLE_EXTENSION	=.bundle
BUNDLE_INSTALL_DIR	=$(GNUSTEP_LOCAL_ROOT)/Library/ProjectCenter/

PCGormProj_OBJC_FILES = 		\
	PCGormProj.m 		\
	PCGormMakefileFactory.m 	\
	PCGormProject.m 

PCGormProj_HEADERS= 		\
	PCGormMakefileFactory.h 	\
	PCGormProj.h 		\
	PCGormProject.h

PCGormProj_PRINCIPAL_CLASS = PCGormProj

PCGormProj_RESOURCE_FILES = 	\
	PC.proj 		\
	main.m			\
	baseInterface.classes	\
	baseInterface.gorm	\
	Info-project.plist

-include GNUmakefile.preamble

include $(GNUSTEP_MAKEFILES)/bundle.make

-include GNUmakefile.postamble

