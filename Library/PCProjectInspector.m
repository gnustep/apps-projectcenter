/*
   GNUstep ProjectCenter - http://www.gnustep.org

   Copyright (C) 2000-2002 Free Software Foundation

   Author: Philippe C.D. Robert <probert@siggraph.org>

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

#include "PCDefines.h"
#include "PCProjectManager.h"
#include "PCProject.h"
#include "PCProjectInspector.h"

@implementation PCProjectInspector

// ============================================================================
// ==== Intialization & deallocation
// ============================================================================

- (id)initWithProjectManager:(PCProjectManager *)manager
{
  projectManager = manager;

  [self _initUI];

  // Track project switching
  [[NSNotificationCenter defaultCenter] 
    addObserver:self
       selector:@selector(activeProjectDidChange:)
           name:ActiveProjectDidChangeNotification
         object:nil];

  [self inspectorPopupDidChange:inspectorPopup];

  return self;
}

- (void)close
{
  [inspectorPanel performClose:self];
}

- (void)dealloc
{
  NSLog (@"PCProjectInspector: dealloc");
  [[NSNotificationCenter defaultCenter] removeObserver:self];

  RELEASE(inspectorPanel);
  RELEASE(inspectorView);
  RELEASE(inspectorPopup);

  RELEASE(buildAttributesView);
  RELEASE(projectAttributesView);
  RELEASE(fileAttributesView);

  [super dealloc];
}

// ============================================================================
// ==== Panel & contents
// ============================================================================

// Should be GORM file in the future
- (void)_initUI
{
  // Panel
  inspectorPanel = [[NSPanel alloc] 
    initWithContentRect:NSMakeRect(200,300,300,404)
              styleMask:NSTitledWindowMask | NSClosableWindowMask
                backing:NSBackingStoreBuffered
                  defer:YES];
  [inspectorPanel setMinSize:NSMakeSize(300,404)];
  [inspectorPanel setTitle:@"Project Inspector"];
  [inspectorPanel setTitle: [NSString stringWithFormat:
    @"%@ - Project Inspector", [[projectManager activeProject] projectName]]];
  [inspectorPanel setReleasedWhenClosed:NO];
  [inspectorPanel setHidesOnDeactivate:YES];
  [inspectorPanel setFrameAutosaveName:@"Inspector"];

  [inspectorPanel setFrameUsingName:@"Inspector"];

  // Content
  contentView = [[NSBox alloc] init];
  [contentView setTitlePosition:NSNoTitle];
  [contentView setFrame:NSMakeRect(0,0,300,384)];
  [contentView setBorderType:NSNoBorder];
  [contentView setContentViewMargins:NSMakeSize(0.0, 0.0)];
  [inspectorPanel setContentView:contentView];

  inspectorPopup = [[NSPopUpButton alloc] 
    initWithFrame:NSMakeRect(90,378,128,20)];
  [inspectorPopup setTarget:self];
  [inspectorPopup setAction:@selector(inspectorPopupDidChange:)];
  [contentView addSubview:inspectorPopup];
  
  [inspectorPopup addItemWithTitle:@"Build Attributes"];
  [inspectorPopup addItemWithTitle:@"Project Attributes"];
  [inspectorPopup addItemWithTitle:@"File Attributes"];
  [inspectorPopup selectItemAtIndex:0];

  hLine = [[[NSBox alloc] init] autorelease];
  [hLine setTitlePosition:NSNoTitle];
  [hLine setFrame:NSMakeRect(0,356,280,2)];
  [contentView addSubview:hLine];

  // Holder of PC*Proj inspectors
  inspectorView = [[NSBox alloc] init];
  [inspectorView setTitlePosition:NSNoTitle];
  [inspectorView setFrame:NSMakeRect(-8,-8,315,384)];
  [inspectorView setBorderType:NSNoBorder];
  [contentView addSubview:inspectorView];

  [self activeProjectDidChange:nil];
}

- (NSPanel *)panel
{
  if (!inspectorPanel)
    {
      [self _initUI];
    }

  return inspectorPanel;
}

- (NSView *)contentView
{
  if (!contentView)
    {
      [self _initUI];
    }
    
  return contentView;
}

// ============================================================================
// ==== Actions
// ============================================================================

- (void)inspectorPopupDidChange:(id)sender
{
  switch([sender indexOfSelectedItem]) 
    {
    case 0:
       [inspectorView setContentView:buildAttributesView];
      break;
    case 1:
      [inspectorView setContentView: projectAttributesView];
      break;
    case 2:
      [inspectorView setContentView:fileAttributesView];
      break;
    }

  [inspectorView display];
}

// ============================================================================
// ==== Notifications
// ============================================================================

- (void)activeProjectDidChange:(NSNotification *)aNotif
{
  PCProject *project = [projectManager activeProject];

  NSLog (@"Active projectChanged to %@", 
	 [[project projectDict] objectForKey:PCProjectName]);

  [inspectorPanel setTitle: [NSString stringWithFormat: 
    @"%@ - Project Inspector", [project projectName]]];

  // 1. Fill buildAttributesView, projectAttributesView, fileAttributesView
  //    with current project's versions
  buildAttributesView = [project buildAttributesView];
  projectAttributesView = [project projectAttributesView];
  fileAttributesView = [project fileAttributesView];

  // 2. Display current view
  [self inspectorPopupDidChange:inspectorPopup];
}

@end
