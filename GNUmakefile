# GNUmakefile: main makefile for GNUstep ProjectCenter
#
# Copyright (C) 2001 Free Software Foundation, Inc.
#
# Author:      Philippe C.D. Robert <phr@3dkit.org>
# Date:        2000
#
# This file is part of GNUstep.
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
#

# Install into the system root by default
GNUSTEP_INSTALLATION_DIR = $(GNUSTEP_SYSTEM_ROOT)

include $(GNUSTEP_MAKEFILES)/common.make

PACKAGE_NAME = ProjectCenter

#
# The list of subproject directories
#

SUBPROJECTS = 			\
	PCLib			\
	ProjectCenter		\
	PCAppProj		\
	PCGormProj		\
	PCBundleProj		\
	PCToolProj		\
	PCLibProj		\
	PCBaseFileTypes		\
	PCRenaissanceProj

-include GNUMakefile.preamble

include $(GNUSTEP_MAKEFILES)/aggregate.make

-include GNUMakefile.postamble


