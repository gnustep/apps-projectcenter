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

#import "PCBrowserController.h"
#import "PCProject.h"
#import "PCFileManager.h"

@implementation PCBrowserController

- (void)dealloc
{
  [[NSNotificationCenter defaultCenter] removeObserver:self];

  [super dealloc];
}

- (void)click:(id)sender
{
  if ([[sender selectedCell] isLeaf]) 
  {
    NSString *ltitle   = [[sender selectedCell] stringValue];
    NSString *category = [[sender selectedCellInColumn:0] stringValue];

    if ([self isEditableCategory:category file: ltitle])
    {
	[[NSNotificationCenter defaultCenter] postNotificationName:@"FileBecomesEditedNotification" object:ltitle];
	
	[project browserDidClickFile:ltitle category:category];
    }
  }
}

- (void)doubleClick:(id)sender
{
  if ([[sender selectedCell] isLeaf]) 
  {
    NSString *category = [[sender selectedCellInColumn:0] stringValue];
    NSString *fn = [self nameOfSelectedFile];
    NSString *f = [[project projectPath] stringByAppendingPathComponent:fn];

    if ([self isEditableCategory:category file: fn])
    {
      [project browserDidDblClickFile:f category:category];
    }
    else if([[NSWorkspace sharedWorkspace] openFile:f] == NO) 
    {
	NSRunAlertPanel(@"Attention!",@"Could not open %@.",@"OK",nil,nil,f);
    }
  }
  else 
  {
    [[PCFileManager fileManager] showAddFileWindow];
  }
}

- (BOOL)isEditableCategory:(NSString *)category  file: (NSString *)title
{
    NSString *k = [[project rootCategories] objectForKey:category];

    if ([k isEqualToString:PCClasses] || 
	[k isEqualToString:PCHeaders] || 
	[k isEqualToString:PCOtherResources] || 
	[k isEqualToString:PCSupportingFiles] || 
	[k isEqualToString:PCDocuFiles] || 
	[k isEqualToString:PCOtherSources]) 
    {
        return YES;
    }

    if ([k isEqualToString:PCGSMarkupFiles]
	&& [[title pathExtension] isEqual: @"gorm"] == NO)
      {
        return YES;
      }

    return NO;
}

- (void)projectDictDidChange:(NSNotification *)aNotif
{
    if (browser) 
    {
        [browser reloadColumn:[browser lastColumn]];
    }
}

- (NSString *)nameOfSelectedFile
{
  NSString *name = nil;

  // Doesn't work with subprojects!
  if ([browser selectedColumn] != 0) {
    name = [[[browser path] componentsSeparatedByString:@"/"] lastObject];
  }
  
  return name;
}

- (NSString *)pathOfSelectedFile
{
  return [browser path];
}

- (void)setBrowser:(NSBrowser *)aBrowser
{
  browser = aBrowser;
  
  [browser setTitled:NO];

  [browser setTarget:self];
  [browser setAction:@selector(click:)];
  [browser setDoubleAction:@selector(doubleClick:)];
  
  [browser setMaxVisibleColumns:3];
  [browser setAllowsMultipleSelection:NO];
  
  [[NSNotificationCenter defaultCenter] addObserver:self 
                                       selector:@selector(projectDictDidChange:)
				       name:@"ProjectDictDidChangeNotification" 
				       object:project];
}

- (void)setProject:(PCProject *)aProj
{
  project = aProj;
}

@end

@implementation PCBrowserController (ProjectBrowserDelegate)

- (void)browser:(NSBrowser *)sender createRowsForColumn:(int)column inMatrix:(NSMatrix *)matrix
{
    NSString 	*pathToCol = [sender pathToColumn:column];
    NSArray	*files = [project contentAtKeyPath:pathToCol];
    int 	i;
    int		count = [files count];
    
    if( sender != browser ) return;

    for (i = 0; i < count; ++i) 
    {
      NSMutableString *keyPath = [NSMutableString stringWithString:pathToCol];
      id cell;
      
      [matrix insertRow:i];
      
      cell = [matrix cellAtRow:i column:0];
      [cell setStringValue:[files objectAtIndex:i]];
      
      [keyPath appendString:@"/"];
      [keyPath appendString:[files objectAtIndex:i]];
      
      [cell setLeaf:![project hasChildrenAtKeyPath:keyPath]];
    }
}

- (void)browser:(NSBrowser *)sender willDisplayCell:(id)cell atRow:(int)row column:(int)column
{
}

- (BOOL)browser:(NSBrowser *)sender selectCellWithString:(NSString *)title inColumn:(int)column
{
    return YES;
}

@end
