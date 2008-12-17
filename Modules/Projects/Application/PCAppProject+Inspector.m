/*
   GNUstep ProjectCenter - http://www.gnustep.org/experience/ProjectCenter.html

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

#include <ProjectCenter/PCMakefileFactory.h>

#include "PCAppProject+Inspector.h"

// ----------------------------------------------------------------------------
// --- Customized text field
// ----------------------------------------------------------------------------
NSString *PCITextFieldGetFocus = @"PCITextFieldGetFocusNotification";

static void
setOrRemove(NSMutableDictionary *m, id v, NSString *k)
{
  if ([v isKindOfClass: [NSString class]])
    {
      v = [v stringByTrimmingSpaces];
      if ([v length] == 0)
	v = nil;
    }
  else if ([v isKindOfClass: [NSArray class]])
    {
      if ([v count] == 0)
	v = nil;
    }
  if (v == nil)
    [m removeObjectForKey: k];
  else
    [m setObject: v forKey: k];
}

static id
cleanup(NSMutableDictionary *m, NSString *k)
{
  id	v;

  setOrRemove(m, [m objectForKey: k], k);
  v = [m objectForKey: k];
  if (v == nil)
    v = @"";
  return v;
}


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

- (void)awakeFromNib
{
  [docBasedAppButton setRefusesFirstResponder:YES];

  [docBasedAppButton setState:
    ([[projectDict objectForKey: PCDocumentBasedApp]
     isEqualToString: @"YES"]) ? NSOnState : NSOffState];
}

// ----------------------------------------------------------------------------
// --- User Interface
// ----------------------------------------------------------------------------

- (void)createProjectAttributes
{
  // TFs Buttons
  [setFieldButton setRefusesFirstResponder: YES];
  [clearFieldButton setRefusesFirstResponder: YES];

  // Document types buttons
  [addDocTypeButton setRefusesFirstResponder: YES];
  [removeDocTypeButton setRefusesFirstResponder: YES];
  [docBasedAppButton setRefusesFirstResponder: YES];

  [self setDocBasedApp: docBasedAppButton];
  
  [[NSNotificationCenter defaultCenter] addObserver: self
                                           selector: @selector(tfGetFocus:)
                                               name: PCITextFieldGetFocus
                                             object: nil];
  [projectAttributesView retain];

  [self updateInspectorValues: nil];
}

- (NSView *)projectAttributesView
{
  if (!projectAttributesView)
    {
      if ([NSBundle loadNibNamed: @"Inspector" owner: self] == NO)
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

- (void)setAppType: (id)sender
{
  NSString       *appType = [appTypeField stringValue];
  NSMutableArray *libs = [[projectDict objectForKey: PCLibraries] mutableCopy];

  if ([appType isEqualToString: @"Renaissance"])
    {
      [libs addObject: @"Renaissance"];
    }
  else
    {
      [libs removeObject: @"Renaissance"];
    }

  [self setProjectDictObject: libs forKey: PCLibraries notify: YES];
  RELEASE(libs);
  [self setProjectDictObject: appType forKey: PCAppType notify: YES];
}

- (void)setAppClass: (id)sender
{
  [self setProjectDictObject: [appClassField stringValue]
                      forKey: PCPrincipalClass
		      notify: YES];
}

- (void)setIconViewImage: (NSImage *)image
{
  [iconView setImage: nil];
  [iconView display];

  if (image == nil)
    {
      return;
    }

  [iconView setImage: image];
  [iconView display];
}

- (void)setFile: (id)sender
{
  if (!activeTextField)
    {
      return;
    }

  if (activeTextField == appImageField)
    {
      [self setAppIcon: self];
    }
  else if (activeTextField == helpFileField)
    {
      [self setHelpFile: self];
    }
  else if (activeTextField == mainNIBField)
    {
      [self setMainNib: self];
    }
}

- (void)clearFile: (id)sender
{
  if (!activeTextField)
    {
      return;
    }

  if (activeTextField == appImageField)
    {
      [self clearAppIcon: self];
    }
  else if (activeTextField == helpFileField)
    {
      [self clearHelpFile: self];
    }
  else if (activeTextField == mainNIBField)
    {
      [self clearMainNib: self];
    }
  [self setIconViewImage: nil];
}

// Application Icon
- (void)setAppIcon: (id)sender
{
  int         result;  
  NSArray     *fileTypes = [NSImage imageFileTypes];
  NSOpenPanel *openPanel = [NSOpenPanel openPanel];
  NSString    *dir = nil;

  [openPanel setAllowsMultipleSelection: NO];
  [openPanel setTitle: @"Set Application Icon"];
  
  dir = [[NSUserDefaults standardUserDefaults]
    objectForKey: @"LastOpenDirectory"];
  result = [openPanel runModalForDirectory: dir
                                      file: nil 
                                     types: fileTypes];

  if (result == NSOKButton)
    {
      NSString *imageFilePath = [[openPanel filenames] objectAtIndex: 0];

      if (![self setAppIconWithImageAtPath: imageFilePath])
	{
	  NSRunAlertPanel(@"Error while opening file!", 
			  @"Couldn't open %@", @"OK", nil, nil,imageFilePath);
	}
    }  
}

- (void)setHelpFile: (id)sender
{
  int         result;  
  NSArray     *fileTypes = [NSArray arrayWithObject: @"rtfd"];
  NSOpenPanel *openPanel = [NSOpenPanel openPanel];
  NSString    *dir = nil;

  [openPanel setAllowsMultipleSelection: NO];
  [openPanel setTitle: @"Set Help File"];
  
  dir = [[NSUserDefaults standardUserDefaults]
    objectForKey: @"LastOpenDirectory"];
  result = [openPanel runModalForDirectory: dir
                                      file: nil 
                                     types: fileTypes];

  if (result == NSOKButton)
    {
      NSString *path = [[openPanel filenames] objectAtIndex: 0];
      NSString *file = [path lastPathComponent];

      [helpFileField setStringValue: file];

      [self addAndCopyFiles: [NSArray arrayWithObject: path]
		     forKey: PCDocuFiles];
  
      [infoDict setObject: file forKey: @"GSHelpContentsFile"];
      [self setProjectDictObject: file forKey: PCHelpFile notify: YES];
    }  
}

- (void)clearAppIcon: (id)sender
{
  [appImageField setStringValue: @""];
  [infoDict setObject: @"" forKey: @"NSIcon"];
  [infoDict setObject: @"" forKey: @"ApplicationIcon"];
  
  [self setProjectDictObject: @"" forKey: PCAppIcon notify: YES];
}

- (void)clearHelpFile: (id)sender
{
  [infoDict removeObjectForKey: @"GSHelpContentsFile"];
  [self setProjectDictObject: @"" forKey: PCHelpFile notify: YES];
}

- (BOOL)setAppIconWithImageAtPath: (NSString *)path
{
  NSImage  *image = nil;
  NSString *imageName = nil;

  if (!(image = [[NSImage alloc] initWithContentsOfFile: path]))
    {
      return NO;
    }

  imageName = [path lastPathComponent];

  [appImageField setStringValue: imageName];

  [self setIconViewImage: image];

  [self addAndCopyFiles: [NSArray arrayWithObject: path] forKey: PCImages];
  
  [infoDict setObject: imageName forKey: @"NSIcon"];
  [infoDict setObject: imageName forKey: @"ApplicationIcon"];

  [self setProjectDictObject: imageName forKey: PCAppIcon notify: YES];

  return YES;
}

// Main Interface File
- (void)setMainNib: (id)sender
{
  int         result;
  NSOpenPanel *openPanel = [NSOpenPanel openPanel];
  NSString    *dir = nil;
  NSArray     *types = nil;

  [openPanel setAllowsMultipleSelection: NO];
  [openPanel setTitle: @"Set Main Interface File"];
  if ([[projectDict objectForKey: PCAppType] isEqualToString: @"GORM"])
    {
      types = [NSArray arrayWithObject: @"gorm"];
    }
  else
    {
      types = [NSArray arrayWithObject: @"gsmarkup"];
    }
  
  dir = [[NSUserDefaults standardUserDefaults]
    objectForKey: @"LastOpenDirectory"];
  result = [openPanel runModalForDirectory: dir file: nil types: types];

  if (result == NSOKButton)
    {
      NSString *file = [[openPanel filenames] objectAtIndex: 0];

      if (![self setMainNibWithFileAtPath: file])
	{
	  NSRunAlertPanel(@"Error while opening file!", 
			  @"Couldn't open %@", @"OK", nil, nil,file);
	}
    }  
}

- (BOOL)setMainNibWithFileAtPath: (NSString *)path
{
  NSString *nibName = [path lastPathComponent];

  [self setIconViewImage: [[NSWorkspace sharedWorkspace] iconForFile: path]];

  [self addAndCopyFiles: [NSArray arrayWithObject: path] forKey: PCInterfaces];
  [infoDict setObject: nibName forKey: @"NSMainNibFile"];

  [self setProjectDictObject: nibName forKey: PCMainInterfaceFile notify: YES];

  [mainNIBField setStringValue: nibName];

  return YES;
}

- (void)clearMainNib: (id)sender
{
  [mainNIBField setStringValue: @""];
  [infoDict setObject: @"" forKey: @"NSMainNibFile"];

  [self setProjectDictObject: @"" forKey: PCMainInterfaceFile notify: YES];
}

// Document Types
- (void)showDocTypesPanel: (id)sender
{
  [docTypesPanel makeKeyAndOrderFront: nil];
}

- (void)setDocBasedApp: (id)sender
{
  NSString *docBased = [projectDict objectForKey: PCDocumentBasedApp];

  if ([docBasedAppButton state] == NSOnState)
    {
      [docTypeLabel setTextColor: [NSColor blackColor]];
      [docTypeField setBackgroundColor: [NSColor whiteColor]];
      [docTypeField setTextColor: [NSColor blackColor]];
      [docTypeField setEditable: YES];

      [docNameLabel setTextColor: [NSColor blackColor]];
      [docNameField setBackgroundColor: [NSColor whiteColor]];
      [docNameField setTextColor: [NSColor blackColor]];
      [docNameField setEditable: YES];

      [docRoleLabel setTextColor: [NSColor blackColor]];
      [docRoleField setBackgroundColor: [NSColor whiteColor]];
      [docRoleField setTextColor: [NSColor blackColor]];
      [docRoleField setEditable: YES];

      [docClassLabel setTextColor: [NSColor blackColor]];
      [docClassField setBackgroundColor: [NSColor whiteColor]];
      [docClassField setTextColor: [NSColor blackColor]];
      [docClassField setEditable: YES];

      [nameColumn setIdentifier: @"NSHumanReadableName"];
      [[nameColumn headerCell] setStringValue: @"Name"];
      [docTypesList addTableColumn: roleColumn];
      [docTypesList addTableColumn: classColumn];
      RELEASE(roleColumn);
      RELEASE(classColumn);
      
      if (![docBased isEqualToString: @"YES"])
	{
	  [self setProjectDictObject: @"YES" 
	                      forKey: PCDocumentBasedApp
			      notify: YES];
	}
    }
  else
    {
      [docTypeLabel setTextColor: [NSColor darkGrayColor]];
      [docTypeField setBackgroundColor: [NSColor lightGrayColor]];
      [docTypeField setTextColor: [NSColor darkGrayColor]];
      [docTypeField setEditable: NO];

      [docNameLabel setTextColor: [NSColor darkGrayColor]];
      [docNameField setBackgroundColor: [NSColor lightGrayColor]];
      [docNameField setTextColor: [NSColor darkGrayColor]];
      [docNameField setEditable: NO];

      [docRoleLabel setTextColor: [NSColor darkGrayColor]];
      [docRoleField setBackgroundColor: [NSColor lightGrayColor]];
      [docRoleField setTextColor: [NSColor darkGrayColor]];
      [docRoleField setEditable: NO];

      [docClassLabel setTextColor: [NSColor darkGrayColor]];
      [docClassField setBackgroundColor: [NSColor lightGrayColor]];
      [docClassField setTextColor: [NSColor darkGrayColor]];
      [docClassField setEditable: NO];

      // Columns
//      [docTypesList removeTableColumn:nameColumn];
      [nameColumn setIdentifier: @"NSIcon"];
      [[nameColumn headerCell] setStringValue: @"Icon"];
      RETAIN(roleColumn);
      RETAIN(classColumn);
      [docTypesList removeTableColumn: roleColumn];
      [docTypesList removeTableColumn: classColumn];
      
      if (![docBased isEqualToString: @"NO"])
	{
	  [self setProjectDictObject: @"NO" 
	                      forKey: PCDocumentBasedApp
			      notify: YES];
	}
    }
}

- (void)addDocType: (id)sender
{
  int                 row;
  NSMutableDictionary *entry = [NSMutableDictionary dictionaryWithCapacity: 6];
  int                 selectedRow = [docTypesList selectedRow];

  setOrRemove(entry, [docTypeField stringValue], @"NSName");
  setOrRemove(entry, [docNameField stringValue], @"NSHumanReadableName");
  setOrRemove(entry, [[docExtensionsField stringValue] componentsSeparatedByString: @","], @"NSUnixExtensions");
  setOrRemove(entry, [docIconField stringValue], @"NSIcon");
  setOrRemove(entry, [docRoleField stringValue], @"NSRole");
  setOrRemove(entry, [docClassField stringValue], @"NSDocumentClass");

  if (selectedRow >= 0 && [docTypesItems count] > 0)
    {
      [docTypesItems insertObject: entry atIndex: selectedRow + 1];
      row = selectedRow + 1;
    }
  else
    {
      [docTypesItems addObject: entry];
      row = [docTypesItems count] - 1;
    }
  [docTypesList reloadData];
  
  [docTypesList selectRow: row byExtendingSelection: NO];

  [self fillFieldsForRow: row];

  [self setProjectDictObject: docTypesItems 
                      forKey: PCDocumentTypes
		      notify: YES];
}

- (void)removeDocType: (id)sender
{
  int selectedRow = [docTypesList selectedRow];

  if (selectedRow >= 0)
    {
      [docTypesItems removeObjectAtIndex: selectedRow];
      [docTypesList reloadData];
    }

  if (([docTypesList selectedRow] < 0) && ([docTypesItems count] > 0))
    {
      [docTypesList selectRow: [docTypesItems count]-1
	 byExtendingSelection: NO];
      [self fillFieldsForRow: [docTypesItems count]-1];
    }

  [self setProjectDictObject: docTypesItems
                      forKey: PCDocumentTypes
                      notify: YES];
}

- (void)docFieldSet: (id)sender
{
  NSMutableDictionary *object = nil;
 
  NSLog(@"docFieldSet");

  if (sender != docTypeField && sender != docNameField 
    && sender != docIconField && sender != docExtensionsField
    && sender != docRoleField && sender != docClassField)
    {
      return;
    }
    
  if ([docTypesItems count] <= 0)
    {
      [self addDocType: addDocTypeButton];
    }

  object = [[docTypesItems objectAtIndex: [docTypesList selectedRow]] 
    mutableCopy];

  if (sender == docTypeField)
    {
      setOrRemove(object, [sender stringValue], @"NSName");
    }
  else if (sender == docNameField)
    {
      setOrRemove(object, [sender stringValue], @"NSHumanReadableName");
    }
  else if (sender == docIconField)
    {
      setOrRemove(object, [sender stringValue], @"NSIcon");
    }
  else if (sender == docExtensionsField)
    {
      setOrRemove(object,
	[[sender stringValue] componentsSeparatedByString: @","],
	@"NSUnixExtensions");
    }
  else if (sender == docRoleField)
    {
      setOrRemove(object, [sender stringValue], @"NSRole");
    }
  else if (sender == docClassField)
    {
      setOrRemove(object, [sender stringValue], @"NSDocumentClass");
    }

  [docTypesItems replaceObjectAtIndex: [docTypesList selectedRow] 
                          withObject: object];
  [docTypesList reloadData];
  [object release];
}

// ----------------------------------------------------------------------------
// --- Document Types browser
// ----------------------------------------------------------------------------

- (int)numberOfRowsInTableView: (NSTableView *)aTableView
{
  return [docTypesItems count];
}
    
- (id)            tableView: (NSTableView *)aTableView
  objectValueForTableColumn: (NSTableColumn *)aTableColumn
                        row: (int)rowIndex
{
  NSDictionary *object = nil;

  if (docTypesItems != nil || [docTypesItems count] > 0)
    {
      object = [docTypesItems objectAtIndex: rowIndex];

      if (aTableColumn == extensionsColumn)
	{
	  return [[object objectForKey: @"NSUnixExtensions"] 
	    componentsJoinedByString: @","];
	}
      else
	{
	  return [object objectForKey: [aTableColumn identifier]];
	}
    }

  return nil;
}
  
- (void)tableView: (NSTableView *)aTableView
   setObjectValue: anObject
   forTableColumn: (NSTableColumn *)aTableColumn
              row: (int)rowIndex
{
  NSMutableDictionary *type = nil;
  
  if (docTypesItems == nil || [docTypesItems count] <= 0)
    {
      return;
    }

  type = [docTypesItems objectAtIndex: rowIndex];
  if ([[aTableColumn identifier] isEqualToString: @"NSUnixExtensions"])
    {
      setOrRemove(type, anObject, @"Extension");
    }
  else if ([[aTableColumn identifier] isEqualToString: @"NSIcon"])
    {
      setOrRemove(type, anObject, @"Icon");
    }
  
  [self setProjectDictObject: docTypesItems
                      forKey: PCDocumentTypes
		      notify: YES];
}

- (BOOL)tableView: (NSTableView *)aTableView shouldSelectRow: (int)rowIndex
{
  [self fillFieldsForRow: rowIndex];
  return YES;
}

- (void)fillFieldsForRow: (int)rowIndex
{
  NSMutableDictionary *type = nil;
  int          itemCount = [docTypesItems count];

  if (itemCount <= 0 || rowIndex > itemCount || rowIndex < 0)
    {
      [docTypeField setStringValue: @""];
      [docNameField setStringValue: @""];
      [docIconField setStringValue: @""];
      [docExtensionsField setStringValue: @""];
      [docRoleField setStringValue: @""];
      [docClassField setStringValue: @""];

      return;
    }

  type = [docTypesItems objectAtIndex: rowIndex];
  
  [docTypeField setStringValue: cleanup(type, @"NSName")];
  [docNameField setStringValue: cleanup(type, @"NSHumanReadableName")];
  [docIconField setStringValue: cleanup(type, @"NSIcon")];

  [docExtensionsField setStringValue: @""];
  if ([[type objectForKey: @"NSUnixExtensions"] count] > 0)
    {
      [docExtensionsField setStringValue:
	[[type objectForKey: @"NSUnixExtensions"] 
	 componentsJoinedByString: @","]];
    }

  [docRoleField setStringValue: cleanup(type, @"NSRole")];
  [docClassField setStringValue: cleanup(type, @"NSDocumentClass")];
}

// ----------------------------------------------------------------------------
// --- Notifications
// ----------------------------------------------------------------------------

- (void)updateInspectorValues: (NSNotification *)aNotif
{
//  NSLog (@"PCAppProject: updateInspectorValues");

  // Project Attributes view
  [appTypeField selectItemWithTitle: [projectDict objectForKey: PCAppType]];
  [appClassField setStringValue: [projectDict objectForKey: PCPrincipalClass]];

  [appImageField setStringValue: [projectDict objectForKey: PCAppIcon]];
  [helpFileField setStringValue: [projectDict objectForKey: PCHelpFile]];
  [mainNIBField setStringValue:
    [projectDict objectForKey: PCMainInterfaceFile]];

  docTypesItems = [projectDict objectForKey: PCDocumentTypes];
  [docTypesList reloadData];
}

// TextFields (PCITextField subclass)
// 
// NSTextField become first responder when user clicks on it and immediately
// lost first resonder status, so we can't catch when focus leaves textfield
// with resignFirstResponder: method overriding. Here we're using
// controlTextDidEndEditing (NSTextField's delegate method) to achieve this.

- (void)tfGetFocus: (NSNotification *)aNotif
{
  id       anObject = [aNotif object];
  NSString *file = nil;
  NSString *path = nil;

  
  if (anObject != appImageField 
    && anObject != helpFileField 
    && anObject != mainNIBField)
    {
//      NSLog(@"tfGetFocus: not that textfield");
      return;
    }

  if (anObject == appImageField)
    {
      file = [appImageField stringValue];

      if (![file isEqualToString: @""])
	{
	  path = [self dirForCategoryKey: PCImages];
	  path = [path stringByAppendingPathComponent: file];
	  [self setIconViewImage: [[NSImage alloc]
          initWithContentsOfFile: path]];
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
      
      if (![file isEqualToString: @""])
	{
	  path = [projectPath stringByAppendingPathComponent: file];
	  [self setIconViewImage: [[NSWorkspace sharedWorkspace]
	             iconForFile: path]];
	}
      activeTextField = mainNIBField;
    }

  [setFieldButton setEnabled: YES];
  [clearFieldButton setEnabled: YES];
}

- (void)controlTextDidEndEditing: (NSNotification *)aNotification
{
  NSControl *anObject = [aNotification object];
  id        target = [anObject target];
  SEL       action = [anObject action];

  if (anObject == appImageField
    || anObject == helpFileField
    || anObject == mainNIBField)
    {
      activeTextField = nil;
      [self setIconViewImage: nil];

      [setFieldButton setEnabled: NO];
      [clearFieldButton setEnabled: NO];

      return;
    }

  if ([target respondsToSelector: action])
    {
      [target performSelector: action withObject: anObject];
    }
}

@end
