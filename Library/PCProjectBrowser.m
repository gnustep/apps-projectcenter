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
// ==== Accessor methods
// ============================================================================

- (NSView *)view
{
  return browser;
}

// This is responsibility of PC*Project classes
- (BOOL)isEditableCategory:(NSString *)category  file:(NSString *)title
{
  NSString *key = [project keyForCategory:category];

  if ([key isEqualToString:PCClasses]
      || [key isEqualToString:PCHeaders]
      || [key isEqualToString:PCSupportingFiles]
      || [key isEqualToString:PCDocuFiles]
      || [key isEqualToString:PCOtherSources]
      || [key isEqualToString:PCOtherResources]
      || [key isEqualToString:PCNonProject]) 
    {
      return YES;
    }

  if ([key isEqualToString:PCGSMarkupFiles]
      && [[title pathExtension] isEqual: @"gorm"] == NO)
    {
      return YES;
    }

  return NO;
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
  if ([[sender selectedCell] isLeaf] && [[self selectedFiles] count] == 1)
    {
      NSString *category = [[sender selectedCellInColumn:0] stringValue];
      NSString *fn = [[sender selectedCell] stringValue];
      NSString *fp = [[project projectPath] stringByAppendingPathComponent:fn];

      if ([self isEditableCategory:category file:fn])
	{
	  [[project projectEditor] editorForFile:fp
	                                category:category
					windowed:NO];
	}
    }

  [[NSNotificationCenter defaultCenter]
    postNotificationName:PCBrowserDidSetPathNotification 
                  object:self];
}

- (void)doubleClick:(id)sender
{
  if ([[sender selectedCell] isLeaf]) 
    {
      NSString *category = [[sender selectedCellInColumn:0] stringValue];
      NSString *fn = [[sender selectedCell] stringValue];
      NSString *fp = [[project projectPath] stringByAppendingPathComponent:fn];

      if ([self isEditableCategory:category file: fn])
	{
	  [[project projectEditor] editorForFile:fp
	                                category:category
					windowed:YES];
	}
      else if([[NSWorkspace sharedWorkspace] openFile:fp] == NO) 
	{
	  NSRunAlertPanel(@"Attention!",
			  @"Could not open %@.",
			  @"OK",nil,nil,fp);
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
  if (browser) 
    {
      NSString *browserPath = [browser path];
      NSString *path = nil;
      NSString *slctdCategory = [project selectedRootCategory];
 
      if (slctdCategory && browserPath && ![browserPath isEqualToString:@"/"])
	{
	  path = [[browserPath componentsSeparatedByString:@"/"] 
	    objectAtIndex:1];

	  if ([[[project projectEditor] allEditors] count] == 0
	      && [self isEditableCategory:slctdCategory file:nil])
	    {
	      [self setPathForFile:nil category:path];
	    }
	}

      [browser reloadColumn:[browser lastColumn]];
    }
}

@end

@implementation PCProjectBrowser (ProjectBrowserDelegate)

- (void)browser:(NSBrowser *)sender createRowsForColumn:(int)column inMatrix:(NSMatrix *)matrix
{
  NSString *pathToCol = [sender pathToColumn:column];
  NSArray  *files = [project contentAtCategoryPath:pathToCol];
  int      i;
  int      count = [files count];

  if (sender != browser)
    {
      return;
    }

  for (i = 0; i < count; ++i) 
    {
      NSMutableString *categoryPath = nil;
      id              cell;
      
      categoryPath = [NSMutableString stringWithString:pathToCol];
      
      [matrix insertRow:i];

      cell = [matrix cellAtRow:i column:0];
      [cell setStringValue:[files objectAtIndex:i]];

      [categoryPath appendString:@"/"];
      [categoryPath appendString:[files objectAtIndex:i]];

      [cell setLeaf:![project hasChildrenAtCategoryPath:categoryPath]];
    }
}

@end
