/*
   GNUstep ProjectCenter - http://www.gnustep.org

   Copyright (C) 2000-2004 Free Software Foundation

   Authors: Philippe C.D. Robert
            Serg Stoyan

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
#include "PCFileManager.h"
#include "PCProjectManager.h"
#include "PCProject.h"
#include "PCProjectBrowser.h"
#include "PCProjectEditor.h"

#include "PCLogController.h"

NSString *PCBrowserDidSetPathNotification = @"PCBrowserDidSetPathNotification";

@implementation PCProjectBrowser

// ============================================================================
// ==== Intialization & deallocation
// ============================================================================

- (id)initWithProject:(PCProject *)aProject
{
  if ((self = [super init]))
    {
      project = aProject;

      browser = [[NSBrowser alloc] initWithFrame:NSMakeRect(-1,251,562,128)];
      [browser setRefusesFirstResponder:YES];
      [browser setAutoresizingMask: NSViewWidthSizable | NSViewMinYMargin];
      [browser setTitled:NO];
      [browser setMaxVisibleColumns:4];
      [browser setSeparatesColumns:NO];
      [browser setAllowsMultipleSelection:YES];
      [browser setDelegate:self];
      [browser setTarget:self];
      [browser setAction:@selector(click:)];
      [browser setDoubleAction:@selector(doubleClick:)];
      [browser loadColumnZero];

      [[NSNotificationCenter defaultCenter] 
	addObserver:self 
	   selector:@selector(projectDictDidChange:)
	       name:PCProjectDictDidChangeNotification 
	     object:nil];
    }

  return self;
}

- (void)dealloc
{
#ifdef DEVELOPMENT
  NSLog (@"PCProjectBrowser: dealloc");
#endif

  [[NSNotificationCenter defaultCenter] removeObserver:self];

  RELEASE(browser);

  [super dealloc];
}

// ============================================================================
// ==== Accessory methods
// ============================================================================

- (NSView *)view
{
  return browser;
}

// Returns nil if multiple files selected
- (NSString *)nameOfSelectedFile
{
  NSString *name = nil;

  if ([[browser selectedCells] count] == 1)
    {
      name = [[browser path] lastPathComponent];
      if ([name isEqualToString:[self nameOfSelectedCategory]])
	{
	  return nil;
	}
    }
    
  return name;
}

// Returns nil if multiple files selected
- (NSString *)pathToSelectedFile
{
  NSString *name = nil;
  NSString *path = nil;

  if ([[browser selectedCells] count] == 1)
    {
      name = [[browser path] lastPathComponent];
      if ([name isEqualToString:[self nameOfSelectedCategory]])
	{
	  path = nil;
	}
      else
	{
	  path = [browser path];
	}
    }
  
  return path;
}

// Returns nil of multiple categories selected
- (NSString *)nameOfSelectedCategory
{
  NSString  *name = nil;
  NSArray   *pathArray = [[browser path] componentsSeparatedByString:@"/"];
  PCProject *activeProject = [[project projectManager] activeProject];
  NSArray   *rootCategories = [activeProject rootCategories];
  int       i;

  if ([rootCategories containsObject:[pathArray lastObject]]
      && [[browser selectedCells] count] > 1)
    {
      return nil;
    }

  for (i = [pathArray count] - 1; i >= 0; i--)
    {
      if ([rootCategories containsObject:[pathArray objectAtIndex:i]])
	{
	  name = [pathArray objectAtIndex:i];
	  break;
	}
    }
  
  return name;
}

// Returns nil of multiple categories selected
- (NSString *)pathToSelectedCategory
{
  NSString       *path = nil;
  NSString       *selectedCategory = [self nameOfSelectedCategory];
  NSMutableArray *bPathArray = nil;
  int            i;
 
  if (selectedCategory)
    {
      bPathArray = [NSMutableArray arrayWithArray:[[browser path]
	componentsSeparatedByString:@"/"]];
      i = [bPathArray count] - 1;
      while (![[bPathArray objectAtIndex:i] isEqualToString:selectedCategory])
	{
	  [bPathArray removeObjectAtIndex:i];
	  i = [bPathArray count] - 1;
	}
      path = [bPathArray componentsJoinedByString:@"/"];
    }
  
  return path;
}

- (NSString *)nameOfSelectedRootCategory
{
  NSString *categoryPath = [self pathToSelectedCategory];
  NSArray  *pathComponents = nil;

  if ([categoryPath isEqualToString:@"/"] || [categoryPath isEqualToString:@""])
    {
      return nil;
    }
    
  pathComponents = [categoryPath componentsSeparatedByString:@"/"];

  return [pathComponents objectAtIndex:1];
}

- (NSArray *)selectedFiles
{
  NSArray        *cells = [browser selectedCells];
  NSMutableArray *files = [[NSMutableArray alloc] initWithCapacity: 1];
  int            i;
  int            count = [cells count];
  PCProject      *activeProject = [[project projectManager] activeProject];

  // Return nil if categories selected
  if ([cells count] == 0
      || [[activeProject rootCategories] 
      containsObject:[[cells objectAtIndex:0] stringValue]])
    {
      return nil;
    }

  for (i = 0; i < count; i++)
    {
      [files addObject: [[cells objectAtIndex: i] stringValue]];
    }
    
  return AUTORELEASE((NSArray *)files);
}

- (NSString *)path
{
  return [browser path];
}

- (BOOL)setPath:(NSString *)path
{
  int      selectedColumn;
  NSMatrix *columnMatrix = nil;
  BOOL     res;

  if ([[browser path] isEqualToString: path])
    {
      return YES;
    }

  // HACK!!! NSBrowser needs fixing!!!
  while ((selectedColumn = [browser selectedColumn]) >= 0)
    {
      columnMatrix = [browser matrixInColumn:selectedColumn];
      [columnMatrix deselectAllCells];
    }
  // End of HACK

  PCLogInfo(self, @"[setPath]: %@", path);

  res = [browser setPath:path];

  [[NSNotificationCenter defaultCenter]
    postNotificationName:PCBrowserDidSetPathNotification
                  object:self];

  return res;
}

- (void)reloadLastColumnAndNotify:(BOOL)yn
{
  int       column = [browser lastColumn];
  NSString  *category = [self nameOfSelectedCategory];
  int       selectedColumn = [browser selectedColumn];
  NSMatrix  *colMatrix = [browser matrixInColumn:selectedColumn];
  int       rowCount = 0, colCount = 0, spCount = 0;
  PCProject *activeProject = [[project projectManager] activeProject];
  NSString  *selCellTitle = [[browser selectedCell] stringValue];

  if ([category isEqualToString:@"Subprojects"]
      && ![selCellTitle isEqualToString:@"Subprojects"])
    { // /Subprojects/Name selected
      if ([selCellTitle isEqualToString:[activeProject projectName]])
	{
	  activeProject = [activeProject superProject];
	}
      [colMatrix getNumberOfRows:&rowCount columns:&colCount];
      spCount = [[[activeProject projectDict] 
	objectForKey:PCSubprojects] count];
    }

  if ([category isEqualToString:@"Subprojects"] && rowCount != spCount
      && ![[[browser selectedCell] stringValue] isEqualToString:@"Subprojects"])
    {
      column = selectedColumn;
    }
  
  [browser reloadColumn:column];

  if (yn)
    {
      [[NSNotificationCenter defaultCenter]
	postNotificationName:PCBrowserDidSetPathNotification
                      object:self];
    }
}

- (void)reloadLastColumnAndSelectFile:(NSString *)file
{
  PCProject *p = [[project projectManager] activeProject];
  NSString  *catKey = [p keyForCategory:[self nameOfSelectedCategory]];
  NSArray   *array = [[p projectDict] objectForKey:catKey];
  
  [self reloadLastColumnAndNotify:NO];

  [browser selectRow:[array indexOfObject:file] inColumn:[browser lastColumn]];

  // Notify
  [[NSNotificationCenter defaultCenter]
    postNotificationName:PCBrowserDidSetPathNotification
                  object:self];
}

// ============================================================================
// ==== Actions
// ============================================================================

- (void)click:(id)sender
{
  NSUserDefaults *ud = nil;
  NSString       *category = nil;
  NSString       *fileName = nil;
  NSString       *filePath = nil;
  NSString       *key = nil;
  PCProject      *activeProject = nil;
  NSFileManager  *fm = [NSFileManager defaultManager];
  BOOL           isDir;

  if (sender != browser)
    {
      return;
    }

  if ([[sender selectedCell] isLeaf] && [[self selectedFiles] count] == 1)
    {
      ud = [NSUserDefaults standardUserDefaults];
      category = [self nameOfSelectedCategory];
      fileName = [[sender selectedCell] stringValue];
      
      activeProject = [[project projectManager] activeProject];
      key = [activeProject keyForCategory:category];
      filePath = [activeProject dirForCategoryKey:key];
      filePath = [filePath stringByAppendingPathComponent:fileName];

      PCLogInfo(self, @"[click] category: %@ filePath: %@",
		category, filePath);

      if ([activeProject isEditableCategory:category]
	  && [fm fileExistsAtPath:filePath isDirectory:&isDir] && !isDir)
	{
	  if (![[ud objectForKey:SeparateEditor] isEqualToString:@"YES"])
	    {
	      [[project projectEditor] editorForFile:filePath
		                        categoryPath:[browser path]
					    windowed:NO];
	    }
	}
    }

  [[NSNotificationCenter defaultCenter]
    postNotificationName:PCBrowserDidSetPathNotification 
                  object:self];
}

- (void)doubleClick:(id)sender
{
  id selectedCell;
  
  if (sender != browser)
    {
      return;
    }

  selectedCell = [sender selectedCell];

  if ([selectedCell isLeaf]) 
    {
      NSString  *category = [self nameOfSelectedCategory];
      NSString  *fileName = [[sender selectedCell] stringValue];
      NSString  *filePath = nil;
      NSString  *key = nil;
      PCProject *activeProject = nil;
      
      activeProject = [[project projectManager] activeProject];
      key = [activeProject keyForCategory:category];
      filePath = [activeProject dirForCategoryKey:key];
      filePath = [filePath stringByAppendingPathComponent:fileName];

      PCLogInfo(self, @"{doubleClick} filePath: %@", filePath);

      if ([activeProject isEditableCategory:category])
	{
	  [[project projectEditor] editorForFile:filePath
	                            categoryPath:[browser path]
					windowed:YES];
	}
      else if ([[NSWorkspace sharedWorkspace] openFile:filePath] == NO) 
	{
	  NSRunAlertPanel(@"Attention!",
			  @"Could not open %@.",
			  @"OK",nil,nil,filePath);
	}
    }
  else 
    {
      if ([[selectedCell title] isEqualToString:@"Subprojects"]) 
	{
	  [[project projectManager] addSubproject];
	}
      else
	{
	  [[project projectManager] addProjectFiles];
	}
    }
}

// ============================================================================
// ==== Notifications
// ============================================================================

- (void)projectDictDidChange:(NSNotification *)aNotif
{
  NSDictionary *notifObject = [aNotif object];
  PCProject    *changedProject = [notifObject objectForKey:@"Project"];
  NSString     *changedAttribute = [notifObject objectForKey:@"Attribute"];

  if (!browser)
    {
      return;
    }

  if (changedProject != project 
      && changedProject != [project activeSubproject]
      && [changedProject superProject] != [project activeSubproject])
    {
      return;
    }

  if ([[changedProject sourceFileKeys] containsObject:changedAttribute]
      || [[changedProject resourceFileKeys] containsObject:changedAttribute]
      || [[changedProject otherKeys] containsObject:changedAttribute])
    {
      [self reloadLastColumnAndNotify:YES];
    }
}

@end

@implementation PCProjectBrowser (ProjectBrowserDelegate)

- (void)browser:(NSBrowser *)sender createRowsForColumn:(int)column
                                               inMatrix:(NSMatrix *)matrix
{
  NSString  *pathToCol = nil;
  NSArray   *files = nil;
  int       i = 0;
  int       count = 0;

  if (sender != browser || !matrix || ![matrix isKindOfClass:[NSMatrix class]])
    {
      return;
    }

  pathToCol = [sender pathToColumn:column];
  files = [project contentAtCategoryPath:pathToCol];
  if (files)
    {
      count = [files count];
    }

  for (i = 0; i < count; ++i) 
    {
      NSMutableString *categoryPath = nil;
      id              cell;
      
      categoryPath = [NSMutableString stringWithString:pathToCol];
      
      [matrix insertRow:i];

      cell = [matrix cellAtRow:i column:0];
      [cell setStringValue:[files objectAtIndex:i]];

      if (![categoryPath isEqualToString:@"/"])
	{
	  [categoryPath appendString:@"/"];
	}
      [categoryPath appendString:[files objectAtIndex:i]];

      [cell setLeaf:![project hasChildrenAtCategoryPath:categoryPath]];
    }
}

@end
