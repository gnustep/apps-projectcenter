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

#define ENABLE_HISTORY

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
  NSBox        *hLine;
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

  history = [[NSBrowser alloc] initWithFrame:NSMakeRect(320,372,80,128)];
  [history setDelegate: historyController];
  [history setMaxVisibleColumns: 1];
  [history setAllowsMultipleSelection: NO];
  [history setHasHorizontalScroller: NO];
  [history setAutoresizingMask: NSViewWidthSizable | NSViewMinYMargin];

  [historyController setBrowser: history];
  
  rect = [[projectWindow contentView] frame];
  rect.size.height = 130;
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
  RELEASE(v_split);
#else
  [split addSubview: browser];
#endif

  [split addSubview: box];
  RELEASE(box);

  [split adjustSubviews];
  [_c_view addSubview: split];

  [browser loadColumnZero];

#ifdef ENABLE_HISTORY
  [history loadColumnZero];
#endif

  RELEASE(browser);
  RELEASE(split);

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
  [projectAttributeInspectorView setFrame:NSMakeRect(0,0,295,364)];
  [projectAttributeInspectorView setTitlePosition:NSNoTitle];
  [projectAttributeInspectorView 
    setAutoresizingMask:(NSViewWidthSizable | NSViewHeightSizable)];
  [projectAttributeInspectorView setContentViewMargins:NSMakeSize(0.0, 0.0)];

  // Compiler Flags -- ADDITIONAL_OBJCFLAGS(?), ADDITIONAL_CFLAGS
  textField =[[NSTextField alloc] initWithFrame:NSMakeRect(4,323,104,21)];
  [textField setAlignment: NSRightTextAlignment];
  [textField setBordered: NO];
  [textField setEditable: NO];
  [textField setBezeled: NO];
  [textField setDrawsBackground: NO];
  [textField setStringValue:@"Compiler Flags:"];
  [projectAttributeInspectorView addSubview:textField];
  RELEASE(textField);

  ccOptField =[[NSTextField alloc] initWithFrame:NSMakeRect(111,323,165,21)];
  [ccOptField setAlignment: NSLeftTextAlignment];
  [ccOptField setBordered: YES];
  [ccOptField setEditable: YES];
  [ccOptField setBezeled: YES];
  [ccOptField setDrawsBackground: YES];
  [ccOptField setStringValue:@""];
  [ccOptField setAction:@selector(changeCommonProjectEntry:)];
  [ccOptField setTarget:self];
  [projectAttributeInspectorView addSubview:ccOptField];
  RELEASE(ccOptField);

  // Linker Flags -- ADDITIONAL_LDFLAGS
  textField =[[NSTextField alloc] initWithFrame:NSMakeRect(4,298,104,21)];
  [textField setAlignment: NSRightTextAlignment];
  [textField setBordered: NO];
  [textField setEditable: NO];
  [textField setBezeled: NO];
  [textField setDrawsBackground: NO];
  [textField setStringValue:@"Linker Flags:"];
  [projectAttributeInspectorView addSubview:textField];
  RELEASE(textField);

  ldOptField =[[NSTextField alloc] initWithFrame:NSMakeRect(111,298,165,21)];
  [ldOptField setAlignment: NSLeftTextAlignment];
  [ldOptField setBordered: YES];
  [ldOptField setEditable: YES];
  [ldOptField setBezeled: YES];
  [ldOptField setDrawsBackground: YES];
  [ldOptField setStringValue:@""];
  [ldOptField setAction:@selector(changeCommonProjectEntry:)];
  [ldOptField setTarget:self];
  [projectAttributeInspectorView addSubview:ldOptField];
  RELEASE(ldOptField);

  // Install In
  textField =[[NSTextField alloc] initWithFrame:NSMakeRect(4,273,104,21)];
  [textField setAlignment: NSRightTextAlignment];
  [textField setBordered: NO];
  [textField setEditable: NO];
  [textField setBezeled: NO];
  [textField setDrawsBackground: NO];
  [textField setStringValue:@"Install In:"];
  [projectAttributeInspectorView addSubview:textField];
  RELEASE(textField);

  installPathField =[[NSTextField alloc] 
    initWithFrame:NSMakeRect(111,273,165,21)];
  [installPathField setAlignment: NSLeftTextAlignment];
  [installPathField setBordered: YES];
  [installPathField setEditable: YES];
  [installPathField setBezeled: YES];
  [installPathField setDrawsBackground: YES];
  [installPathField setStringValue:@""];
  [installPathField setAction:@selector(changeCommonProjectEntry:)];
  [installPathField setTarget:self];
  [projectAttributeInspectorView addSubview:installPathField];
  RELEASE(installPathField);

  // Build Tool
  textField =[[NSTextField alloc] initWithFrame:NSMakeRect(4,248,104,21)];
  [textField setAlignment: NSRightTextAlignment];
  [textField setBordered: NO];
  [textField setEditable: NO];
  [textField setBezeled: NO];
  [textField setDrawsBackground: NO];
  [textField setStringValue:@"Build Tool:"];
  [projectAttributeInspectorView addSubview:textField];
  RELEASE(textField);

  toolField =[[NSTextField alloc] initWithFrame:NSMakeRect(111,248,165,21)];
  [toolField setAlignment: NSLeftTextAlignment];
  [toolField setBordered: YES];
  [toolField setEditable: YES];
  [toolField setBezeled: YES];
  [toolField setDrawsBackground: YES];
  [toolField setStringValue:@""];
  [toolField setAction:@selector(changeCommonProjectEntry:)];
  [toolField setTarget:self];
  [projectAttributeInspectorView addSubview:toolField];
  RELEASE(toolField);

  // Public Headers In -- ADDITIONAL_INCLUDE_DIRS
  textField =[[NSTextField alloc] initWithFrame:NSMakeRect(4,223,104,21)];
  [textField setAlignment: NSRightTextAlignment];
  [textField setBordered: NO];
  [textField setEditable: NO];
  [textField setBezeled: NO];
  [textField setDrawsBackground: NO];
  [textField setStringValue:@"Public Headers In:"];
  [projectAttributeInspectorView addSubview:textField];
  RELEASE(textField);

  headersField =[[NSTextField alloc] initWithFrame:NSMakeRect(111,223,165,21)];
  [headersField setAlignment: NSLeftTextAlignment];
  [headersField setBordered: YES];
  [headersField setEditable: YES];
  [headersField setBezeled: YES];
  [headersField setDrawsBackground: YES];
  [headersField setStringValue:@""];
  [headersField setAction:@selector(changeCommonProjectEntry:)];
  [headersField setTarget:self];
  [projectAttributeInspectorView addSubview:headersField];
  RELEASE(headersField);

  // Public Libraries In -- ADDITIONAL_TOOL_LIBS
  textField =[[NSTextField alloc] initWithFrame:NSMakeRect(4,198,104,21)];
  [textField setAlignment: NSRightTextAlignment];
  [textField setBordered: NO];
  [textField setEditable: NO];
  [textField setBezeled: NO];
  [textField setDrawsBackground: NO];
  [textField setStringValue:@"Public Libraries In:"];
  [projectAttributeInspectorView addSubview:textField];
  RELEASE(textField);

  libsField =[[NSTextField alloc] initWithFrame:NSMakeRect(111,198,165,21)];
  [libsField setAlignment: NSLeftTextAlignment];
  [libsField setBordered: YES];
  [libsField setEditable: YES];
  [libsField setBezeled: YES];
  [libsField setDrawsBackground: YES];
  [libsField setStringValue:@""];
  [libsField setAction:@selector(changeCommonProjectEntry:)];
  [libsField setTarget:self];
  [projectAttributeInspectorView addSubview:libsField];
  RELEASE(libsField);


  /*
   * Project View
   *
   */

  projectProjectInspectorView = [[NSBox alloc] init];
  [projectProjectInspectorView setFrame:NSMakeRect(0,0,295,364)];
  [projectProjectInspectorView setTitlePosition:NSNoTitle];
  [projectProjectInspectorView 
    setAutoresizingMask:(NSViewWidthSizable | NSViewHeightSizable)];
  [projectProjectInspectorView setContentViewMargins:NSMakeSize(0.0, 0.0)];

  // Project Type
  textField = [[NSTextField alloc] initWithFrame:NSMakeRect(4,323,104,21)];
  [textField setAlignment: NSRightTextAlignment];
  [textField setBordered: NO];
  [textField setEditable: NO];
  [textField setBezeled: NO];
  [textField setDrawsBackground: NO];
  [textField setStringValue:@"Project Type:"];
  [projectProjectInspectorView addSubview:textField];
  RELEASE(textField);

  projectTypeField = [[NSTextField alloc] initWithFrame:
    NSMakeRect(111,323,165,21)];
  [projectTypeField setAlignment: NSLeftTextAlignment];
  [projectTypeField setBordered: NO];
  [projectTypeField setEditable: NO];
  [projectTypeField setSelectable: NO];
  [projectTypeField setBezeled: NO];
  [projectTypeField setDrawsBackground: NO];
  [projectTypeField setFont:[NSFont boldSystemFontOfSize: 12.0]];
  [projectTypeField setStringValue:@""];
  [projectProjectInspectorView addSubview:projectTypeField];
  RELEASE(projectTypeField);

  // Project Name
  textField = [[NSTextField alloc] initWithFrame:NSMakeRect(4,298,104,21)];
  [textField setAlignment: NSRightTextAlignment];
  [textField setBordered: NO];
  [textField setEditable: NO];
  [textField setBezeled: NO];
  [textField setDrawsBackground: NO];
  [textField setStringValue:@"Project Name:"];
  [projectProjectInspectorView addSubview:textField];
  RELEASE(textField);

  projectNameField = [[NSTextField alloc] initWithFrame:
    NSMakeRect(111,298,165,21)];
  [projectNameField setAlignment: NSLeftTextAlignment];
  [projectNameField setBordered: NO];
  [projectNameField setEditable: NO];
  [projectNameField setBezeled: YES];
  [projectNameField setDrawsBackground: YES];
  [projectNameField setStringValue:@""];
  [projectProjectInspectorView addSubview:projectNameField];
  RELEASE(projectNameField);

  // Project Language
  textField = [[NSTextField alloc] initWithFrame:NSMakeRect(4,273,104,21)];
  [textField setAlignment: NSRightTextAlignment];
  [textField setBordered: NO];
  [textField setEditable: NO];
  [textField setBezeled: NO];
  [textField setDrawsBackground: NO];
  [textField setStringValue:@"Language:"];
  [projectProjectInspectorView addSubview:textField];
  RELEASE(textField);

  projectLanguageField = [[NSTextField alloc] initWithFrame:
    NSMakeRect(111,273,165,21)];
  [projectLanguageField setAlignment: NSLeftTextAlignment];
  [projectLanguageField setBordered: NO];
  [projectLanguageField setEditable: NO];
  [projectLanguageField setBezeled: YES];
  [projectLanguageField setDrawsBackground: YES];
  [projectLanguageField setStringValue:@""];
  [projectProjectInspectorView addSubview:projectLanguageField];
  RELEASE(projectLanguageField);

  /*
   * File View
   *
   */

  projectFileInspectorView = [[NSBox alloc] init];
  [projectFileInspectorView setFrame:NSMakeRect(0,0,295,364)];
  [projectFileInspectorView setTitlePosition:NSNoTitle];
  [projectFileInspectorView setAutoresizingMask:
    (NSViewWidthSizable | NSViewHeightSizable)];
  [projectFileInspectorView setContentViewMargins:NSMakeSize(0.0, 0.0)];

  fileIconView = [[NSImageView alloc] initWithFrame:NSMakeRect(8,290,48,48)];
  [fileIconView setImage:[NSImage imageNamed:@"common_Unknown"]];
  [projectFileInspectorView addSubview:fileIconView];
  RELEASE(fileIconView);

  fileNameField =[[NSTextField alloc] initWithFrame:NSMakeRect(60,290,216,48)];
  [fileNameField setAlignment: NSLeftTextAlignment];
  [fileNameField setBordered: NO];
  [fileNameField setEditable: NO];
  [fileNameField setSelectable: NO];
  [fileNameField setBezeled: NO];
  [fileNameField setDrawsBackground: NO];
  [fileNameField setFont:[NSFont systemFontOfSize:20.0]];
  [fileNameField setStringValue:@"No file selected"];
  [projectFileInspectorView addSubview:fileNameField];
  RELEASE(fileNameField);
  
  hLine = [[NSBox alloc] initWithFrame:NSMakeRect(0,278,295,2)];
  [hLine setTitlePosition:NSNoTitle];
  [projectFileInspectorView addSubview:hLine];
  RELEASE(hLine);

  changeFileNameButton = [[NSButton alloc] initWithFrame:
    NSMakeRect(84,240,104,21)];
  [changeFileNameButton setTitle:@"Rename..."];
  [changeFileNameButton setTarget:self];
  [changeFileNameButton setAction:@selector(renameFile:)];
  [projectFileInspectorView addSubview:changeFileNameButton];
  RELEASE(changeFileNameButton);
}

- (void)setFileIcon:(NSNotification *)notification
{
  id       object = [notification object];
  NSString *path = [object pathOfSelectedFile];
  NSArray  *pathComps = [path pathComponents];
  NSString *lastComp = [path lastPathComponent];
  NSString *extension = [[lastComp componentsSeparatedByString:@"."] lastObject];
 
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
    
  if ([fileIcon image] == nil)
    {
      [fileIcon 
	setImage: [[NSWorkspace sharedWorkspace] iconForFileType:extension]];
    }

  // Set icon in Inspector "File Attributes". Should not be here!
  [fileIconView setImage:[fileIcon image]];

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

