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

#include "PCProject+UInterface.h"
#include "PCProject+ComponentHandling.h"
#include "PCSplitView.h"
#include "PCHistoryController.h"
#include "PCBrowserController.h"
#include "PCDefines.h"

#include "PCButton.h"

#undef ENABLE_HISTORY

@implementation PCProject (UInterface)

- (void)_initUI
{
  NSView       *_c_view;
  unsigned int style = NSTitledWindowMask 
                     | NSClosableWindowMask
		     | NSMiniaturizableWindowMask
		     | NSResizableWindowMask;
  NSBrowser    *browser;
  NSRect       rect;
  PCButton     *buildButton;
  PCButton     *launchButton;
  PCButton     *editorButton;
  PCButton     *loadedFilesButton;
  PCButton     *findButton;
  PCButton     *inspectorButton;
  id           textField;
  PCSplitView  *split;

#ifdef ENABLE_HISTORY
  PCSplitView  *v_split;
  NSBrowser    *history;
#endif

  /*
   * Project Window
   */

  rect = NSMakeRect (100,100,560,448);
  projectWindow = [[NSWindow alloc] initWithContentRect: rect
                                              styleMask: style
                                                backing: NSBackingStoreBuffered
                                                  defer: YES];
  [projectWindow setDelegate: self];
  [projectWindow setMinSize: NSMakeSize (560,448)];
  [projectWindow setFrameAutosaveName: @"ProjectWindow"];
  _c_view = [projectWindow contentView];

  /*
   * Tool bar
   */
  buildButton = [[PCButton alloc] initWithFrame: NSMakeRect(8,390,50,50)];
  [buildButton setTitle: @"Build"];
//  [buildButton setImage: IMAGE(@"Build")];
  [buildButton setImage: IMAGE(@"ProjectCenter_make")];
  [buildButton setTarget: self];
  [buildButton setAction: @selector(showBuildView:)];
  [buildButton setAutoresizingMask: (NSViewMaxXMargin | NSViewMinYMargin)];
  [buildButton setButtonType: NSMomentaryPushButton];
  [_c_view addSubview: buildButton];
  [buildButton setShowTooltip:YES];
  RELEASE (buildButton);
  
  launchButton = [[PCButton alloc] initWithFrame: NSMakeRect(58,390,50,50)];
  [launchButton setTitle: @"Launch"];
//  [launchButton setImage: IMAGE(@"Run")];
  [launchButton setImage: IMAGE(@"ProjectCenter_run")];
  [launchButton setTarget: self];
  [launchButton setAction: @selector(showRunView:)];
  [launchButton setAutoresizingMask: (NSViewMaxXMargin | NSViewMinYMargin)];
  [launchButton setButtonType: NSMomentaryPushButton];
  [_c_view addSubview: launchButton];
  [launchButton setShowTooltip:YES];
  RELEASE (launchButton);
  
  editorButton = [[PCButton alloc] initWithFrame: NSMakeRect(108,390,50,50)];
  [editorButton setTitle: @"Editor"];
//  [editorButton setImage: IMAGE(@"Editor")];
  [editorButton setImage: IMAGE(@"ProjectCenter_files")];
  [editorButton setTarget: self];
  [editorButton setAction: @selector(showEditorView:)];
  [editorButton setAutoresizingMask: (NSViewMaxXMargin | NSViewMinYMargin)];
  [editorButton setButtonType: NSMomentaryPushButton];
  [_c_view addSubview: editorButton];
  [editorButton setShowTooltip:YES];
  RELEASE (editorButton);

  loadedFilesButton = [[PCButton alloc] initWithFrame: NSMakeRect(158,390,50,50)];
  [loadedFilesButton setTitle: @"Loaded Files"];
//  [loadedFilesButton setImage: IMAGE(@"Files")];
  [loadedFilesButton setImage: IMAGE(@"ProjectCenter_files")];
  [loadedFilesButton setTarget: self];
  [loadedFilesButton setAction: @selector(showLoadedFilesView:)];
  [loadedFilesButton setAutoresizingMask: (NSViewMaxXMargin 
					   | NSViewMinYMargin)];
  [loadedFilesButton setButtonType: NSMomentaryPushButton];
//  [loadedFilesButton setEnabled:NO];
  [_c_view addSubview: loadedFilesButton];
  [loadedFilesButton setShowTooltip:YES];
  RELEASE (loadedFilesButton);

  findButton = [[PCButton alloc] initWithFrame: NSMakeRect(208,390,50,50)];
  [findButton setTitle: @"Project Find"];
//  [findButton setImage: IMAGE(@"Find")];
  [findButton setImage: IMAGE(@"ProjectCenter_find")];
  [findButton setTarget: self];
  [findButton setAction: @selector(showFindView:)];
  [findButton setAutoresizingMask: (NSViewMaxXMargin | NSViewMinYMargin)];
  [findButton setButtonType: NSMomentaryPushButton];
//  [findButton setEnabled:NO];
  [_c_view addSubview: findButton];
  [findButton setShowTooltip:YES];
  RELEASE (findButton);
  
  inspectorButton = [[PCButton alloc] initWithFrame: NSMakeRect(258,390,50,50)];
  [inspectorButton setTitle: @"Inspector"];
//  [inspectorButton setImage: IMAGE(@"Inspector")];
  [inspectorButton setImage: IMAGE(@"ProjectCenter_settings")];
  [inspectorButton setTarget: self];
  [inspectorButton setAction: @selector(showInspector:)];
  [inspectorButton setAutoresizingMask:(NSViewMaxXMargin | NSViewMinYMargin)];
  [inspectorButton setButtonType: NSMomentaryPushButton];
  [_c_view addSubview: inspectorButton];
  [inspectorButton setShowTooltip:YES];
  RELEASE (inspectorButton);
  

  /*
   * File icon and title
   */
  fileIcon = [[NSButton alloc] initWithFrame: NSMakeRect (504,391,48,48)];
  [fileIcon setBordered:NO];
  [fileIcon setEnabled:NO];
  [fileIcon setAutoresizingMask: (NSViewMinXMargin | NSViewMinYMargin)];
  [fileIcon setImagePosition: NSImageOnly];
  [fileIcon setImage: IMAGE (@"projectSuitcase")];
  [_c_view addSubview: fileIcon];
  RELEASE (fileIcon);

  fileIconTitle = [[NSTextField alloc]
    initWithFrame: NSMakeRect (316,395,180,21)];
  [fileIconTitle setAutoresizingMask: (NSViewMinXMargin 
				       | NSViewMinYMargin 
				       | NSViewWidthSizable)];
  [fileIconTitle setEditable:NO];
  [fileIconTitle setSelectable:NO];
  [fileIconTitle setDrawsBackground: NO];
  [fileIconTitle setAlignment:NSRightTextAlignment];
  [fileIconTitle setBezeled:NO];
  [_c_view addSubview: fileIconTitle];
  RELEASE (fileIconTitle);

  [[NSNotificationCenter defaultCenter] 
    addObserver: self
       selector: @selector (setFileIcon:)
           name: PCBrowserDidSetPathNotification
         object: nil];


  /*
   * File Browser
   */
  browserController = [[PCBrowserController alloc] init];

  browser = [[NSBrowser alloc] initWithFrame: NSMakeRect (-1,251,562,128)];
  [browser setDelegate: browserController];
  [browser setAutoresizingMask: NSViewWidthSizable | NSViewMinYMargin];

  [browserController setBrowser: browser];
  [browserController setProject: self];

#ifdef ENABLE_HISTORY
  historyController = [[PCHistoryController alloc] initWithProject:self];

  history = [[NSBrowser alloc] initWithFrame:NSMakeRect(320,372,100,60)];
  [history setDelegate: historyController];
  [history setMaxVisibleColumns: 1];
  [history setAllowsMultipleSelection: NO];
  [history setHasHorizontalScroller: NO];
  [history setAutoresizingMask: NSViewWidthSizable | NSViewMinYMargin];

  [historyController setBrowser: history];
  
  rect = [[projectWindow contentView] frame];
  rect.size.width -= 16;
  rect.size.height /= 2;
  v_split = [[PCSplitView alloc] initWithFrame: rect];
  [v_split setAutoresizingMask: (NSViewWidthSizable | NSViewHeightSizable)];
  [v_split setVertical: YES];

  [v_split addSubview: browser];
  [v_split addSubview: history];
  [v_split adjustSubviews];

  RELEASE (history);
#endif

  // Box
  box = [[NSBox alloc] initWithFrame: NSMakeRect (-1,-1,562,252)];
  [box setTitlePosition: NSNoTitle];
  [box setBorderType: NSNoBorder];
  [box setContentViewMargins: NSMakeSize(0.0,0.0)];
  [box setAutoresizingMask: NSViewWidthSizable | NSViewHeightSizable];

  // Editor in the Box
  [self showEditorView: self];

  rect = [[projectWindow contentView] frame];
  rect.size.height -= 62;
  rect.size.width -= 16;
  rect.origin.x += 8;
  rect.origin.y = -2;
  split = [[PCSplitView alloc] initWithFrame:rect];
  [split setAutoresizingMask: (NSViewWidthSizable | NSViewHeightSizable)];

#ifdef ENABLE_HISTORY
  [split addSubview: v_split];
#else
  [split addSubview: browser];
#endif

  [split addSubview: box];
  [split adjustSubviews];
  [_c_view addSubview: split];

  RELEASE(split);
  RELEASE(browser);

  [browser loadColumnZero];

#ifdef ENABLE_HISTORY
  [history loadColumnZero];
#endif

  if (![projectWindow setFrameUsingName: @"ProjectWindow"])
    {
      [projectWindow center];
    }

//--------------------------------------------------------------------------
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
}

- (void)setFileIcon:(NSNotification *)notification
{
  id       object = [notification object];
  NSString *path = [object pathOfSelectedFile];
  NSArray  *pathComps = [path pathComponents];
  NSString *lastComp = [path lastPathComponent];
  NSString *extension = [[lastComp componentsSeparatedByString:@"."] lastObject];
 
//  NSLog (@"PCP+UI %i -- %@", [pathComps count], path);

  // Should be provided by PC*Proj bundles
  if ([[object selectedFiles] count] > 1
      && [pathComps count] > 2)
    {
      [fileIcon setImage: IMAGE (@"MultipleSelection")];
    }
  else if ([lastComp isEqualToString: @"/"])
    {
      [fileIcon setImage: IMAGE (@"projectSuitcase")];
    }
  else if ([lastComp isEqualToString: @"Classes"])
    {
      [fileIcon setImage: IMAGE (@"classSuitcase")];
    }
  else if ([lastComp isEqualToString: @"Headers"])
    {
      [fileIcon setImage: IMAGE (@"headerSuitcase")];
    }
  else if ([lastComp isEqualToString: @"Other Sources"])
    {
      [fileIcon setImage: IMAGE (@"genericSuitcase")];
    }
  else if ([lastComp isEqualToString: @"Interfaces"])
    {
      [fileIcon setImage: IMAGE (@"nibSuitcase")];
    }
  else if ([lastComp isEqualToString: @"Images"])
    {
      [fileIcon setImage: IMAGE (@"iconSuitcase")];
    }
  else if ([lastComp isEqualToString: @"Other Resources"])
    {
      [fileIcon setImage: IMAGE (@"otherSuitcase")];
    }
  else if ([lastComp isEqualToString: @"Subprojects"])
    {
      [fileIcon setImage: IMAGE (@"subprojectSuitcase")];
    }
  else if ([lastComp isEqualToString: @"Documentation"])
    {
      [fileIcon setImage: IMAGE (@"helpSuitcase")];
    }
  else if ([lastComp isEqualToString: @"Supporting Files"])
    {
      [fileIcon setImage: IMAGE (@"genericSuitcase")];
    }
  else if ([lastComp isEqualToString: @"Libraries"])
    {
      [fileIcon setImage: IMAGE (@"librarySuitcase")];
    }
  else if ([lastComp isEqualToString: @"Non Project Files"])
    {
      [fileIcon setImage: IMAGE (@"projectSuitcase")];
    }
  else 
    {
      [fileIcon 
	setImage: [[NSWorkspace sharedWorkspace] iconForFileType:extension]];
    }

  // Set title
  if ([[object selectedFiles] count] > 1
      && [pathComps count] > 2)
    {
      [fileIconTitle setStringValue:
	[NSString stringWithFormat: 
	@"%i files", [[object selectedFiles] count]]];
    }
  else
    {
      [fileIconTitle setStringValue:lastComp];
    }
}

@end

