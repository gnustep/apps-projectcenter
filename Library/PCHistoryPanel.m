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
#include "PCProjectHistory.h"
#include "PCHistoryPanel.h"

@implementation PCHistoryPanel

- (id)initWithProjectManager:(PCProjectManager *)aManager
{
  PCProjectHistory *projectHistory;
  
  projectManager = aManager;

  projectHistory = [[aManager activeProject] projectHistory];

  self = [super initWithContentRect: NSMakeRect (0, 300, 480, 322)
                         styleMask: (NSTitledWindowMask 
		                    | NSClosableWindowMask
				    | NSResizableWindowMask)
			   backing: NSBackingStoreRetained
			     defer: YES];
  [self setMinSize: NSMakeSize(120, 23)];
  [self setFrameAutosaveName: @"ProjectHistory"];
  [self setReleasedWhenClosed: NO];
  [self setHidesOnDeactivate: YES];
  [self setTitle: [NSString stringWithFormat: 
    @"%@ - Project History", [[projectManager activeProject] projectName]]];

  contentBox = [[NSBox alloc] init];
  [contentBox setContentViewMargins:NSMakeSize(0.0, 0.0)];
  [contentBox setTitlePosition:NSNoTitle];
  [contentBox setBorderType:NSNoBorder];
  [self setContentView:contentBox];

  [self setContentView: [projectHistory componentView]];

  // Track project switching
  [[NSNotificationCenter defaultCenter] 
    addObserver:self
       selector:@selector(activeProjectDidChange:)
           name:ActiveProjectDidChangeNotification
         object:nil];

  if (![self setFrameUsingName: @"ProjectHistory"])
    {
      [self center];
    }

  return self;
}

- (void)dealloc
{
  NSLog (@"PCHistoryPanel: dealloc");
  [[NSNotificationCenter defaultCenter] removeObserver:self];
  
  [super dealloc];
}

- (void)setContentView:(NSView *)view
{
  if (view == contentBox)
    {
      [super setContentView:view];
    }
  else
    {
      [contentBox setContentView:view];
    }
}

- (void)activeProjectDidChange:(NSNotification *)aNotif
{
  PCProject *activeProject = [aNotif object];

  if (![self isVisible])
    {
      return;
    }

  [self setTitle: [NSString stringWithFormat: 
    @"%@ - Project History", [activeProject projectName]]];

  if (!activeProject)
    {
      [[contentBox contentView] removeFromSuperview];
    }
  else
    {
      [self setContentView:[[activeProject projectHistory] componentView]];
    }
}

@end

