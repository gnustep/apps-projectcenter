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
#include "PCProjectBuilder.h"
#include "PCBuildPanel.h"

@implementation PCBuildPanel

- (id)initWithProjectManager:(PCProjectManager *)aManager
{
  PCProjectBuilder *projectBuilder = nil;
  PCProject        *activeProject = nil;
  
  projectManager = aManager;
  activeProject = [projectManager rootActiveProject];
  projectBuilder = [activeProject projectBuilder];
  
  self = [super initWithContentRect: NSMakeRect (0, 300, 480, 322)
                         styleMask: (NSTitledWindowMask 
		                    | NSClosableWindowMask
				    | NSResizableWindowMask)
			   backing: NSBackingStoreRetained
			     defer: YES];
  [self setMinSize: NSMakeSize(440, 222)];
  [self setFrameAutosaveName: @"ProjectBuilder"];
  [self setReleasedWhenClosed: NO];
  [self setHidesOnDeactivate: NO];
  [self setTitle: [NSString stringWithFormat: 
    @"%@ - Project Build", [activeProject projectName]]];

  contentBox = [[NSBox alloc] init];
  [contentBox setContentViewMargins:NSMakeSize(8.0, 0.0)];
  [contentBox setTitlePosition:NSNoTitle];
  [contentBox setBorderType:NSNoBorder];
  [super setContentView:contentBox];

  [contentBox setContentView:[projectBuilder componentView]];

  // Track project switching
  [[NSNotificationCenter defaultCenter] 
    addObserver:self
       selector:@selector(activeProjectDidChange:)
           name:PCActiveProjectDidChangeNotification
         object:nil];

  if (![self setFrameUsingName: @"ProjectBuilder"])
    {
      [self center];
    }

  return self;
}

- (void)dealloc
{
/*  NSLog (@"PCBuildPanel: dealloc (CV RC:%i)", 
	 [[contentBox contentView] retainCount]);*/
  [[NSNotificationCenter defaultCenter] removeObserver:self];
  
  [super dealloc];
}

- (void)activeProjectDidChange:(NSNotification *)aNotif
{
  PCProject *activeProject = [projectManager rootActiveProject];

  [self setTitle: [NSString stringWithFormat: 
    @"%@ - Project Build", [activeProject projectName]]];

  if (!activeProject)
    {
      [contentBox setContentView:nil];
    }
  else
    {
      [contentBox 
	setContentView:[[activeProject projectBuilder] componentView]];
    }
}

@end

