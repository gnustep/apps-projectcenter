/*
   GNUstep ProjectCenter - http://www.gnustep.org

   Copyright (C) 2003 Free Software Foundation

   Author: Serg Stoyan <stoyan@on.com.ua>

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
*/

#include "PCProjectManager.h"
#include "PCProject.h"
#include "PCProjectLoadedFiles.h"
#include "PCLoadedFilesPanel.h"

@implementation PCLoadedFilesPanel

- (id)initWithProjectManager:(PCProjectManager *)aManager
{
  PCProjectLoadedFiles *projectLoadedFiles = nil;
  PCProject            *activeProject = nil;
  
  projectManager = aManager;
  activeProject = [projectManager rootActiveProject];
  projectLoadedFiles = [activeProject projectLoadedFiles];

  self = [super initWithContentRect: NSMakeRect (0, 300, 220, 322)
                         styleMask: (NSTitledWindowMask 
		                    | NSClosableWindowMask
				    | NSResizableWindowMask)
			   backing: NSBackingStoreRetained
			     defer: YES];
  [self setMinSize: NSMakeSize(120, 23)];
  [self setFrameAutosaveName: @"LoadedFiles"];
  [self setReleasedWhenClosed: NO];
  [self setHidesOnDeactivate: YES];
  [self setTitle: [NSString stringWithFormat: 
    @"%@ - Loaded Files", [activeProject projectName]]];

  contentBox = [[NSBox alloc] init];
  [contentBox setContentViewMargins:NSMakeSize(0.0, 0.0)];
  [contentBox setTitlePosition:NSNoTitle];
  [contentBox setBorderType:NSNoBorder];
  [self setContentView:contentBox];

  [contentBox setContentView:[projectLoadedFiles componentView]];

  // Track project switching
  [[NSNotificationCenter defaultCenter] 
    addObserver:self
       selector:@selector(activeProjectDidChange:)
           name:PCActiveProjectDidChangeNotification
         object:nil];

  if (![self setFrameUsingName: @"LoadedFiles"])
    {
      [self center];
    }

  return self;
}

- (void)dealloc
{
  NSLog (@"PCLoadedFilesPanel: dealloc");
  [[NSNotificationCenter defaultCenter] removeObserver:self];
  
  [super dealloc];
}

- (BOOL)canBecomeKeyWindow
{
  // Panels controls doesn't receive mouse click if return NO
  return YES;
}

- (void)activeProjectDidChange:(NSNotification *)aNotif
{
  PCProject *activeProject = [projectManager rootActiveProject];

  [self setTitle: [NSString stringWithFormat: 
    @"%@ - Loaded Files", [activeProject projectName]]];

  if (!activeProject)
    {
      [contentBox setContentView:nil];
    }
  else
    {
      [contentBox 
	setContentView:[[activeProject projectLoadedFiles] componentView]];
    }
}

@end

