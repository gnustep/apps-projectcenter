/*
   GNUstep ProjectCenter - http://www.gnustep.org

   Copyright (C) 2001 Free Software Foundation

   Author: Philippe C.D. Robert <phr@3dkit.org>

   This file is part of GNUstep.

   This application is free software; you can redistribute it and/or
   modify it under the terms of the GNU General Public
   License as published by the Free Software Foundation; either
   version 2 of the License, or (at your option) any later version.

   This application is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
   Library General Public License for more details.

   You should have received a copy of the GNU General Public
   License along with this library; if not, write to the Free
   Software Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111 USA.

   $Id$
*/

#import <AppKit/AppKit.h>
#import "PCAppController.h"

@interface PCAppController (MenuHandling)

- (void)showPrefWindow:(id)sender;
- (void)showInfoPanel:(id)sender;

- (void)showInspector:(id)sender;
- (void)showBuildPanel:(id)sender;

- (void)openProject:(id)sender;
- (void)newProject:(id)sender;
- (void)saveProject:(id)sender;
- (void)saveProjectAs:(id)sender;
- (void)showLoadedProjects:(id)sender;
- (void)saveFiles:(id)sender;
- (void)revertToSaved:(id)sender;

- (void)newSubproject:(id)sender;
- (void)addSubproject:(id)sender;
- (void)removeSubproject:(id)sender;

- (void)closeProject:(id)sender;

- (void)newFile:(id)sender;
- (void)addFile:(id)sender;
- (void)openFile:(id)sender;
- (void)saveFile:(id)sender;
- (void)saveFileAs:(id)sender;
- (void)revertFile:(id)sender;
- (void)renameFile:(id)sender;
- (void)removeFile:(id)sender;

@end



