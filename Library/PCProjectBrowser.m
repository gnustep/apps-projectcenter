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
#include "PCFileManager.h"
#include "PCProjectManager.h"
#include "PCProject.h"
#include "PCProjectEditor.h"
#include "PCProjectBrowser.h"

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
	     object:project];

    }

  return self;
}

- (void)dealloc
{
  NSLog (@"PCProjectBrowser: dealloc");
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

- (NSString *)nameOfSelectedFile
{
  NSString *name = nil;

  // Doesn't work with subprojects!
  if ([browser selectedColumn] != 0 && [[browser selectedCells] count] == 1)
    {
      name = [[[browser path] componentsSeparatedByString:@"/"] lastObject];
    }
  
  return name;
}

- (NSString *)pathOfSelectedFile
{
  return [browser path];
}

- (NSArray *)selectedFiles
{
  NSArray        *cells = [browser selectedCells];
  NSMutableArray *files = [[NSMutableArray alloc] initWithCapacity: 1];
  int            i;
  int            count = [cells count];

  for (i = 0; i < count; i++)
    {
      [files addObject: [[cells objectAtIndex: i] stringValue]];
    }

  return (NSArray *)files;
}

- (BOOL)setPath:(NSString *)path
{
  int      selectedColumn;
  NSMatrix *columnMatrix = nil;

  while ((selectedColumn = [browser selectedColumn]) >= 0)
    {
      columnMatrix = [browser matrixInColumn:selectedColumn];
      [columnMatrix deselectAllCells];
    }

  NSLog(@"NSPB {setPath}: %@", path);

  return [browser setPath:path];
}

- (BOOL)setPathForFile:(NSString *)file category:(NSString *)category
{
  NSArray  *comp = [NSArray arrayWithObjects: @"/",category,@"/",file,nil];
  NSString *path = [NSString pathWithComponents:comp];
  BOOL     result;

  int      selectedColumn;
  NSMatrix *columnMatrix = nil;

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

  result = [browser setPath:path];

  [self click:browser];
  
/*  [[NSNotificationCenter defaultCenter]
    postNotificationName:PCBrowserDidSetPathNotification 
                  object:self];*/

  return result;
}

// ============================================================================
// ==== Actions
// ============================================================================

- (void)click:(id)sender
{
  if (sender != browser)
    {
      return;
    }
    
  if ([[sender selectedCell] isLeaf] && [[self selectedFiles] count] == 1)
    {
      NSString  *category = [project categoryForCategoryPath:[browser path]];
      NSString  *fileName = [[sender selectedCell] stringValue];
      PCProject *sp = nil;
      NSString  *filePath = nil;
      NSDictionary *prefsDict = nil;

      if ((sp = [project activeSubproject]) != nil)
	{
	  filePath = [[sp projectPath] 
	    stringByAppendingPathComponent:fileName];
	}
      else
	{
	  filePath = [[project projectPath] 
	    stringByAppendingPathComponent:fileName];
	}

      NSLog(@"NSPB {click:} category: %@ filePath: %@", category, filePath);

      if ([project isEditableCategory:category] 
	  || [sp isEditableCategory:category])
	{
	  prefsDict = [[project projectManager] preferencesDict];
	  if (![[prefsDict objectForKey:@"SeparateEditor"] 
	      isEqualToString:@"YES"])
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
  if (sender != browser)
    {
      return;
    }

  if ([[sender selectedCell] isLeaf]) 
    {
      NSString  *category = [project categoryForCategoryPath:[browser path]];
      NSString  *fileName = [[sender selectedCell] stringValue];
      PCProject *sp = nil;
      NSString  *filePath = nil;

      if ((sp = [project activeSubproject]) != nil)
	{
	  filePath = [[sp projectPath] 
	    stringByAppendingPathComponent:fileName];
	}
      else
	{
	  filePath = [[project projectPath] 
	    stringByAppendingPathComponent:fileName];
	}


      if ([project isEditableCategory:category] 
	  || [sp isEditableCategory:category])
	{
	  [[project projectEditor] editorForFile:filePath
	                            categoryPath:[browser path]
					windowed:YES];
	}
      else if([[NSWorkspace sharedWorkspace] openFile:filePath] == NO) 
	{
	  NSRunAlertPanel(@"Attention!",
			  @"Could not open %@.",
			  @"OK",nil,nil,filePath);
	}
    }
  else 
    {
      [[project projectManager] addProjectFiles];
    }
}

// ============================================================================
// ==== Notifications
// ============================================================================

- (void)projectDictDidChange:(NSNotification *)aNotif
{
  if (browser && 
      ([aNotif object] == project 
       || [[project loadedSubprojects] containsObject:[aNotif object]]))
    {
      NSString *browserPath = [browser path];
      NSString *slctdCategory = [project selectedRootCategory];
 
      if (slctdCategory && browserPath && ![browserPath isEqualToString:@"/"])
	{
	  if ([[[project projectEditor] allEditors] count] == 0
	      && [project isEditableCategory:slctdCategory])
	    {
	      [self setPathForFile:nil category:slctdCategory];
	    }
	}

      [browser reloadColumn:[browser lastColumn]];
    }
}

@end

@implementation PCProjectBrowser (ProjectBrowserDelegate)

- (void)browser:(NSBrowser *)sender createRowsForColumn:(int)column inMatrix:(NSMatrix *)matrix
{
  NSString *pathToCol = nil;
  NSArray  *files = nil;
  int      i = 0;
  int      count = 0;

  if (sender != browser || !matrix ||![matrix isKindOfClass:[NSMatrix class]])
    {
      return;
    }

  pathToCol = [sender pathToColumn:column];
  files = [project contentAtCategoryPath:pathToCol];
  count = [files count];

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
