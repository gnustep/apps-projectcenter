#
#  Main Makefile for ProjectCenter
#  
#  Copyright (C) 2000 Philippe C.D. Robert
#
#  Written by:	Philippe C.D. Robert <phr@projectcenter.ch>
#
#  This file is part of the ProjectCenter
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
#  Software Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111 USA
#

# Install into the system root by default
GNUSTEP_INSTALLATION_DIR = $(GNUSTEP_SYSTEM_ROOT)

GNUSTEP_MAKEFILES = $(GNUSTEP_SYSTEM_ROOT)/Makefiles

include $(GNUSTEP_MAKEFILES)/common.make

include ./Version

PACKAGE_NAME = ProjectCenter

#
# The list of subproject directories
#

SUBPROJECTS = 			\
	PCLib			\
	PCAppProj		\
	PCToolProj		\
	PCLibProj		\
	PCBaseFileTypes		\
	ProjectCenter

-include GNUMakefile.preamble

include $(GNUSTEP_MAKEFILES)/aggregate.make

-include GNUMakefile.postamble


