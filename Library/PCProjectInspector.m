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
#include "PCProjectWindow.h"
#include "PCProjectInspector.h"

#include "PCLogController.h"

@implementation PCFileNameField

- (void)setEditableField:(BOOL)yn
{
  NSRect frame = [self frame];

  if ([self textShouldSetEditable] == NO)
    {
      return;
    }

  if (yn == YES)
    {
      frame.size.width += 4;
      frame.origin.x -= 4;
      [self setFrame:frame];
      
      [self setBordered:YES];
      [self setBackgroundColor:[NSColor whiteColor]];
      [self setEditable:YES];
      [self setNeedsDisplay:YES];
      [[self superview] setNeedsDisplay:YES];
    }
  else
    {
      frame.size.width -= 4;
      frame.origin.x += 4;
      [self setFrame:frame];

      [self setBackgroundColor:[NSColor lightGrayColor]];
      [self setBordered:NO];
      [self setEditable:NO];
      [self setNeedsDisplay:YES];
      [[self superview] setNeedsDisplay:YES];
    }
}

- (void)mouseDown:(NSEvent *)theEvent
{
  [self setEditableField:YES];
  [super mouseDown:theEvent];
}

- (BOOL)textShouldSetEditable
{
  NSString *text = [self stringValue];

  if ([text isEqualToString:@"No files selected"]
      || [text isEqualToString:@"Multiple files selected"])
    {
      return NO;
    }

  return YES;
}

- (void)textDidEndEditing:(NSNotification *)aNotification
{
  [self setEditableField:NO];
  [super textDidEndEditing:aNotification];
}

@end

@implementation PCProjectInspector

// ============================================================================
// ==== Intialization & deallocation
// ============================================================================

- (id)initWithProjectManager:(PCProjectManager *)manager
{
  projectManager = manager;

  [self loadPanel];

  // Track project switching
  [[NSNotificationCenter defaultCenter] 
    addObserver:self
       selector:@selector(activeProjectDidChange:)
           name:PCActiveProjectDidChangeNotification
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

  RELEASE(buildAttributesView);
  RELEASE(projectAttributesView);
  RELEASE(projectDescriptionView);
  RELEASE(fileAttributesView);

  RELEASE(inspectorPanel);
  RELEASE(fileName);

  [super dealloc];
}

// ============================================================================
// ==== Panel & contents
// ============================================================================

- (BOOL)loadPanel
{
  if ([NSBundle loadNibNamed:@"ProjectInspector" owner:self] == NO)
    {
      PCLogError(self, @"error loading NIB file!");
      return NO;
    }

  // Panel
  [inspectorPanel setFrameAutosaveName:@"ProjectInspector"];
  [inspectorPanel setFrameUsingName:@"ProjectInspector"];
  
  // PopUp
  [inspectorPopup removeAllItems];
  [inspectorPopup addItemWithTitle:@"Build Attributes"];
  [inspectorPopup addItemWithTitle:@"Project Attributes"];
  [inspectorPopup addItemWithTitle:@"Project Description"];
  [inspectorPopup addItemWithTitle:@"File Attributes"];
  [inspectorPopup selectItemAtIndex:0];
  
  // Build Attributes
  [self createBuildAttributes];

  // Project Description
  [self createProjectDescription];

  // File Attributes
  [self createFileAttributes];

  [self activeProjectDidChange:nil];

  return YES;
}

- (NSPanel *)panel
{
  if (!inspectorPanel && ([self loadPanel] == NO))
    {
      return nil;
    }

  return inspectorPanel;
}

- (NSView *)contentView
{
  if (!contentView && ([self loadPanel] == NO))
    {
      return nil;
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
  if (sender == installPathField
      && ![[[project projectDict] objectForKey:PCInstallDir] isEqualToString:newEntry])
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

- (void)selectSectionWithTitle:(NSString *)sectionTitle
{
  [inspectorPopup selectItemWithTitle:sectionTitle];
  [self inspectorPopupDidChange:inspectorPopup];
}

// ============================================================================
// ==== Notifications
// ============================================================================

- (void)activeProjectDidChange:(NSNotification *)aNotif
{
  project = [projectManager activeProject];
  projectDict = [project projectDict];

  PCLogStatus(self, @"Active projectChanged to %@", 
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
  [authorsList reloadData];

  // File Attributes view
  [self setFANameAndIcon:[project projectBrowser]];
}

// ============================================================================
// ==== Build Attributes
// ============================================================================

- (void)createBuildAttributes
{
  if (buildAttributesView)
    {
      return;
    }

  if ([NSBundle loadNibNamed:@"BuildAttributes" owner:self] == NO)
    {
      PCLogError(self, @"error loading BuildAttributes NIB file!");
      return;
    }

  // Search Order
  // Popup
  [searchOrderPopup removeAllItems];
  [searchOrderPopup addItemWithTitle:@"Header Directories Search Order"];
  [searchOrderPopup addItemWithTitle:@"Library Directories Search Order"];
  [searchOrderPopup addItemWithTitle:@"Framework Directories Search Order"];
  [searchOrderPopup selectItemAtIndex:0];

  // Table column
  searchOrderColumn = [[NSTableColumn alloc] initWithIdentifier: @"SO List"];
  [searchOrderColumn setEditable:NO];

  // Table
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
  [searchOrderList setDrawsGrid:NO];
  [searchOrderList setTarget:self];
  [searchOrderList setDoubleAction:@selector(searchOrderDoubleClick:)];
  [searchOrderList setAction:@selector(searchOrderClick:)];

  // ScrollView
  [searchOrderScroll setDocumentView:searchOrderList];
  [searchOrderScroll setHasHorizontalScroller:NO];
  [searchOrderScroll setHasVerticalScroller:YES];
  [searchOrderScroll setBorderType:NSBezelBorder];
  RELEASE(searchOrderList);

  // Buttons
  [self setSearchOrderButtonsState];

  [cppOptField setNextText:objcOptField];
  [objcOptField setNextText:cOptField];
  [cOptField setNextText:ldOptField];
  [ldOptField setNextText:installPathField];
  [installPathField setNextText:toolField];
  [toolField setNextText:cppOptField];
  
  // Retain view
  [buildAttributesView retain];
}

// --- Search Order
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
  if (projectDescriptionView)
    {
      return;
    }
    
  if ([NSBundle loadNibNamed:@"ProjectDescription" owner:self] == NO)
    {
      PCLogError(self, @"error loading ProjectDescription NIB file!");
      return;
    }

  // Authors table
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
  [authorsScroll setDocumentView:authorsList];
  [authorsScroll setHasHorizontalScroller:NO];
  [authorsScroll setHasVerticalScroller:YES];
  [authorsScroll setBorderType:NSBezelBorder];

  // Authors' buttons
  [authorAdd setRefusesFirstResponder:YES];
  [authorRemove setRefusesFirstResponder:YES];
  
  [authorUp setRefusesFirstResponder:YES];
  [authorUp setImage: [NSImage imageNamed:@"common_ArrowUp"]];
  
  [authorDown setRefusesFirstResponder:YES];
  [authorDown setImage: [NSImage imageNamed:@"common_ArrowDown"]];

  // Link textfields
  [descriptionField setNextText:releaseField];
  [releaseField setNextText:licenseField];
  [licenseField setNextText:licDescriptionField];
  [licDescriptionField setNextText:urlField];
  [urlField setNextText:descriptionField];

  [projectDescriptionView retain];
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
  if (fileAttributesView)
    {
      return;
    }

  if ([NSBundle loadNibNamed:@"FileAttributes" owner:self] == NO)
    {
      PCLogError(self, @"error loading ProjectDescription NIB file!");
      return;
    }

  [fileAttributesView retain];

/*  [[NSNotificationCenter defaultCenter] 
    addObserver:self
       selector:@selector(browserDidSetPath:)
           name:PCBrowserDidSetPathNotification
         object:[project projectBrowser]];*/
  [[NSNotificationCenter defaultCenter] 
    addObserver:self
       selector:@selector(panelDidResignKey:)
           name: NSWindowDidResignKeyNotification
         object:inspectorPanel];
}

- (void)beginFileRename
{
  [fileNameField setEditableField:YES];
  [inspectorPanel makeFirstResponder:fileNameField];
}

- (void)setFANameAndIcon:(PCProjectBrowser *)browser
{
  if (fileName != nil)
    {
      [fileName release];
    }
  fileName = [[browser nameOfSelectedFile] retain];

  if (fileName)
    {
      [fileNameField setStringValue:fileName];
      [fileIconView setImage:[[project projectWindow] fileIconImage]];
    }
  else if ([[browser selectedFiles] count] > 1)
    {
      [fileNameField setStringValue:@"Multiple files selected"];
      [fileIconView setImage:[[project projectWindow] fileIconImage]];
    }
  else
    {
      [fileNameField setStringValue:@"No files selected"];
      [fileIconView setImage:[NSImage imageNamed:@"common_Unknown"]];
    }
}

- (void)fileNameDidChange:(id)sender
{
  if ([fileName isEqualToString:[fileNameField stringValue]])
    {
      return;
    }

  PCLogInfo(self, @"{%@} file name changed from: %@ to: %@",
	    [project projectName], fileName, [fileNameField stringValue]);

  if ([project renameFile:fileName toFile:[fileNameField stringValue]] == NO)
    {
      [fileNameField setStringValue:fileName];
    }
}

// --- Notifications
- (void)browserDidSetPath:(NSNotification *)aNotif
{
  [self setFANameAndIcon:[aNotif object]];
}

- (void)panelDidResignKey:(NSNotification *)aNotif
{
  if ([fileNameField isEditable] == YES)
    {
      [inspectorPanel makeFirstResponder:fileIconView];
      [fileNameField setStringValue:fileName];
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
