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

   $Id$
*/

#import "PCProject+UInterface.h"
#import "PCSplitView.h"
#import "PCHistoryController.h"
#import "PCBrowserController.h"
#import "PCDefines.h"

#define ENABLE_HISTORY

@implementation PCProject (UInterface)

- (void)_initUI
{
  NSView *_c_view;
  unsigned int style = NSTitledWindowMask | NSClosableWindowMask | 
                       NSMiniaturizableWindowMask | NSResizableWindowMask;
  NSBrowser *browser;
  NSRect rect;
  NSMatrix* matrix;
  NSButtonCell* buttonCell = [[[NSButtonCell alloc] init] autorelease];
  id textField;
  id button;
  PCSplitView *split;

#ifdef ENABLE_HISTORY
  NSBrowser *history;
#endif

  browserController = [[PCBrowserController alloc] init];

  /*
   * Project Window
   *
   */

  rect = NSMakeRect(100,100,560,440);
  projectWindow = [[NSWindow alloc] initWithContentRect:rect
                                              styleMask:style
                                                backing:NSBackingStoreBuffered
                                                  defer:YES];
  [projectWindow setDelegate:self];
  [projectWindow setMinSize:NSMakeSize(560,448)];

  browser = [[NSBrowser alloc] initWithFrame:NSMakeRect(-1,251,562,128)];
  [browser setDelegate:browserController];
  [browser setMaxVisibleColumns:3];
  [browser setAllowsMultipleSelection:NO];
  [browser setAutoresizingMask: NSViewWidthSizable | NSViewMinYMargin];

  [browserController setBrowser:browser];
  [browserController setProject:self];
 
  box = [[NSBox alloc] initWithFrame:NSMakeRect (-1,-1,562,252)];
  [box setTitlePosition:NSNoTitle];
  [box setBorderType:NSNoBorder];
  [box setContentViewMargins: NSMakeSize(0.0,0.0)];
  [box setAutoresizingMask: NSViewWidthSizable | NSViewHeightSizable];

  textField = [[NSTextField alloc] initWithFrame:NSMakeRect(16,200,500,21)];
  [textField setAlignment: NSLeftTextAlignment];
  [textField setBordered: NO];
  [textField setEditable: NO];
  [textField setBezeled: NO];
  [textField setDrawsBackground: NO];
  [textField setStringValue:@"Welcome to ProjectCenter.app"];
  [box addSubview:textField];
  RELEASE(textField);

  rect = [[projectWindow contentView] frame];
  rect.size.height -= 76;
  rect.size.width -= 16;
  rect.origin.x += 8;
  split = [[PCSplitView alloc] initWithFrame:rect];
  [split setAutoresizingMask: (NSViewWidthSizable | NSViewHeightSizable)];

  _c_view = [projectWindow contentView];

  [split addSubview:browser];
  [split addSubview:box];
  [split adjustSubviews];
  [_c_view addSubview:split];

  RELEASE(split);
  RELEASE(browser);

  /*
   * File Browser
   */

#ifdef ENABLE_HISTORY
  historyController = [[PCHistoryController alloc] initWithProject:self];

  history = [[NSBrowser alloc] initWithFrame:NSMakeRect(320,372,232,60)];

  [history setDelegate:historyController];
  [history setMaxVisibleColumns:1];
  [history setAllowsMultipleSelection:NO];
  [history setHasHorizontalScroller:NO];
  [history setAutoresizingMask: NSViewWidthSizable | NSViewMinYMargin];
  
  [historyController setBrowser:history];

  [_c_view addSubview:history];
  RELEASE(history);
#endif
  /*
   * Left button matrix
   */

  rect = NSMakeRect(8,372,300,60);
  matrix = [[NSMatrix alloc] initWithFrame: rect
			     mode: NSHighlightModeMatrix
			     prototype: buttonCell
			     numberOfRows: 1
			     numberOfColumns: 5];
  [matrix setTarget:self];
  [matrix setAction:@selector(topButtonsPressed:)];
  [matrix setSelectionByRect:YES];
  [matrix setAutoresizingMask: (NSViewMaxXMargin | NSViewMinYMargin)];
  [_c_view addSubview:matrix];
  RELEASE(matrix);

  button = [matrix cellAtRow:0 column:0];
  [button setTag:BUILD_TAG];
  [button setImagePosition:NSImageAbove];
  [button setTitle:@"Build"];
  [button setImage:IMAGE(@"ProjectCentre_build")];
  [button setButtonType:NSMomentaryPushButton];

  button = [matrix cellAtRow:0 column:1];
  [button setTag:LAUNCH_TAG];
  [button setImagePosition:NSImageAbove];
  [button setTitle:@"Run"];
  [button setImage:IMAGE(@"ProjectCentre_run.tiff")];
  [button setButtonType:NSMomentaryPushButton];

  button = [matrix cellAtRow:0 column:2];
  [button setTag:SETTINGS_TAG];
  [button setImagePosition:NSImageAbove];
  [button setTitle:@"Settings"];
  [button setImage:IMAGE(@"ProjectCentre_settings.tiff")];
  [button setButtonType:NSMomentaryPushButton];

  button = [matrix cellAtRow:0 column:3];
  [button setTag:EDITOR_TAG];
  [button setImagePosition:NSImageAbove];
  [button setTitle:@"Editor"];
  [button setImage:IMAGE(@"ProjectCentre_files.tiff")];
  [button setButtonType:NSMomentaryPushButton];

  button = [matrix cellAtRow:0 column:4];
  [button setTag:PREFS_TAG];
  [button setImagePosition:NSImageAbove];
  [button setTitle:@"Options"];
  [button setImage:IMAGE(@"ProjectCentre_prefs.tiff")];
  [button setButtonType:NSMomentaryPushButton];

  [matrix sizeToCells];

  /*
   * Build Options Panel
   *
   */

  rect = NSMakeRect(100,100,272,80);
  style = NSTitledWindowMask | NSClosableWindowMask;
  buildTargetPanel = [[NSWindow alloc] initWithContentRect:rect 
				       styleMask:style 
				       backing:NSBackingStoreBuffered 
				       defer:YES];
  [buildTargetPanel setDelegate:self];
  [buildTargetPanel setReleasedWhenClosed:NO];
  [buildTargetPanel setTitle:@"Build Options"];
  _c_view = [buildTargetPanel contentView];

  // Host
  textField = [[NSTextField alloc] initWithFrame:NSMakeRect(16,24,56,21)];
  [textField setAlignment: NSRightTextAlignment];
  [textField setBordered: NO];
  [textField setEditable: NO];
  [textField setBezeled: NO];
  [textField setDrawsBackground: NO];
  [textField setStringValue:@"Host:"];
  [_c_view addSubview:textField];
  RELEASE(textField);

  // Host message
  buildTargetHostField = [[NSTextField alloc] initWithFrame:NSMakeRect(72,24,184,21)];
  [buildTargetHostField setAlignment: NSLeftTextAlignment];
  [buildTargetHostField setBordered: NO];
  [buildTargetHostField setEditable: YES];
  [buildTargetHostField setBezeled: YES];
  [buildTargetHostField setDrawsBackground: YES];
  [buildTargetHostField setStringValue:@"localhost"];
  [buildTargetHostField setDelegate:self];
  [buildTargetHostField setTarget:self];
  [buildTargetHostField setAction:@selector(setHost:)];
  [_c_view addSubview:buildTargetHostField];

  // Args
  textField = [[NSTextField alloc] initWithFrame:NSMakeRect(12,44,60,21)];
  [textField setAlignment: NSRightTextAlignment];
  [textField setBordered: NO];
  [textField setEditable: NO];
  [textField setBezeled: NO];
  [textField setDrawsBackground: NO];
  [textField setStringValue:@"Arguments:"];
  [_c_view addSubview:textField];
  RELEASE(textField);

  // Args message
  buildTargetArgsField = [[NSTextField alloc] initWithFrame:NSMakeRect(72,44,184,21)];
  [buildTargetArgsField setAlignment: NSLeftTextAlignment];
  [buildTargetArgsField setBordered: NO];
  [buildTargetArgsField setEditable: YES];
  [buildTargetArgsField setBezeled: YES];
  [buildTargetArgsField setDrawsBackground: YES];
  [buildTargetArgsField setStringValue:@""];
  [buildTargetArgsField setDelegate:self];
  [buildTargetArgsField setTarget:self];
  [buildTargetArgsField setAction:@selector(setArguments:)];
  [_c_view addSubview:buildTargetArgsField];

  /*
   * Model the standard inspector UI
   *
   */

  projectAttributeInspectorView = [[NSBox alloc] init];
  [projectAttributeInspectorView setFrame:NSMakeRect(-2,-2,284,334)];
  [projectAttributeInspectorView setTitlePosition:NSNoTitle];
  [projectAttributeInspectorView setBorderType:NSNoBorder];
  [projectAttributeInspectorView setAutoresizingMask:(NSViewWidthSizable | NSViewHeightSizable)];

  textField =[[NSTextField alloc] initWithFrame:NSMakeRect(16,280,64,21)];
  [textField setAlignment: NSRightTextAlignment];
  [textField setBordered: NO];
  [textField setEditable: NO];
  [textField setBezeled: NO];
  [textField setDrawsBackground: NO];
  [textField setStringValue:@"Install in:"];
  [projectAttributeInspectorView addSubview:textField];
  RELEASE(textField);

  installPathField =[[NSTextField alloc] initWithFrame:NSMakeRect(84,280,176,21)];
  [installPathField setAlignment: NSLeftTextAlignment];
  [installPathField setBordered: YES];
  [installPathField setEditable: YES];
  [installPathField setBezeled: YES];
  [installPathField setDrawsBackground: YES];
  [installPathField setStringValue:@""];
  [installPathField setAction:@selector(changeCommonProjectEntry:)];
  [installPathField setTarget:self];
  [projectAttributeInspectorView addSubview:installPathField];

  textField =[[NSTextField alloc] initWithFrame:NSMakeRect(16,256,64,21)];
  [textField setAlignment: NSRightTextAlignment];
  [textField setBordered: NO];
  [textField setEditable: NO];
  [textField setBezeled: NO];
  [textField setDrawsBackground: NO];
  [textField setStringValue:@"Build tool:"];
  [projectAttributeInspectorView addSubview:textField];
  RELEASE(textField);

  toolField =[[NSTextField alloc] initWithFrame:NSMakeRect(84,256,176,21)];
  [toolField setAlignment: NSLeftTextAlignment];
  [toolField setBordered: YES];
  [toolField setEditable: YES];
  [toolField setBezeled: YES];
  [toolField setDrawsBackground: YES];
  [toolField setStringValue:@""];
  [toolField setAction:@selector(changeCommonProjectEntry:)];
  [toolField setTarget:self];
  [projectAttributeInspectorView addSubview:toolField];

  textField =[[NSTextField alloc] initWithFrame:NSMakeRect(16,232,64,21)];
  [textField setAlignment: NSRightTextAlignment];
  [textField setBordered: NO];
  [textField setEditable: NO];
  [textField setBezeled: NO];
  [textField setDrawsBackground: NO];
  [textField setStringValue:@"CC options:"];
  [projectAttributeInspectorView addSubview:textField];
  RELEASE(textField);

  ccOptField =[[NSTextField alloc] initWithFrame:NSMakeRect(84,232,176,21)];
  [ccOptField setAlignment: NSLeftTextAlignment];
  [ccOptField setBordered: YES];
  [ccOptField setEditable: YES];
  [ccOptField setBezeled: YES];
  [ccOptField setDrawsBackground: YES];
  [ccOptField setStringValue:@""];
  [ccOptField setAction:@selector(changeCommonProjectEntry:)];
  [ccOptField setTarget:self];
  [projectAttributeInspectorView addSubview:ccOptField];

  textField =[[NSTextField alloc] initWithFrame:NSMakeRect(16,204,64,21)];
  [textField setAlignment: NSRightTextAlignment];
  [textField setBordered: NO];
  [textField setEditable: NO];
  [textField setBezeled: NO];
  [textField setDrawsBackground: NO];
  [textField setStringValue:@"LD options:"];
  [projectAttributeInspectorView addSubview:textField];
  RELEASE(textField);

  ldOptField =[[NSTextField alloc] initWithFrame:NSMakeRect(84,204,176,21)];
  [ldOptField setAlignment: NSLeftTextAlignment];
  [ldOptField setBordered: YES];
  [ldOptField setEditable: NO];
  [ldOptField setBezeled: YES];
  [ldOptField setDrawsBackground: YES];
  [ldOptField setStringValue:@""];
  [ldOptField setAction:@selector(changeCommonProjectEntry:)];
  [ldOptField setTarget:self];
  [projectAttributeInspectorView addSubview:ldOptField];

  /*
   * Project View
   *
   */

  projectProjectInspectorView = [[NSBox alloc] init];
  [projectProjectInspectorView setFrame:NSMakeRect(-2,-2,284,334)];
  [projectProjectInspectorView setTitlePosition:NSNoTitle];
  [projectProjectInspectorView setBorderType:NSNoBorder];
  [projectProjectInspectorView setAutoresizingMask:(NSViewWidthSizable | NSViewHeightSizable)];

  textField =[[NSTextField alloc] initWithFrame:NSMakeRect(16,280,64,21)];
  [textField setAlignment: NSRightTextAlignment];
  [textField setBordered: NO];
  [textField setEditable: NO];
  [textField setBezeled: NO];
  [textField setDrawsBackground: NO];
  [textField setStringValue:@"Type:"];
  [projectProjectInspectorView addSubview:textField];
  RELEASE(textField);

  projectTypeField = [[NSTextField alloc] initWithFrame:NSMakeRect(84,280,176,21)];
  [projectTypeField setAlignment: NSLeftTextAlignment];
  [projectTypeField setBordered: NO];
  [projectTypeField setEditable: NO];
  [projectTypeField setBezeled: NO];
  [projectTypeField setDrawsBackground: NO];
  [projectTypeField setStringValue:@""];
  [projectProjectInspectorView addSubview:projectTypeField];

  projectFileInspectorView = [[NSBox alloc] init];
  [projectFileInspectorView setFrame:NSMakeRect(-2,-2,284,334)];
  [projectFileInspectorView setTitlePosition:NSNoTitle];
  [projectFileInspectorView setBorderType:NSNoBorder];
  [projectFileInspectorView setAutoresizingMask:(NSViewWidthSizable | NSViewHeightSizable)];

  textField =[[NSTextField alloc] initWithFrame:NSMakeRect(16,280,64,21)];
  [textField setAlignment: NSRightTextAlignment];
  [textField setBordered: NO];
  [textField setEditable: NO];
  [textField setBezeled: NO];
  [textField setDrawsBackground: NO];
  [textField setStringValue:@"Filename:"];
  [projectFileInspectorView addSubview:textField];
  RELEASE(textField);

  fileNameField =[[NSTextField alloc] initWithFrame:NSMakeRect(84,280,176,21)];
  [fileNameField setAlignment: NSLeftTextAlignment];
  [fileNameField setBordered: NO];
  [fileNameField setEditable: NO];
  [fileNameField setBezeled: NO];
  [fileNameField setDrawsBackground: NO];
  [fileNameField setStringValue:@""];
  [projectFileInspectorView addSubview:fileNameField];

  changeFileNameButton = [[NSButton alloc] initWithFrame:NSMakeRect(84,240,104,21)];
  [changeFileNameButton setTitle:@"Rename..."];
  [changeFileNameButton setTarget:self];
  [changeFileNameButton setAction:@selector(renameFile:)];
  [projectFileInspectorView addSubview:changeFileNameButton];

  /*
   *
   */

  [browser loadColumnZero];
  
#ifdef ENABLE_HISTORY
  [history loadColumnZero];
#endif
}

@end
