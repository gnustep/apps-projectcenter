/*
   GNUstep ProjectCenter - http://www.gnustep.org

   Copyright (C) 2001 Free Software Foundation

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

#include <ProjectCenter/ProjectCenter.h>
#include <ProjectCenter/PCProjectBrowser.h>
#include "PCAppProject+Inspector.h"

@implementation PCAppProject (Inspector)

// ----------------------------------------------------------------------------
// --- User Interface
// ----------------------------------------------------------------------------

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
  [searchOrderPopup selectItemAtIndex:0];
  RELEASE(searchOrderPopup);
  
  [searchOrderPopup addItemWithTitle:@"Header Directories Search Order"];
  [searchOrderPopup addItemWithTitle:@"Library Directories Search Order"];
  [searchOrderPopup addItemWithTitle:@"Framework Directories Search Order"];

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

  searchHeaders = [projectDict objectForKey:PCSearchHeaders];
  searchLibs = [projectDict objectForKey:PCSearchLibs];
  ASSIGN(searchItems, searchHeaders);
  [searchOrderList reloadData];

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

  [self updateInspectorValues:nil];
}

- (void)createProjectAttributes
{
  NSTextField *textField = nil;
  NSBox       *_iconViewBox = nil;
  NSBox       *_iconsBox = nil;

  if (projectAttributesView)
    {
      return;
    }

  projectAttributesView = [[NSBox alloc] init];
  [projectAttributesView setFrame:NSMakeRect(0,0,295,384)];
  [projectAttributesView setTitlePosition:NSNoTitle];
  [projectAttributesView 
    setAutoresizingMask:(NSViewWidthSizable | NSViewHeightSizable)];
  [projectAttributesView setContentViewMargins:NSMakeSize(0.0, 0.0)];

  // Project Type
  textField = [[NSTextField alloc] initWithFrame:NSMakeRect(4,343,104,21)];
  [textField setAlignment: NSRightTextAlignment];
  [textField setBordered: NO];
  [textField setEditable: NO];
  [textField setBezeled: NO];
  [textField setDrawsBackground: NO];
  [textField setStringValue:@"Project Type:"];
  [projectAttributesView addSubview:textField];
  RELEASE(textField);

  projectTypeField = [[NSTextField alloc] initWithFrame:
    NSMakeRect(111,343,185,21)];
  [projectTypeField setAlignment: NSLeftTextAlignment];
  [projectTypeField setBordered: NO];
  [projectTypeField setEditable: NO];
  [projectTypeField setSelectable: NO];
  [projectTypeField setBezeled: NO];
  [projectTypeField setDrawsBackground: NO];
  [projectTypeField setFont:[NSFont boldSystemFontOfSize: 12.0]];
  [projectTypeField setStringValue:@""];
  [projectAttributesView addSubview:projectTypeField];
  RELEASE(projectTypeField);

  // Project Name
  textField = [[NSTextField alloc] initWithFrame:NSMakeRect(4,318,104,21)];
  [textField setAlignment: NSRightTextAlignment];
  [textField setBordered: NO];
  [textField setEditable: NO];
  [textField setBezeled: NO];
  [textField setDrawsBackground: NO];
  [textField setStringValue:@"Project Name:"];
  [projectAttributesView addSubview:textField];
  RELEASE(textField);

  projectNameField = [[NSTextField alloc] initWithFrame:
    NSMakeRect(111,318,185,21)];
  [projectNameField setAlignment: NSLeftTextAlignment];
  [projectNameField setBordered: NO];
  [projectNameField setEditable: NO];
  [projectNameField setBezeled: YES];
  [projectNameField setDrawsBackground: YES];
  [projectNameField setStringValue:@""];
  [projectAttributesView addSubview:projectNameField];
  RELEASE(projectNameField);

  // Project Language
  textField = [[NSTextField alloc] initWithFrame:NSMakeRect(4,293,104,21)];
  [textField setAlignment: NSRightTextAlignment];
  [textField setBordered: NO];
  [textField setEditable: NO];
  [textField setBezeled: NO];
  [textField setDrawsBackground: NO];
  [textField setStringValue:@"Language:"];
  [projectAttributesView addSubview:textField];
  RELEASE(textField);

  projectLanguageField = [[NSTextField alloc] initWithFrame:
    NSMakeRect(111,293,185,21)];
  [projectLanguageField setAlignment: NSLeftTextAlignment];
  [projectLanguageField setBordered: NO];
  [projectLanguageField setEditable: NO];
  [projectLanguageField setBezeled: YES];
  [projectLanguageField setDrawsBackground: YES];
  [projectLanguageField setStringValue:@""];
  [projectAttributesView addSubview:projectLanguageField];
  RELEASE(projectLanguageField);

  // Application Class
  textField = [[NSTextField alloc] initWithFrame:NSMakeRect(4,268,104,21)];
  [textField setAlignment: NSRightTextAlignment];
  [textField setBordered: NO];
  [textField setEditable: NO];
  [textField setBezeled: NO];
  [textField setDrawsBackground: NO];
  [textField setStringValue:@"Application Class:"];
  [projectAttributesView addSubview:textField];
  RELEASE(textField);

  appClassField = [[NSTextField alloc] initWithFrame:
    NSMakeRect(111,268,185,21)];
  [appClassField setAlignment: NSLeftTextAlignment];
  [appClassField setBordered: YES];
  [appClassField setEditable: YES];
  [appClassField setBezeled: YES];
  [appClassField setDrawsBackground: YES];
  [appClassField setStringValue:@""];
  [appClassField setTarget:self];
  [appClassField setAction:@selector(setAppClass:)];
  [projectAttributesView addSubview:appClassField];
  RELEASE(appClassField);

  // Icons, Main NIB file, Help file
  _iconsBox = [[NSBox alloc] init];
  [_iconsBox setFrame:NSMakeRect(6,6,290,259)];
  [_iconsBox setContentViewMargins:NSMakeSize(4.0, 4.0)];
  [_iconsBox setTitlePosition:NSNoTitle];
  [projectAttributesView addSubview:_iconsBox];

  // Icon view
  _iconViewBox = [[NSBox alloc] initWithFrame:NSMakeRect(220,189,56,56)];
  [_iconViewBox setTitlePosition:NSNoTitle];
  [_iconViewBox setBorderType:NSBezelBorder];
  [_iconViewBox setContentViewMargins:NSMakeSize(2.0, 2.0)];
  [_iconsBox addSubview:_iconViewBox];
  RELEASE(_iconViewBox);
  
  iconView = [[NSImageView alloc] initWithFrame:NSMakeRect(220,0,56,56)];
  [_iconViewBox addSubview:iconView];
  RELEASE(iconView);

  // Buttons
  setAppIconButton = [[NSButton alloc]
    initWithFrame:NSMakeRect(220,156,56,24)];
  [setAppIconButton setTitle:@"Set..."];
  [setAppIconButton setRefusesFirstResponder:YES];
  [setAppIconButton setTarget:self];
  [setAppIconButton setAction:@selector(setFile:)];
  [_iconsBox addSubview:setAppIconButton];
  RELEASE(setAppIconButton);

  clearAppIconButton = [[NSButton alloc]
    initWithFrame:NSMakeRect(220,128,56,24)];
  [clearAppIconButton setTitle:@"Clear"];
  [clearAppIconButton setRefusesFirstResponder:YES];
  [clearAppIconButton setTarget:self];
  [clearAppIconButton setAction:@selector(clearFile:)];
  [_iconsBox addSubview:clearAppIconButton];
  RELEASE(clearAppIconButton);

  // Application Icon
  textField = [[NSTextField alloc] initWithFrame:NSMakeRect(2,227,108,18)];
  [textField setAlignment: NSLeftTextAlignment];
  [textField setBordered: NO];
  [textField setEditable: NO];
  [textField setSelectable: NO];
  [textField setBezeled: NO];
  [textField setDrawsBackground: NO];
  [textField setStringValue:@"Application Icon:"];
  [_iconsBox addSubview:textField];
  RELEASE(textField);

  appImageField = [[NSTextField alloc] initWithFrame:NSMakeRect(2,206,211,21)];
  [appImageField setAlignment: NSLeftTextAlignment];
  [appImageField setBordered: YES];
  [appImageField setEditable: YES];
  [appImageField setBezeled: YES];
  [appImageField setDrawsBackground: YES];
  [appImageField setStringValue:@""];
  [appImageField setDelegate:self];
  [_iconsBox addSubview:appImageField];
  RELEASE(appImageField);
  
  // Help File
  textField = [[NSTextField alloc] initWithFrame:NSMakeRect(2,188,108,18)];
  [textField setAlignment: NSLeftTextAlignment];
  [textField setBordered: NO];
  [textField setEditable: NO];
  [textField setSelectable: NO];
  [textField setBezeled: NO];
  [textField setDrawsBackground: NO];
  [textField setStringValue:@"Help File:"];
  [_iconsBox addSubview:textField];
  RELEASE(textField);

  helpFileField = [[NSTextField alloc] initWithFrame:NSMakeRect(2,167,211,21)];
  [helpFileField setAlignment: NSLeftTextAlignment];
  [helpFileField setBordered: YES];
  [helpFileField setEditable: YES];
  [helpFileField setBezeled: YES];
  [helpFileField setDrawsBackground: YES];
  [helpFileField setStringValue:@""];
  [helpFileField setDelegate:self];
  [_iconsBox addSubview:helpFileField];
  RELEASE(helpFileField);
  
  // Main NIB File
  textField = [[NSTextField alloc] initWithFrame:NSMakeRect(2,149,108,18)];
  [textField setAlignment: NSLeftTextAlignment];
  [textField setBordered: NO];
  [textField setEditable: NO];
  [textField setSelectable: NO];
  [textField setBezeled: NO];
  [textField setDrawsBackground: NO];
  [textField setStringValue:@"Main Interface File:"];
  [_iconsBox addSubview:textField];
  RELEASE(textField);

  mainNIBField = [[NSTextField alloc] initWithFrame:NSMakeRect(2,128,211,21)];
  [mainNIBField setAlignment: NSLeftTextAlignment];
  [mainNIBField setBordered: YES];
  [mainNIBField setEditable: YES];
  [mainNIBField setBezeled: YES];
  [mainNIBField setDrawsBackground: YES];
  [mainNIBField setStringValue:@""];
  [mainNIBField setDelegate:self];
  [_iconsBox addSubview:mainNIBField];
  RELEASE(mainNIBField);

  RELEASE(_iconsBox);

  [self updateInspectorValues:nil];
}

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
         object:[self projectBrowser]];

  [self updateInspectorValues:nil];
}

- (NSView *)buildAttributesView
{
  if (!buildAttributesView)
    {
      [self createBuildAttributes];
    }

  return buildAttributesView;
}

- (NSView *)projectAttributesView
{
  if (!projectAttributesView)
    {
      [self createProjectAttributes];
    }
  return projectAttributesView;
}

- (NSView *)fileAttributesView
{
  if (!fileAttributesView)
    {
      [self createFileAttributes];
    }
  return fileAttributesView;
}

// ----------------------------------------------------------------------------
// --- Actions
// ----------------------------------------------------------------------------

- (void)changeCommonProjectEntry:(id)sender
{
  NSString *newEntry = [sender stringValue];

  if (sender == installPathField)
    {
      [projectDict setObject:newEntry forKey:PCInstallDir];
    }
  else if (sender == toolField)
    {
      [projectDict setObject:newEntry forKey:PCBuildTool];

      if (![[NSFileManager defaultManager] isExecutableFileAtPath:newEntry])
	{
	  NSRunAlertPanel(@"Build Tool Error!",
			  @"No valid executable found at '%@'!",
			  @"OK",nil,nil,newEntry);
	}
    }
  else if (sender == cppOptField)
    {
      [projectDict setObject:newEntry forKey:PCPreprocessorOptions];
    }
  else if (sender == objcOptField)
    {
      [projectDict setObject:newEntry forKey:PCObjCCompilerOptions];
    }
  else if (sender == cOptField)
    {
      [projectDict setObject:newEntry forKey:PCCompilerOptions];
    }
  else if ( sender == ldOptField )
    {
      [projectDict setObject:newEntry forKey:PCLinkerOptions];
    }

  [[NSNotificationCenter defaultCenter] 
    postNotificationName:PCProjectDictDidChangeNotification
                  object:self];
}

- (void)setAppClass:(id)sender
{
  [projectDict setObject:[appClassField stringValue] forKey:PCPrincipalClass];

  [[NSNotificationCenter defaultCenter] 
    postNotificationName:PCProjectDictDidChangeNotification
                  object:self];
}

- (void)setFile:(id)sender
{
/*  int         result;  
  NSArray     *fileTypes = [NSImage imageFileTypes];
  NSOpenPanel *openPanel = [NSOpenPanel openPanel];
  NSString    *dir = nil;*/

/*  NSLog(@"FR: %@", 
	[[[projectAttributesView superview] firstResponder] className]);*/
  id firstResponder = 
	[[[[self projectManager] projectInspector] panel] firstResponder];
  NSLog(@"FR: %@", [firstResponder className]);

/*  [openPanel setAllowsMultipleSelection:NO];
  
  dir = [[NSUserDefaults standardUserDefaults]
    objectForKey:@"LastOpenDirectory"];
  result = [openPanel runModalForDirectory:dir
                                      file:nil 
                                     types:fileTypes];

  if (result == NSOKButton)
    {
      NSString *imageFilePath = [[openPanel filenames] objectAtIndex:0];

      if (![self setAppIconWithImageAtPath:imageFilePath])
	{
	  NSRunAlertPanel(@"Error while opening file!", 
			  @"Couldn't open %@", @"OK", nil, nil,imageFilePath);
	}
    }  */
}

- (void)clearFile:(id)sender
{
/*  [projectDict setObject:@"" forKey:PCAppIcon];
  [infoDict setObject:@"" forKey:@"NSIcon"];
  [infoDict setObject:@"" forKey:@"ApplicationIcon"];
  [appImageField setStringValue:@""];
  [iconView setImage:nil];
  [iconView display];

  [[NSNotificationCenter defaultCenter] 
    postNotificationName:PCProjectDictDidChangeNotification
                  object:self];*/
}

- (void)setAppIcon:(id)sender
{
  int         result;  
  NSArray     *fileTypes = [NSImage imageFileTypes];
  NSOpenPanel *openPanel = [NSOpenPanel openPanel];
  NSString    *dir = nil;

  [openPanel setAllowsMultipleSelection:NO];
  
  dir = [[NSUserDefaults standardUserDefaults]
    objectForKey:@"LastOpenDirectory"];
  result = [openPanel runModalForDirectory:dir
                                      file:nil 
                                     types:fileTypes];

  if (result == NSOKButton)
    {
      NSString *imageFilePath = [[openPanel filenames] objectAtIndex:0];

      if (![self setAppIconWithImageAtPath:imageFilePath])
	{
	  NSRunAlertPanel(@"Error while opening file!", 
			  @"Couldn't open %@", @"OK", nil, nil,imageFilePath);
	}
    }  
}

- (void)clearAppIcon:(id)sender
{
  [projectDict setObject:@"" forKey:PCAppIcon];
  [infoDict setObject:@"" forKey:@"NSIcon"];
  [infoDict setObject:@"" forKey:@"ApplicationIcon"];
  [appImageField setStringValue:@""];
  [iconView setImage:nil];
  [iconView display];

  [[NSNotificationCenter defaultCenter] 
    postNotificationName:PCProjectDictDidChangeNotification
                  object:self];
}

- (BOOL)setAppIconWithImageAtPath:(NSString *)path
{
  NSRect   frame = {{0,0}, {64, 64}};
  NSImage  *image = nil;
  NSString *imageName = nil;

  if (!(image = [[NSImage alloc] initWithContentsOfFile:path]))
    {
      return NO;
    }

  imageName = [path lastPathComponent];

  [self addAndCopyFiles:[NSArray arrayWithObject:path] forKey:PCImages];
  
  [projectDict setObject:imageName forKey:PCAppIcon];

  [infoDict setObject:imageName forKey:@"NSIcon"];
  [infoDict setObject:imageName forKey:@"ApplicationIcon"];

  [appImageField setStringValue:imageName];

  [iconView setImage:nil];
  [iconView display];

  frame.size = [image size];
  [iconView setFrame:frame];
  [iconView setImage:image];
  [iconView display];
  RELEASE(image);

  [[NSNotificationCenter defaultCenter] 
    postNotificationName:PCProjectDictDidChangeNotification
                  object:self];

  return YES;
}

- (void)setMainNib:(id)sender
{
  int         result;
  NSOpenPanel *openPanel = [NSOpenPanel openPanel];
  NSString    *dir = nil;

  [openPanel setAllowsMultipleSelection:NO];
  
  dir = [[NSUserDefaults standardUserDefaults]
    objectForKey:@"LastOpenDirectory"];
  result = [openPanel runModalForDirectory:dir
                                      file:nil 
                                     types:[NSArray arrayWithObject:@"gorm"]];

  if (result == NSOKButton)
    {
      NSString *file = [[openPanel filenames] objectAtIndex:0];

      if (![self setMainNibWithFileAtPath:file])
	{
	  NSRunAlertPanel(@"Error while opening file!", 
			  @"Couldn't open %@", @"OK", nil, nil,file);
	}
    }  
}

- (BOOL)setMainNibWithFileAtPath:(NSString *)path
{
  NSString *nibName = [path lastPathComponent];

  [self addAndCopyFiles:[NSArray arrayWithObject:path] forKey:PCInterfaces];
  [projectDict setObject:nibName forKey:PCMainInterfaceFile];
  [infoDict setObject:nibName forKey:@"NSMainNibFile"];

//  [mainNibField setStringValue:nibName];

  [[NSNotificationCenter defaultCenter] 
    postNotificationName:PCProjectDictDidChangeNotification
                  object:self];

  return YES;
}

- (void)clearMainNib:(id)sender
{
  [projectDict setObject:@"" forKey:PCMainInterfaceFile];
  [infoDict setObject:@"" forKey:@"NSMainNibFile"];
//  [mainNibField setStringValue:@""];

  [[NSNotificationCenter defaultCenter] 
    postNotificationName:PCProjectDictDidChangeNotification
                  object:self];
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
  int      pIndex;

  pIndex = [searchOrderPopup indexOfSelectedItem];
  switch (pIndex)
    {
    case 0:
      [projectDict setObject:searchItems forKey:PCSearchHeaders];
      break;
    case 1:
      [projectDict setObject:searchItems forKey:PCSearchLibs];
      break;
    case 2:
      return;
    }

  [[NSNotificationCenter defaultCenter] 
    postNotificationName:PCProjectDictDidChangeNotification
                  object:self];
}

//
- (int)numberOfRowsInTableView: (NSTableView *)aTableView
{
  return [searchItems count];
}
    
- (id)            tableView: (NSTableView *)aTableView
  objectValueForTableColumn: (NSTableColumn *)aTableColumn
                        row: (int)rowIndex
{
  return [searchItems objectAtIndex:rowIndex];
}
  
- (void) tableView:(NSTableView *)aTableView
    setObjectValue:anObject
    forTableColumn:(NSTableColumn *)aTableColumn
               row:(int)rowIndex
{
/*  NSString *path = nil;
  NSParameterAssert (rowIndex >= 0 && rowIndex < [editedFiles count]);
      
  [editedFiles removeObjectAtIndex:rowIndex];
  [editedFiles insertObject:anObject atIndex:rowIndex];
      
  path =
  [filesPath removeObjectAtIndex:rowIndex];
  [filesPath insertObject:[editor path] atIndex:rowIndex];*/
}

// ----------------------------------------------------------------------------
// --- Notifications
// ----------------------------------------------------------------------------

- (void)updateInspectorValues:(NSNotification *)aNotif
{
  NSRect   frame = {{0,0}, {48,48}};
  NSImage  *image = nil;
  NSString *path = nil;
  NSString *_icon = nil;

  NSLog (@"PCAppProject: updateInspectorValues");

  // Build Attributes view
/*  searchHeaders = [projectDict objectForKey:PCSearchHeaders];
  searchLibs = [projectDict objectForKey:PCSearchLibs];
  [self searchOrderPopupDidChange:searchOrderPopup];*/

  [projectNameLabel setStringValue:projectName];

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

  // Project Attributes view
  [projectTypeField setStringValue:[projectDict objectForKey:PCProjectType]];
  [projectNameField setStringValue:[projectDict objectForKey:PCProjectName]];
  [projectLanguageField setStringValue:[projectDict objectForKey:@"LANGUAGE"]];
  [appClassField setStringValue:[projectDict objectForKey:PCPrincipalClass]];
  [appImageField setStringValue:[projectDict objectForKey:PCAppIcon]];

  _icon = [projectDict objectForKey:PCAppIcon];
  if (_icon && ![_icon isEqualToString:@""])
    {
      path = [self dirForCategory:PCImages];
      path = [path stringByAppendingPathComponent:_icon];
    }

  if (path && (image = [[NSImage alloc] initWithContentsOfFile:path]))
    {
      frame.size = [image size];
      [iconView setFrame:frame];
      [iconView setImage:image];
      [iconView display];
      RELEASE(image);
    }

  // File Attributes view
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

@end
