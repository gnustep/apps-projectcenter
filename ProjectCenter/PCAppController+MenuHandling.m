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

#import "PCAppController+MenuHandling.h"
#import "PCMenuController.h"
#import "PCPrefController.h"
#import "PCInfoController.h"

#import "PCProject+ComponentHandling.h"
#import "PCProjectManager.h"
#import "PCTextFinder.h"

@implementation PCAppController (MenuHandling)

- (void)showPrefWindow:(id)sender
{
  [prefController showPrefWindow:sender];
}

- (void)showInfoPanel:(id)sender
{
  [infoController showInfoWindow:sender];
}

- (void)showInspector:(id)sender
{
  [projectManager showInspectorForProject:[projectManager activeProject]];
}

- (void)showBuildPanel:(id)sender
{
  [[projectManager activeProject] showBuildView:self];
}

- (void)showFindPanel:(id)sender
{
  [[PCTextFinder sharedFinder] showFindPanel:self];
}

- (void)findNext:(id)sender
{
  [[PCTextFinder sharedFinder] findNext:self];
}

- (void)findPrevious:(id)sender
{
  [[PCTextFinder sharedFinder] findPrevious:self];
}

- (void)openProject:(id)sender
{
  [menuController openProject:sender];
}

- (void)newProject:(id)sender
{
  [menuController newProject:sender];
}

- (void)saveProject:(id)sender
{
  [menuController saveProject:sender];
}

- (void)saveProjectAs:(id)sender
{
  [menuController saveProjectAs:sender];
}

- (void)saveFiles:(id)sender
{
  [menuController saveFiles:sender];
}

- (void)revertToSaved:(id)sender
{
  [menuController revertToSaved:sender];
}

- (void)newSubproject:(id)sender
{
  [menuController newSubproject:sender];
}

- (void)addSubproject:(id)sender
{
  [menuController addSubproject:sender];
}

- (void)removeSubproject:(id)sender
{
  [menuController removeSubproject:sender];
}

- (void)closeProject:(id)sender
{
  [menuController closeProject:sender];
}

- (void)newFile:(id)sender
{
  [menuController newFile:sender];
}

- (void)addFile:(id)sender
{
  [menuController addFile:sender];
}

- (void)openFile:(id)sender
{
  [menuController openFile:sender];
}

- (void)saveFile:(id)sender
{
  [menuController saveFile:sender];
}

- (void)revertFile:(id)sender
{
  [menuController revertFile:sender];
}

- (void)renameFile:(id)sender
{
  [menuController renameFile:sender];
}

- (void)removeFile:(id)sender
{
  [menuController removeFile:sender];
}

- (BOOL)validateMenuItem:(id <NSMenuItem>)menuItem
{
    return [menuController validateMenuItem:menuItem];
}

@end
