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
#include "PCAppProject+Inspector.h"

@implementation PCAppProject (Inspector)

// ----------------------------------------------------------------------------
// --- User Interface
// ----------------------------------------------------------------------------

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
  [appImageField setTarget:self];
  [appImageField setAction:@selector(setAppIcon:)];
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

  // Document Icons
  textField = [[NSTextField alloc] initWithFrame:NSMakeRect(2,107,108,21)];
  [textField setAlignment: NSLeftTextAlignment];
  [textField setBordered: NO];
  [textField setEditable: NO];
  [textField setSelectable: NO];
  [textField setBezeled: NO];
  [textField setDrawsBackground: NO];
  [textField setStringValue:@"Document Icons:"];
  [_iconsBox addSubview:textField];
  RELEASE(textField);

  //
  docExtColumn = [[NSTableColumn alloc] initWithIdentifier: @"extension"];
  [[docExtColumn headerCell] setStringValue:@"Extenstion"];
  [docExtColumn setWidth:94];
  docIconColumn = [[NSTableColumn alloc] initWithIdentifier: @"icon"];
  [[docIconColumn headerCell] setStringValue:@"Icon name"];

  docIconsList = [[NSTableView alloc]
    initWithFrame:NSMakeRect(2,0,211,108)];
  [docIconsList setAllowsMultipleSelection:NO];
  [docIconsList setAllowsColumnReordering:NO];
  [docIconsList setAllowsColumnResizing:NO];
  [docIconsList setAllowsEmptySelection:YES];
  [docIconsList setAllowsColumnSelection:NO];
  [docIconsList addTableColumn:docExtColumn];
  [docIconsList addTableColumn:docIconColumn];
  [docIconsList setDataSource:self];
  [docIconsList setTarget:self];

  //
  docIconsScroll = [[NSScrollView alloc] initWithFrame:
    NSMakeRect (2,0,211,106)];
  [docIconsScroll setDocumentView:docIconsList];
  [docIconsScroll setHasHorizontalScroller:NO];
  [docIconsScroll setHasVerticalScroller:YES];
  [docIconsScroll setBorderType:NSBezelBorder];
  RELEASE(docIconsList);
  [_iconsBox addSubview:docIconsScroll];
  RELEASE(docIconsScroll);
  [docIconsList reloadData];
  
  // Document icons buttons
  addDocIcon = [[NSButton alloc] initWithFrame:NSMakeRect(220,28,56,24)];
  [addDocIcon setTitle:@"Add"];
  [addDocIcon setRefusesFirstResponder:YES];
  [addDocIcon setTarget:self];
  [addDocIcon setAction:@selector(addDocIcon:)];
  [_iconsBox addSubview:addDocIcon];
  RELEASE(addDocIcon);

  removeDocIcon = [[NSButton alloc] initWithFrame:NSMakeRect(220,0,56,24)];
  [removeDocIcon setTitle:@"Remove"];
  [removeDocIcon setRefusesFirstResponder:YES];
  [removeDocIcon setTarget:self];
  [removeDocIcon setAction:@selector(removeDocIcon:)];
  [_iconsBox addSubview:removeDocIcon];
  RELEASE(removeDocIcon);

  RELEASE(_iconsBox);

  [self updateInspectorValues:nil];
}

- (NSView *)projectAttributesView
{
  if (!projectAttributesView)
    {
      [self createProjectAttributes];
    }
  return projectAttributesView;
}

// ----------------------------------------------------------------------------
// --- Actions
// ----------------------------------------------------------------------------

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
  [infoDict setObject:@"" forKey:@"NSIcon"];
  [infoDict setObject:@"" forKey:@"ApplicationIcon"];
  [appImageField setStringValue:@""];
  [iconView setImage:nil];
  [iconView display];
  
  [self setProjectDictObject:@"" forKey:PCAppIcon];
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

  [appImageField setStringValue:imageName];

  [iconView setImage:nil];
  [iconView display];

  frame.size = [image size];
  [iconView setFrame:frame];
  [iconView setImage:image];
  [iconView display];
  RELEASE(image);

  [self addAndCopyFiles:[NSArray arrayWithObject:path] forKey:PCImages];
  
  [infoDict setObject:imageName forKey:@"NSIcon"];
  [infoDict setObject:imageName forKey:@"ApplicationIcon"];

  [self setProjectDictObject:imageName forKey:PCAppIcon];

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
  [infoDict setObject:nibName forKey:@"NSMainNibFile"];
  [self setProjectDictObject:nibName forKey:PCMainInterfaceFile];

//  [mainNibField setStringValue:nibName];

  return YES;
}

- (void)clearMainNib:(id)sender
{
  [infoDict setObject:@"" forKey:@"NSMainNibFile"];
  [self setProjectDictObject:@"" forKey:PCMainInterfaceFile];

//  [mainNibField setStringValue:@""];
}

- (void)addDocIcon:(id)sender
{
  int row;
  NSMutableDictionary *entry = [NSMutableDictionary dictionaryWithCapacity:2];

  [entry setObject:@"" forKey:@"Extension"];
  [entry setObject:@"" forKey:@"Icon"];
  [docIconsItems addObject:entry];
  [docIconsList reloadData];
  
  row = [docIconsItems count] - 1;
  [docIconsList selectRow:row byExtendingSelection:NO];
  [docIconsList editColumn:0 row:row withEvent:nil select:YES];

  [self setProjectDictObject:docIconsItems forKey:PCDocumentExtensions];
}

- (void)removeDocIcon:(id)sender
{
  int selectedRow = [docIconsList selectedRow];
  
  if (selectedRow >= 0)
  {
    [docIconsItems removeObjectAtIndex:selectedRow];
    [docIconsList reloadData];
  }
  
  if (([docIconsList selectedRow] < 0) && ([docIconsItems count] > 0))
  {
    [docIconsList selectRow:[docIconsItems count]-1 byExtendingSelection:NO];
  }

  [self setProjectDictObject:docIconsItems forKey:PCDocumentExtensions];
}

// ----------------------------------------------------------------------------
// --- Document Icons browser
// ----------------------------------------------------------------------------

- (int)numberOfRowsInTableView: (NSTableView *)aTableView
{
  return [docIconsItems count];
}
    
- (id)            tableView: (NSTableView *)aTableView
  objectValueForTableColumn: (NSTableColumn *)aTableColumn
                        row: (int)rowIndex
{
  if ([[aTableColumn identifier] isEqualToString:@"extension"])
    {
      return [[docIconsItems objectAtIndex:rowIndex] objectForKey:@"Extension"];
    }
  else if ([[aTableColumn identifier] isEqualToString:@"icon"])
    {
      return [[docIconsItems objectAtIndex:rowIndex] objectForKey:@"Icon"];
    }

  return nil;
}
  
- (void) tableView:(NSTableView *)aTableView
    setObjectValue:anObject
    forTableColumn:(NSTableColumn *)aTableColumn
               row:(int)rowIndex
{
  if (docIconsItems == nil || [docIconsItems count] <= 0)
    {
      return;
    }

  if ([[aTableColumn identifier] isEqualToString:@"extension"])
    {
      [[docIconsItems objectAtIndex:rowIndex] removeObjectForKey:@"Extension"];
      [[docIconsItems objectAtIndex:rowIndex] setObject:anObject
	                                         forKey:@"Extension"];
    }
  else if ([[aTableColumn identifier] isEqualToString:@"icon"])
    {
      [[docIconsItems objectAtIndex:rowIndex] removeObjectForKey:@"Icon"];
      [[docIconsItems objectAtIndex:rowIndex] setObject:anObject
	                                         forKey:@"Icon"];
    }
  
  [self setProjectDictObject:docIconsItems forKey:PCDocumentExtensions];
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

  docIconsItems = [projectDict objectForKey:PCDocumentExtensions];
  [docIconsList reloadData];
}

@end
