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
#include "PCProjectBrowser.h"
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
    initWithFrame:NSMakeRect(81,378,138,20)];
  [inspectorPopup setTarget:self];
  [inspectorPopup setAction:@selector(inspectorPopupDidChange:)];
  [contentView addSubview:inspectorPopup];
  
  [inspectorPopup addItemWithTitle:@"Build Attributes"];
  [inspectorPopup addItemWithTitle:@"Project Attributes"];
  [inspectorPopup addItemWithTitle:@"Project Description"];
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

  // Build Attributes
  [self createBuildAttributes];

  // Project Description
  [self createProjectDescription];

  // File Attributes
  [self createFileAttributes];

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
      [inspectorView setContentView: projectDescriptionView];
      break;
    case 3:
      [inspectorView setContentView:fileAttributesView];
      break;
    }

  [inspectorView display];
}

- (void)changeCommonProjectEntry:(id)sender
{
  NSString *newEntry = [sender stringValue];

  // Build Atributes
  if (sender == installPathField)
    {
      [project setProjectDictObject:newEntry forKey:PCInstallDir];
    }
  else if (sender == toolField)
    {
      [project setProjectDictObject:newEntry forKey:PCBuildTool];

      if (![[NSFileManager defaultManager] isExecutableFileAtPath:newEntry])
	{
	  NSRunAlertPanel(@"Build Tool Error!",
			  @"No valid executable found at '%@'!",
			  @"OK",nil,nil,newEntry);
	}
    }
  else if (sender == cppOptField)
    {
      [project setProjectDictObject:newEntry forKey:PCPreprocessorOptions];
    }
  else if (sender == objcOptField)
    {
      [project setProjectDictObject:newEntry forKey:PCObjCCompilerOptions];
    }
  else if (sender == cOptField)
    {
      [project setProjectDictObject:newEntry forKey:PCCompilerOptions];
    }
  else if ( sender == ldOptField )
    {
      [project setProjectDictObject:newEntry forKey:PCLinkerOptions];
    }
  // Project Description
  else if ( sender == descriptionField )
    {
      [project setProjectDictObject:newEntry forKey:PCDescription];
    }
  else if ( sender == releaseField )
    {
      [project setProjectDictObject:newEntry forKey:PCRelease];
    }
  else if ( sender == licenseField )
    {
      [project setProjectDictObject:newEntry forKey:PCCopyright];
    }
  else if ( sender == licDescriptionField )
    {
      [project setProjectDictObject:newEntry forKey:PCCopyrightDescription];
    }
  else if ( sender == urlField )
    {
      [project setProjectDictObject:newEntry forKey:PCURL];
    }
}

// ============================================================================
// ==== Notifications
// ============================================================================

- (void)activeProjectDidChange:(NSNotification *)aNotif
{
  project = [projectManager activeProject];
  projectDict = [project projectDict];

  NSLog (@"Active projectChanged to %@", 
	 [[project projectDict] objectForKey:PCProjectName]);

  [inspectorPanel setTitle: [NSString stringWithFormat: 
    @"%@ - Project Inspector", [project projectName]]];

  // 1. Get custom project attributes view
  projectAttributesView = [project projectAttributesView];

  // 2. Update values in UI elements
  [self updateValues:nil];

  // 3. Display current view
  [self inspectorPopupDidChange:inspectorPopup];
}

- (void)updateValues:(NSNotification *)aNotif
{
  // Build Attributes view
  searchHeaders = [projectDict objectForKey:PCSearchHeaders];
  searchLibs = [projectDict objectForKey:PCSearchLibs];
  [self searchOrderPopupDidChange:searchOrderPopup];

  [projectNameLabel setStringValue:[project projectName]];

  [cppOptField setStringValue:
    [projectDict objectForKey:PCPreprocessorOptions]];
  [objcOptField setStringValue:
    [projectDict objectForKey:PCObjCCompilerOptions]];
  [cOptField setStringValue:
    [projectDict objectForKey:PCCompilerOptions]];
  [ldOptField setStringValue:
    [projectDict objectForKey:PCLinkerOptions]];
  [installPathField setStringValue:
    [projectDict objectForKey:PCInstallDir]];
  [toolField setStringValue:
    [projectDict objectForKey:PCBuildTool]];
    
  // Project Description view
  [descriptionField setStringValue:
    [projectDict objectForKey:PCDescription]];
  [releaseField setStringValue:
    [projectDict objectForKey:PCRelease]];
  [licenseField setStringValue:
    [projectDict objectForKey:PCCopyright]];
  [licDescriptionField setStringValue:
    [projectDict objectForKey:PCCopyrightDescription]];
  [urlField setStringValue:
    [projectDict objectForKey:PCURL]];

  authorsItems = [projectDict objectForKey:PCAuthors];
//  NSLog(@"updateValues: %@",authorsItems);
  [authorsList reloadData];
}


// ============================================================================
// ==== Build Attributes
// ============================================================================

- (void)createBuildAttributes
{
  NSTextField *textField = nil;
  NSBox       *line = nil;

  if (buildAttributesView)
    {
      return;
    }

  buildAttributesView = [[NSBox alloc] init];
  [buildAttributesView setFrame:NSMakeRect(0,0,315,384)];
  [buildAttributesView setTitlePosition:NSNoTitle];
  [buildAttributesView 
    setAutoresizingMask:(NSViewWidthSizable | NSViewHeightSizable)];
  [buildAttributesView setContentViewMargins:NSMakeSize(0.0, 0.0)];

  // Project or subproject name
  projectNameLabel = [[NSTextField alloc] 
    initWithFrame:NSMakeRect(6,347,290,20)];
  [projectNameLabel setAlignment:NSCenterTextAlignment];
  [projectNameLabel setBordered:NO];
  [projectNameLabel setEditable:NO];
  [projectNameLabel setSelectable:NO];
  [projectNameLabel setBezeled:NO];
  [projectNameLabel setDrawsBackground:NO];
  [buildAttributesView addSubview:projectNameLabel];
  RELEASE(projectNameLabel);

  //
  line = [[NSBox alloc] initWithFrame:NSMakeRect(0,344,315,2)];
  [line setTitlePosition:NSNoTitle];
  [buildAttributesView addSubview:line];
  RELEASE(line);

  // Search Order
  searchOrderPopup = [[NSPopUpButton alloc] 
    initWithFrame:NSMakeRect(6,317,290,21)];
  [searchOrderPopup setTarget:self];
  [searchOrderPopup setAction:@selector(searchOrderPopupDidChange:)];
  [buildAttributesView addSubview:searchOrderPopup];
  [searchOrderPopup addItemWithTitle:@"Header Directories Search Order"];
  [searchOrderPopup addItemWithTitle:@"Library Directories Search Order"];
  [searchOrderPopup addItemWithTitle:@"Framework Directories Search Order"];
  [searchOrderPopup selectItemAtIndex:0];
  RELEASE(searchOrderPopup);

  //
  searchOrderColumn = [[NSTableColumn alloc] initWithIdentifier: @"SO List"];
  [searchOrderColumn setEditable:NO];

  searchOrderList = [[NSTableView alloc]
    initWithFrame:NSMakeRect(0,0,290,99)];
  [searchOrderList setAllowsMultipleSelection:NO];
  [searchOrderList setAllowsColumnReordering:NO];
  [searchOrderList setAllowsColumnResizing:NO];
  [searchOrderList setAllowsEmptySelection:YES];
  [searchOrderList setAllowsColumnSelection:NO];
  [searchOrderList setCornerView:nil];
  [searchOrderList setHeaderView:nil];
  [searchOrderList addTableColumn:searchOrderColumn];
  [searchOrderList setDataSource:self];

  // Hack! Should be [searchOrderList setDrawsGrid:NO]
  [searchOrderList setGridColor:[NSColor lightGrayColor]];
  [searchOrderList setTarget:self];
  [searchOrderList setDoubleAction:@selector(searchOrderDoubleClick:)];
  [searchOrderList setAction:@selector(searchOrderClick:)];

  //
  searchOrderScroll = [[NSScrollView alloc] initWithFrame:
    NSMakeRect (6,212,290,99)];
  [searchOrderScroll setDocumentView:searchOrderList];
  [searchOrderScroll setHasHorizontalScroller:NO];
  [searchOrderScroll setHasVerticalScroller:YES];
  [searchOrderScroll setBorderType:NSBezelBorder];
  RELEASE(searchOrderList);
  [buildAttributesView addSubview:searchOrderScroll];
  RELEASE(searchOrderScroll);

  //
  searchOrderTF = [[NSTextField alloc] initWithFrame:
    NSMakeRect (6,187,290,21)];
  [buildAttributesView addSubview:searchOrderTF];
  RELEASE(searchOrderTF);

  //
  searchOrderSet = [[NSButton alloc] initWithFrame:
    NSMakeRect (6,159,94,24)];
  [searchOrderSet setTitle: @"Set..."];
  [searchOrderSet setTarget: self];
  [searchOrderSet setAction: @selector(setSearchOrder:)];
  [searchOrderSet setButtonType: NSMomentaryPushButton];
  [buildAttributesView addSubview:searchOrderSet];
  RELEASE(searchOrderSet);

  searchOrderRemove = [[NSButton alloc] initWithFrame:
    NSMakeRect (104,159,94,24)];
  [searchOrderRemove setTitle: @"Remove"];
  [searchOrderRemove setTarget: self];
  [searchOrderRemove setAction: @selector(removeSearchOrder:)];
  [searchOrderRemove setButtonType: NSMomentaryPushButton];
  [buildAttributesView addSubview:searchOrderRemove];
  RELEASE(searchOrderRemove);
  
  searchOrderAdd = [[NSButton alloc] initWithFrame:
    NSMakeRect (202,159,94,24)];
  [searchOrderAdd setTitle: @"Add"];
  [searchOrderAdd setTarget: self];
  [searchOrderAdd setAction: @selector(addSearchOrder:)];
  [searchOrderAdd setButtonType: NSMomentaryPushButton];
  [buildAttributesView addSubview:searchOrderAdd];
  RELEASE(searchOrderAdd);

  [self setSearchOrderButtonsState];

  //
  line = [[NSBox alloc] initWithFrame:NSMakeRect(0,153,315,2)];
  [line setTitlePosition:NSNoTitle];
  [buildAttributesView addSubview:line];
  RELEASE(line);
  
  // Preprocessor flags -- ADDITIONAL_CPPFLAGS
  textField = [[NSTextField alloc] initWithFrame:NSMakeRect(6,126,124,21)];
  [textField setAlignment: NSRightTextAlignment];
  [textField setBordered: NO];
  [textField setEditable: NO];
  [textField setBezeled: NO];
  [textField setSelectable:NO];
  [textField setDrawsBackground: NO];
  [textField setStringValue:@"Preprocessor Flags:"];
  [buildAttributesView addSubview:textField];
  RELEASE(textField);

  cppOptField = [[NSTextField alloc] initWithFrame:NSMakeRect(132,126,164,21)];
  [cppOptField setAlignment: NSLeftTextAlignment];
  [cppOptField setBordered: YES];
  [cppOptField setEditable: YES];
  [cppOptField setBezeled: YES];
  [cppOptField setDrawsBackground: YES];
  [cppOptField setStringValue:@""];
  [cppOptField setAction:@selector(changeCommonProjectEntry:)];
  [cppOptField setTarget:self];
  [buildAttributesView addSubview:cppOptField];
  RELEASE(cppOptField);
  
  // ObjC compiler flags -- ADDITIONAL_OBJCFLAGS
  textField = [[NSTextField alloc] initWithFrame:NSMakeRect(6,102,124,21)];
  [textField setAlignment: NSRightTextAlignment];
  [textField setBordered: NO];
  [textField setEditable: NO];
  [textField setBezeled: NO];
  [textField setSelectable:NO];
  [textField setDrawsBackground: NO];
  [textField setStringValue:@"ObjC Compiler Flags:"];
  [buildAttributesView addSubview:textField];
  RELEASE(textField);

  objcOptField =[[NSTextField alloc] initWithFrame:NSMakeRect(132,102,164,21)];
  [objcOptField setAlignment: NSLeftTextAlignment];
  [objcOptField setBordered: YES];
  [objcOptField setEditable: YES];
  [objcOptField setBezeled: YES];
  [objcOptField setDrawsBackground: YES];
  [objcOptField setStringValue:@""];
  [objcOptField setAction:@selector(changeCommonProjectEntry:)];
  [objcOptField setTarget:self];
  [buildAttributesView addSubview:objcOptField];
  RELEASE(objcOptField);

  // Compiler Flags -- ADDITIONAL_OBJCFLAGS(?), ADDITIONAL_CFLAGS
  textField = [[NSTextField alloc] initWithFrame:NSMakeRect(6,78,124,21)];
  [textField setAlignment: NSRightTextAlignment];
  [textField setBordered: NO];
  [textField setEditable: NO];
  [textField setBezeled: NO];
  [textField setSelectable:NO];
  [textField setDrawsBackground: NO];
  [textField setStringValue:@"C Compiler Flags:"];
  [buildAttributesView addSubview:textField];
  RELEASE(textField);

  cOptField = [[NSTextField alloc] initWithFrame:NSMakeRect(132,78,164,21)];
  [cOptField setAlignment: NSLeftTextAlignment];
  [cOptField setBordered: YES];
  [cOptField setEditable: YES];
  [cOptField setBezeled: YES];
  [cOptField setDrawsBackground: YES];
  [cOptField setStringValue:@""];
  [cOptField setAction:@selector(changeCommonProjectEntry:)];
  [cOptField setTarget:self];
  [buildAttributesView addSubview:cOptField];
  RELEASE(cOptField);

  // Linker Flags -- ADDITIONAL_LDFLAGS
  textField = [[NSTextField alloc] initWithFrame:NSMakeRect(6,54,124,21)];
  [textField setAlignment: NSRightTextAlignment];
  [textField setBordered: NO];
  [textField setEditable: NO];
  [textField setBezeled: NO];
  [textField setSelectable:NO];
  [textField setDrawsBackground: NO];
  [textField setStringValue:@"Linker Flags:"];
  [buildAttributesView addSubview:textField];
  RELEASE(textField);

  ldOptField = [[NSTextField alloc] initWithFrame:NSMakeRect(132,54,164,21)];
  [ldOptField setAlignment: NSLeftTextAlignment];
  [ldOptField setBordered: YES];
  [ldOptField setEditable: YES];
  [ldOptField setBezeled: YES];
  [ldOptField setDrawsBackground: YES];
  [ldOptField setStringValue:@""];
  [ldOptField setAction:@selector(changeCommonProjectEntry:)];
  [ldOptField setTarget:self];
  [buildAttributesView addSubview:ldOptField];
  RELEASE(ldOptField);

  // Install In
  textField = [[NSTextField alloc] initWithFrame:NSMakeRect(6,30,124,21)];
  [textField setAlignment: NSRightTextAlignment];
  [textField setBordered: NO];
  [textField setEditable: NO];
  [textField setBezeled: NO];
  [textField setSelectable:NO];
  [textField setDrawsBackground: NO];
  [textField setStringValue:@"Install In:"];
  [buildAttributesView addSubview:textField];
  RELEASE(textField);

  installPathField = [[NSTextField alloc] 
    initWithFrame:NSMakeRect(132,30,164,21)];
  [installPathField setAlignment: NSLeftTextAlignment];
  [installPathField setBordered: YES];
  [installPathField setEditable: YES];
  [installPathField setBezeled: YES];
  [installPathField setDrawsBackground: YES];
  [installPathField setStringValue:@""];
  [installPathField setAction:@selector(changeCommonProjectEntry:)];
  [installPathField setTarget:self];
  [buildAttributesView addSubview:installPathField];
  RELEASE(installPathField);

  // Build Tool
  textField =[[NSTextField alloc] initWithFrame:NSMakeRect(6,6,124,21)];
  [textField setAlignment: NSRightTextAlignment];
  [textField setBordered: NO];
  [textField setEditable: NO];
  [textField setBezeled: NO];
  [textField setSelectable:NO];
  [textField setDrawsBackground: NO];
  [textField setStringValue:@"Build Tool:"];
  [buildAttributesView addSubview:textField];
  RELEASE(textField);

  toolField =[[NSTextField alloc] initWithFrame:NSMakeRect(132,6,164,21)];
  [toolField setAlignment: NSLeftTextAlignment];
  [toolField setBordered: YES];
  [toolField setEditable: YES];
  [toolField setBezeled: YES];
  [toolField setDrawsBackground: YES];
  [toolField setStringValue:@""];
  [toolField setAction:@selector(changeCommonProjectEntry:)];
  [toolField setTarget:self];
  [buildAttributesView addSubview:toolField];
  RELEASE(toolField);

  // Link textfields
  [cppOptField setNextText:objcOptField];
  [objcOptField setNextText:cOptField];
  [cOptField setNextText:ldOptField];
  [ldOptField setNextText:installPathField];
  [installPathField setNextText:toolField];
  [toolField setNextText:cppOptField];
}

// ----------------------------------------------------------------------------
// --- Search Order
// ----------------------------------------------------------------------------
- (void)searchOrderPopupDidChange:(id)sender
{
  NSString *selectedTitle = [sender titleOfSelectedItem];
  
  if ([selectedTitle isEqualToString: @"Header Directories Search Order"])
    {
      ASSIGN(searchItems, searchHeaders);
    }
  else if ([selectedTitle isEqualToString: @"Library Directories Search Order"])
    {
      ASSIGN(searchItems, searchLibs);
    }
  else
    {
      ASSIGN(searchItems,nil);
    }

  // Enable/disable buttons according to selected/not selected item
  [self setSearchOrderButtonsState];

  [searchOrderList reloadData];
}

- (void)searchOrderDoubleClick:(id)sender
{
}

- (void)searchOrderClick:(id)sender
{
  // Warning! NSTableView doesn't call action method
  // TODO: Fix NSTableView (NSCell/NSActionCell?)
  [self setSearchOrderButtonsState];
}

- (void)setSearchOrderButtonsState
{
  // Disable until implemented
  [searchOrderSet setEnabled:NO];

  return; // See searchOrderClick
  
  if ([searchOrderList selectedRow] == -1)
    {
      [searchOrderRemove setEnabled:NO];
    }
  else
    {
      [searchOrderRemove setEnabled:YES];
    }
}

- (void)setSearchOrder:(id)sender
{
}

- (void)removeSearchOrder:(id)sender
{
  int row = [searchOrderList selectedRow];

  if (row != -1)
    {
      [searchItems removeObjectAtIndex:row];
      [self syncSearchOrder];

      [searchOrderList reloadData];
    }
}

- (void)addSearchOrder:(id)sender
{
  NSString *value = [searchOrderTF stringValue];

  [searchItems addObject:value];
  [searchOrderTF setStringValue:@""];
  [self syncSearchOrder];
  
  [searchOrderList reloadData];
}

- (void)syncSearchOrder
{
  int pIndex;

  pIndex = [searchOrderPopup indexOfSelectedItem];
  switch (pIndex)
    {
    case 0:
      [project setProjectDictObject:searchItems forKey:PCSearchHeaders];
      break;
    case 1:
      [project setProjectDictObject:searchItems forKey:PCSearchLibs];
      break;
    case 2:
      return;
    }
}

// ============================================================================
// ==== Project Description
// ============================================================================
- (void)createProjectDescription
{
  NSTextField *textField = nil;

  if (projectDescriptionView)
    {
      return;
    }

  projectDescriptionView = [[NSBox alloc] init];
  [projectDescriptionView setFrame:NSMakeRect(0,0,315,384)];
  [projectDescriptionView setTitlePosition:NSNoTitle];
  [projectDescriptionView 
    setAutoresizingMask:(NSViewWidthSizable | NSViewHeightSizable)];
  [projectDescriptionView setContentViewMargins:NSMakeSize(0.0, 0.0)];

  // Description
  textField = [[NSTextField alloc] initWithFrame:NSMakeRect(6,343,114,21)];
  [textField setAlignment: NSRightTextAlignment];
  [textField setBordered: NO];
  [textField setEditable: NO];
  [textField setBezeled: NO];
  [textField setSelectable:NO];
  [textField setDrawsBackground: NO];
  [textField setStringValue:@"Description:"];
  [projectDescriptionView addSubview:textField];
  RELEASE(textField);

  descriptionField = [[NSTextField alloc]
    initWithFrame:NSMakeRect(125,343,171,21)];
  [descriptionField setAlignment: NSLeftTextAlignment];
  [descriptionField setBordered: YES];
  [descriptionField setEditable: YES];
  [descriptionField setBezeled: YES];
  [descriptionField setDrawsBackground: YES];
  [descriptionField setStringValue:@""];
  [descriptionField setAction:@selector(changeCommonProjectEntry:)];
  [descriptionField setTarget:self];
  [projectDescriptionView addSubview:descriptionField];
  RELEASE(descriptionField);

  // Release
  textField = [[NSTextField alloc] initWithFrame:NSMakeRect(6,317,114,21)];
  [textField setAlignment: NSRightTextAlignment];
  [textField setBordered: NO];
  [textField setEditable: NO];
  [textField setBezeled: NO];
  [textField setSelectable:NO];
  [textField setDrawsBackground: NO];
  [textField setStringValue:@"Release:"];
  [projectDescriptionView addSubview:textField];
  RELEASE(textField);

  releaseField = [[NSTextField alloc] initWithFrame:NSMakeRect(125,317,171,21)];
  [releaseField setAlignment: NSLeftTextAlignment];
  [releaseField setBordered: YES];
  [releaseField setEditable: YES];
  [releaseField setBezeled: YES];
  [releaseField setDrawsBackground: YES];
  [releaseField setStringValue:@""];
  [releaseField setAction:@selector(changeCommonProjectEntry:)];
  [releaseField setTarget:self];
  [projectDescriptionView addSubview:releaseField];
  RELEASE(releaseField);

  // License
  textField = [[NSTextField alloc] initWithFrame:NSMakeRect(6,291,114,21)];
  [textField setAlignment: NSRightTextAlignment];
  [textField setBordered: NO];
  [textField setEditable: NO];
  [textField setBezeled: NO];
  [textField setSelectable:NO];
  [textField setDrawsBackground: NO];
  [textField setStringValue:@"License:"];
  [projectDescriptionView addSubview:textField];
  RELEASE(textField);

  licenseField = [[NSTextField alloc] initWithFrame:NSMakeRect(125,291,171,21)];
  [licenseField setAlignment: NSLeftTextAlignment];
  [licenseField setBordered: YES];
  [licenseField setEditable: YES];
  [licenseField setBezeled: YES];
  [licenseField setDrawsBackground: YES];
  [licenseField setStringValue:@""];
  [licenseField setAction:@selector(changeCommonProjectEntry:)];
  [licenseField setTarget:self];
  [projectDescriptionView addSubview:licenseField];
  RELEASE(licenseField);

  // License Description
  textField = [[NSTextField alloc] initWithFrame:NSMakeRect(6,265,114,21)];
  [textField setAlignment: NSRightTextAlignment];
  [textField setBordered: NO];
  [textField setEditable: NO];
  [textField setBezeled: NO];
  [textField setSelectable:NO];
  [textField setDrawsBackground: NO];
  [textField setStringValue:@"License Description:"];
  [projectDescriptionView addSubview:textField];
  RELEASE(textField);

  licDescriptionField = [[NSTextField alloc]
    initWithFrame:NSMakeRect(125,265,171,21)];
  [licDescriptionField setAlignment: NSLeftTextAlignment];
  [licDescriptionField setBordered: YES];
  [licDescriptionField setEditable: YES];
  [licDescriptionField setBezeled: YES];
  [licDescriptionField setDrawsBackground: YES];
  [licDescriptionField setStringValue:@""];
  [licDescriptionField setAction:@selector(changeCommonProjectEntry:)];
  [licDescriptionField setTarget:self];
  [projectDescriptionView addSubview:licDescriptionField];
  RELEASE(licDescriptionField);

  // URL
  textField = [[NSTextField alloc] initWithFrame:NSMakeRect(6,239,114,21)];
  [textField setAlignment: NSRightTextAlignment];
  [textField setBordered: NO];
  [textField setEditable: NO];
  [textField setBezeled: NO];
  [textField setSelectable:NO];
  [textField setDrawsBackground: NO];
  [textField setStringValue:@"URL:"];
  [projectDescriptionView addSubview:textField];
  RELEASE(textField);

  urlField = [[NSTextField alloc] initWithFrame:NSMakeRect(125,239,171,21)];
  [urlField setAlignment: NSLeftTextAlignment];
  [urlField setBordered: YES];
  [urlField setEditable: YES];
  [urlField setBezeled: YES];
  [urlField setDrawsBackground: YES];
  [urlField setStringValue:@""];
  [urlField setAction:@selector(changeCommonProjectEntry:)];
  [urlField setTarget:self];
  [projectDescriptionView addSubview:urlField];
  RELEASE(urlField);

  // Authors
  authorsBox = [[NSBox alloc] initWithFrame:NSMakeRect(6,97,290,138)];
  [authorsBox setTitle:@"Authors"];
  [authorsBox setContentViewMargins:NSMakeSize(0.0, 0.0)];
  
  authorsColumn = [[NSTableColumn alloc] initWithIdentifier: @"Authors List"];
  [authorsColumn setEditable:YES];

  authorsList = [[NSTableView alloc]
    initWithFrame:NSMakeRect(6,6,209,111)];
  [authorsList setAllowsMultipleSelection:NO];
  [authorsList setAllowsColumnReordering:NO];
  [authorsList setAllowsColumnResizing:NO];
  [authorsList setAllowsEmptySelection:YES];
  [authorsList setAllowsColumnSelection:NO];
  [authorsList setRowHeight:17.0];
  [authorsList setCornerView:nil];
  [authorsList setHeaderView:nil];
  [authorsList addTableColumn:authorsColumn];
  [authorsList setDataSource:self];

  //
  authorsScroll = [[NSScrollView alloc] initWithFrame:
    NSMakeRect (6,6,209,111)];
  [authorsScroll setDocumentView:authorsList];
  [authorsScroll setHasHorizontalScroller:NO];
  [authorsScroll setHasVerticalScroller:YES];
  [authorsScroll setBorderType:NSBezelBorder];
  RELEASE(authorsList);
  [authorsBox addSubview:authorsScroll];
  RELEASE(authorsScroll);

  //
  authorAdd = [[NSButton alloc] initWithFrame:NSMakeRect(220,93,60,24)];
  [authorAdd setRefusesFirstResponder:YES];
  [authorAdd setTitle: @"Add"];
  [authorAdd setTarget: self];
  [authorAdd setAction: @selector(addAuthor:)];
  [authorAdd setButtonType: NSMomentaryPushButton];
  [authorsBox addSubview:authorAdd];
  RELEASE(authorAdd);
  
  authorRemove = [[NSButton alloc] initWithFrame:NSMakeRect(220,64,60,24)];
  [authorRemove setRefusesFirstResponder:YES];
  [authorRemove setTitle:@"Remove"];
  [authorRemove setTarget:self];
  [authorRemove setAction:@selector(removeAuthor:)];
  [authorRemove setButtonType:NSMomentaryPushButton];
  [authorsBox addSubview:authorRemove];
  RELEASE(authorRemove);
  
  authorUp = [[NSButton alloc] initWithFrame:NSMakeRect(220,35,60,24)];
  [authorUp setRefusesFirstResponder:YES];
  [authorUp setImage: [NSImage imageNamed:@"common_ArrowUp"]];
  [authorUp setImagePosition:NSImageOnly];
  [authorUp setTarget:self];
  [authorUp setAction:@selector(upAuthor:)];
  [authorUp setButtonType:NSMomentaryPushButton];
  [authorsBox addSubview:authorUp];
  RELEASE(authorUp);
  
  authorDown = [[NSButton alloc] initWithFrame: NSMakeRect(220,6,60,24)];
  [authorDown setRefusesFirstResponder:YES];
  [authorDown setImage: [NSImage imageNamed:@"common_ArrowDown"]];
  [authorDown setImagePosition: NSImageOnly];
  [authorDown setTarget: self];
  [authorDown setAction: @selector(downAuthor:)];
  [authorDown setButtonType: NSMomentaryPushButton];
  [authorsBox addSubview:authorDown];
  RELEASE(authorDown);

  [projectDescriptionView addSubview:authorsBox];

  // Link textfields
  [descriptionField setNextText:releaseField];
  [releaseField setNextText:licenseField];
  [licenseField setNextText:licDescriptionField];
  [licDescriptionField setNextText:urlField];
  [urlField setNextText:descriptionField];
}

// --- Actions
- (void)addAuthor:(id)sender
{
  int row;

  [authorsItems addObject:[NSMutableString stringWithString:@""]];
  [authorsList reloadData];
  
  row = [authorsItems count] - 1;
  [authorsList selectRow:row byExtendingSelection:NO];
  [authorsList editColumn:0 row:row withEvent:nil select:YES];

  [project setProjectDictObject:authorsItems forKey:PCAuthors];
}

- (void)removeAuthor:(id)sender
{
  int selectedRow = [authorsList selectedRow];
  
  if (selectedRow >= 0)
  {
    [authorsItems removeObjectAtIndex:selectedRow];
    [authorsList reloadData];
  }
  
  if ([authorsList selectedRow] < 0 && [authorsItems count] > 0)
  {
    [authorsList selectRow:[authorsItems count]-1 byExtendingSelection:NO];
  }

  [project setProjectDictObject:authorsItems forKey:PCAuthors];
}

- (void)upAuthor:(id)sender
{
  int selectedRow = [authorsList selectedRow];
  id  previousRow;
  id  currentRow;

  if (selectedRow > 0)
  {
    previousRow = [[authorsItems objectAtIndex: selectedRow-1] copy];
    currentRow = [authorsItems objectAtIndex: selectedRow];
      
    [authorsItems replaceObjectAtIndex: selectedRow-1 withObject: currentRow];
    [authorsItems replaceObjectAtIndex: selectedRow withObject: previousRow];
  
    [authorsList selectRow: selectedRow-1 byExtendingSelection: NO];

    [authorsList reloadData];
    [project setProjectDictObject:authorsItems forKey:PCAuthors];
  }
}

- (void)downAuthor:(id)sender
{
  int selectedRow = [authorsList selectedRow];
  id  nextRow;
  id  currentRow;

  if (selectedRow < [authorsItems count]-1)
  {
    nextRow = [[authorsItems objectAtIndex: selectedRow+1] copy];
    currentRow = [authorsItems objectAtIndex: selectedRow];

    [authorsItems replaceObjectAtIndex: selectedRow+1 withObject: currentRow];
    [authorsItems replaceObjectAtIndex: selectedRow withObject: nextRow];

    [authorsList selectRow: selectedRow+1 byExtendingSelection: NO];

    [authorsList reloadData];
    [project setProjectDictObject:authorsItems forKey:PCAuthors];
  }
}

// ============================================================================
// ==== File Attributes
// ============================================================================

- (void)createFileAttributes
{
  NSBox *line = nil;

  if (fileAttributesView)
    {
      return;
    }

  fileAttributesView = [[NSBox alloc] init];
  [fileAttributesView setFrame:NSMakeRect(0,0,295,384)];
  [fileAttributesView setTitlePosition:NSNoTitle];
  [fileAttributesView setAutoresizingMask:
    (NSViewWidthSizable | NSViewHeightSizable)];
  [fileAttributesView setContentViewMargins:NSMakeSize(0.0, 0.0)];

  fileIconView = [[NSImageView alloc] initWithFrame:NSMakeRect(8,310,48,48)];
  [fileIconView setImage:nil];
  [fileAttributesView addSubview:fileIconView];
  RELEASE(fileIconView);

  fileNameField =[[NSTextField alloc] initWithFrame:NSMakeRect(60,310,236,48)];
  [fileNameField setAlignment: NSLeftTextAlignment];
  [fileNameField setBordered: NO];
  [fileNameField setEditable: NO];
  [fileNameField setSelectable: NO];
  [fileNameField setBezeled: NO];
  [fileNameField setDrawsBackground: NO];
  [fileNameField setFont:[NSFont systemFontOfSize:20.0]];
  [fileNameField setStringValue:@"No files selected"];
  [fileAttributesView addSubview:fileNameField];
  RELEASE(fileNameField);

  line = [[NSBox alloc] initWithFrame:NSMakeRect(0,298,315,2)];
  [line setTitlePosition:NSNoTitle];
  [fileAttributesView addSubview:line];
  RELEASE(line);

  [[NSNotificationCenter defaultCenter] 
    addObserver:self
       selector:@selector(browserDidSetPath:)
           name:PCBrowserDidSetPathNotification
         object:[project projectBrowser]];
}

- (void)browserDidSetPath:(NSNotification *)aNotif
{
  NSString *fileName = [[aNotif object] nameOfSelectedFile];

  if (fileName)
    {
      [fileNameField setStringValue:fileName];
    }
  else
    {
      [fileNameField setStringValue:@"No files selected"];
    }
}

// ============================================================================
// ==== NSTableViews
// ============================================================================

- (int)numberOfRowsInTableView: (NSTableView *)aTableView
{
  if (searchOrderList != nil && aTableView == searchOrderList)
    {
      return [searchItems count];
    }
  else if (authorsList != nil && aTableView == authorsList)
    {
      return [authorsItems count];
    }

  return 0;
}
    
- (id)            tableView: (NSTableView *)aTableView
  objectValueForTableColumn: (NSTableColumn *)aTableColumn
                        row: (int)rowIndex
{
  if (searchOrderList != nil && aTableView == searchOrderList)
    {
      return [searchItems objectAtIndex:rowIndex];
    }
  else if (authorsList != nil && aTableView == authorsList)
    {
      return [authorsItems objectAtIndex:rowIndex];
    }

  return nil;
}
  
- (void) tableView:(NSTableView *)aTableView
    setObjectValue:anObject
    forTableColumn:(NSTableColumn *)aTableColumn
               row:(int)rowIndex
{
  if (authorsList != nil && aTableView == authorsList)
    {
      if([authorsItems count] <= 0)
	{
	  return;
	}
	
      [authorsItems removeObjectAtIndex:rowIndex];
      [authorsItems insertObject:anObject atIndex:rowIndex];

      [project setProjectDictObject:authorsItems forKey:PCAuthors];
    }
}

@end
