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

// ----------------------------------------------------------------------------
// --- Customized text field
// ----------------------------------------------------------------------------
NSString *PCITextFieldGetFocus = @"PCITextFieldGetFocusNotification";

@implementation PCAppTextField

- (BOOL)becomeFirstResponder
{
  [[NSNotificationCenter defaultCenter]
    postNotificationName:PCITextFieldGetFocus
                  object:self];
		  
  return [super becomeFirstResponder];
}

@end

@implementation PCAppProject (Inspector)

// ----------------------------------------------------------------------------
// --- User Interface
// ----------------------------------------------------------------------------

- (void)createProjectAttributes
{
  // TFs Buttons
  [setFieldButton setRefusesFirstResponder:YES];
  [clearFieldButton setRefusesFirstResponder:YES];

  // Document Icons
  //
  docExtColumn = [[NSTableColumn alloc] initWithIdentifier: @"extension"];
  [[docExtColumn headerCell] setStringValue:@"Extenstion"];
  [docExtColumn setWidth:75];
  docIconColumn = [[NSTableColumn alloc] initWithIdentifier: @"icon"];
  [[docIconColumn headerCell] setStringValue:@"Icon name"];

  docIconsList = [[NSTableView alloc] initWithFrame:NSMakeRect(2,0,211,108)];
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
  [docIconsScroll setDocumentView:docIconsList];
  [docIconsScroll setHasHorizontalScroller:NO];
  [docIconsScroll setHasVerticalScroller:YES];
  [docIconsScroll setBorderType:NSBezelBorder];
  RELEASE(docIconsList);
  
  // Document icons buttons
  [addDocIcon setRefusesFirstResponder:YES];
  [removeDocIcon setRefusesFirstResponder:YES];

  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(tfGetFocus:)
                                               name:PCITextFieldGetFocus
                                             object:nil];
  [projectAttributesView retain];

  [self updateInspectorValues:nil];
}

- (NSView *)projectAttributesView
{
  if (!projectAttributesView)
    {
      if ([NSBundle loadNibNamed:@"Inspector" owner:self] == NO)
	{
	  NSLog(@"PCAppProject: error loading Inspector NIB!");
	  return nil;
	}
      [self createProjectAttributes];
    }

  return projectAttributesView;
}

// ----------------------------------------------------------------------------
// --- Actions
// ----------------------------------------------------------------------------

- (void)setAppClass:(id)sender
{
  [self setProjectDictObject:[appClassField stringValue]
                      forKey:PCPrincipalClass];
}

- (void)setIconViewImage:(NSImage *)image
{
  [iconView setImage:nil];
  [iconView display];

  if (image == nil)
    {
      return;
    }

  [iconView setImage:image];
  [iconView display];
}

- (void)setFile:(id)sender
{
  if (!activeTextField)
    {
      return;
    }

  if (activeTextField == appImageField)
    {
      [self setAppIcon:self];
    }
  else if (activeTextField == helpFileField)
    {
    }
  else if (activeTextField == mainNIBField)
    {
      [self setMainNib:self];
    }
}

- (void)clearFile:(id)sender
{
  if (!activeTextField)
    {
      return;
    }

  if (activeTextField == appImageField)
    {
      [self clearAppIcon:self];
    }
  else if (activeTextField == helpFileField)
    {
    }
  else if (activeTextField == mainNIBField)
    {
      [self clearMainNib:self];
    }
  [self setIconViewImage:nil];
}

// Application Icon
- (void)setAppIcon:(id)sender
{
  int         result;  
  NSArray     *fileTypes = [NSImage imageFileTypes];
  NSOpenPanel *openPanel = [NSOpenPanel openPanel];
  NSString    *dir = nil;

  [openPanel setAllowsMultipleSelection:NO];
  [openPanel setTitle:@"Set Application Icon"];
  
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
  [appImageField setStringValue:@""];
  [infoDict setObject:@"" forKey:@"NSIcon"];
  [infoDict setObject:@"" forKey:@"ApplicationIcon"];
  
  [self setProjectDictObject:@"" forKey:PCAppIcon];
}

- (BOOL)setAppIconWithImageAtPath:(NSString *)path
{
  NSImage  *image = nil;
  NSString *imageName = nil;

  if (!(image = [[NSImage alloc] initWithContentsOfFile:path]))
    {
      return NO;
    }

  imageName = [path lastPathComponent];

  [appImageField setStringValue:imageName];

  [self setIconViewImage:image];

  [self addAndCopyFiles:[NSArray arrayWithObject:path] forKey:PCImages];
  
  [infoDict setObject:imageName forKey:@"NSIcon"];
  [infoDict setObject:imageName forKey:@"ApplicationIcon"];

  [self setProjectDictObject:imageName forKey:PCAppIcon];

  return YES;
}

// Main Interface File
- (void)setMainNib:(id)sender
{
  int         result;
  NSOpenPanel *openPanel = [NSOpenPanel openPanel];
  NSString    *dir = nil;

  [openPanel setAllowsMultipleSelection:NO];
  [openPanel setTitle:@"Set Main Interface File"];
  
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

  [self setIconViewImage:[[NSWorkspace sharedWorkspace] iconForFile:path]];

  [self addAndCopyFiles:[NSArray arrayWithObject:path] forKey:PCInterfaces];
  [infoDict setObject:nibName forKey:@"NSMainNibFile"];

  [self setProjectDictObject:nibName forKey:PCMainInterfaceFile];

  [mainNIBField setStringValue:nibName];

  return YES;
}

- (void)clearMainNib:(id)sender
{
  [mainNIBField setStringValue:@""];
  [infoDict setObject:@"" forKey:@"NSMainNibFile"];

  [self setProjectDictObject:@"" forKey:PCMainInterfaceFile];
}

// Document Icons
- (void)addDocIcon:(id)sender
{
  int row;
  NSMutableDictionary *entry = [NSMutableDictionary dictionaryWithCapacity:2];
  int selectedRow = [docIconsList selectedRow];

  [entry setObject:@"" forKey:@"Extension"];
  [entry setObject:@"" forKey:@"Icon"];

  if (selectedRow >= 0)
    {
      [docIconsItems insertObject:entry atIndex:selectedRow + 1];
      row = selectedRow + 1;
    }
  else
    {
      [docIconsItems addObject:entry];
      row = [docIconsItems count] - 1;
    }
  [docIconsList reloadData];
  
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
//  NSLog (@"PCAppProject: updateInspectorValues");

  // Project Attributes view
  [projectTypeField setStringValue:[projectDict objectForKey:PCProjectType]];
  [projectNameField setStringValue:[projectDict objectForKey:PCProjectName]];
  [projectLanguageField setStringValue:[projectDict objectForKey:@"LANGUAGE"]];
  [appClassField setStringValue:[projectDict objectForKey:PCPrincipalClass]];

  [appImageField setStringValue:[projectDict objectForKey:PCAppIcon]];
  [helpFileField setStringValue:[projectDict objectForKey:PCHelpFile]];
  [mainNIBField setStringValue:[projectDict objectForKey:PCMainInterfaceFile]];

  docIconsItems = [projectDict objectForKey:PCDocumentExtensions];
  [docIconsList reloadData];
}

// TextFields (PCITextField subclass)
// 
// NSTextField become first responder when user clicks on it and immediately
// lost first resonder status, so we can't catch when focus leaves textfield
// with resignFirstResponder: method overriding. Here we're using
// controlTextDidEndEditing (NSTextField's delegate method) to achieve this.

- (void)tfGetFocus:(NSNotification *)aNotif
{
  id       anObject = [aNotif object];
  NSString *file = nil;
  NSString *path = nil;

  
  if (anObject != appImageField 
      && anObject != helpFileField 
      && anObject != mainNIBField)
    {
      NSLog(@"tfGetFocus: not that textfield");
      return;
    }

  if (anObject == appImageField)
    {
      file = [appImageField stringValue];

      if (![file isEqualToString:@""])
	{
	  path = [self dirForCategoryKey:PCImages];
	  path = [path stringByAppendingPathComponent:file];
	  [self setIconViewImage:[[NSImage alloc]
          initWithContentsOfFile:path]];
	}
      activeTextField = appImageField;
    }
  else if (anObject == helpFileField)
    {
      activeTextField = helpFileField;
    }
  else if (anObject == mainNIBField)
    {
      file = [mainNIBField stringValue];
      
      if (![file isEqualToString:@""])
	{
	  path = [projectPath stringByAppendingPathComponent:file];
	  [self setIconViewImage:[[NSWorkspace sharedWorkspace]
	             iconForFile:path]];
	}
      activeTextField = mainNIBField;
    }

  [setFieldButton setEnabled:YES];
  [clearFieldButton setEnabled:YES];
}

- (void)controlTextDidEndEditing:(NSNotification *)aNotification
{
  id anObject = [aNotification object];
  
  if (anObject != appImageField 
      && anObject != helpFileField 
      && anObject != mainNIBField)
    {
      NSLog(@"tfLostFocus: not that textfield");
      return;
    }

  activeTextField = nil;
  [self setIconViewImage:nil];

  [setFieldButton setEnabled:NO];
  [clearFieldButton setEnabled:NO];
}

@end
