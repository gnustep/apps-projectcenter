/*
   GNUstep ProjectCenter - http://www.projectcenter.ch

   Copyright (C) 2000 Philippe C.D. Robert

   Author: Philippe C.D. Robert <phr@projectcenter.ch>

   This file is part of ProjectCenter.

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

@implementation PCBrowserController

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [super dealloc];
}

- (void)click:(id)sender
{
  NSTextView *pTextView;

  if ([[sender selectedCell] isLeaf]) {
    NSString *ltitle = [[sender selectedCell] stringValue];
    NSString *ctitle = [[sender selectedCellInColumn:0] stringValue];
    NSString *ctitlef = [[project projectPath] stringByAppendingPathComponent:ltitle];

    pTextView = [project textView];

    NSLog(@"****** %@",ctitlef);

    if ([ctitle isEqualToString:@"Classes"]) {
      NSString *f = [NSString stringWithContentsOfFile:ctitlef];

      [pTextView setString:f];
    }
    else if ([ctitle isEqualToString:@"Headers"]) {
      NSString *f = [NSString stringWithContentsOfFile:ctitlef];

      [pTextView setString:f];
    }
    else if ([ctitle isEqualToString:@"Other Sources"]) {
      NSString *f = [NSString stringWithContentsOfFile:ctitlef];

      [pTextView setString:f];
    }

    // This should not be needed!
    [pTextView display];
  }
}

- (void)doubleClick:(id)sender
{
#warning No subproject support here yet!
    /*
    if ([sender selectedColumn] == 0) {
        // Ask the project about the valid file types
        //NSArray *types = [project typesForKeyPath:[sender pathToColumn:0]];
        NSOpenPanel	*openPanel;
        int		retval;
        NSArray 	*types;

        openPanel = [NSOpenPanel openPanel];
        [openPanel setAllowsMultipleSelection:NO];
        [openPanel setCanChooseDirectories:NO];
        [openPanel setCanChooseFiles:YES];

        if ((retval = [openPanel runModalForDirectory:[[NSUserDefaults standardUserDefaults] objectForKey:@"LastOpenDirectory"] file:nil types:types])) {
            NSString *key = [project projectKeyForKeyPath:[sender path]];
            
            [project addFile:[[openPanel filenames] objectAtIndex:0] forKey:key];

            [[NSUserDefaults standardUserDefaults] setObject:[openPanel directory] forKey:@"LastOpenDirectory"];            
        }
    }
    else {
    }
     */
}

- (void)projectDictDidChange:(NSNotification *)aNotif
{
  [browser loadColumnZero];
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
  NSString *path = nil;
  
  // Doesn't work with subprojects!
  if ([browser selectedColumn] != 0) {
    path = [browser path];
  }
  
  return path;
}

- (void)setBrowser:(NSBrowser *)aBrowser
{
  [browser autorelease];
  browser = [aBrowser retain];
  
  [browser setTitled:NO];

  [browser setTarget:self];
  [browser setAction:@selector(click:)];
  [browser setDoubleAction:@selector(doubleClick:)];
  
  [browser setMaxVisibleColumns:3];
  [browser setAllowsMultipleSelection:NO];
  
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(projectDictDidChange:) name:@"ProjectDictDidChangeNotification" object:project];
}

- (void)setProject:(PCProject *)aProj
{
  [project autorelease];
  project = [aProj retain];
}

@end

@implementation PCBrowserController (ProjectBrowserDelegate)

- (void)browser:(NSBrowser *)sender createRowsForColumn:(int)column inMatrix:(NSMatrix *)matrix
{
    NSString 	*pathToCol = [sender pathToColumn:column];
    NSArray	*files = [project contentAtKeyPath:pathToCol];
    int 	i;
    int		count = [files count];
    
    if (count == 0) {
      NSLog(@"<%@ %x>: create rows for column aborted - 0 files!",[self class],self);
      return;
    }

#ifdef DEBUG
    NSLog(@"<%@ %x>: create rows for column %d in %x",[self class],self,column,sender);
#endif DEBUG

    for (i = 0; i < count; ++i) {
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
#ifdef DEBUG
  NSLog(@"<%@ %x>: browser %x will display %@ %x at %d,%d",[self class],self,sender,[cell class],cell,row,column);
#endif DEBUG
}

- (BOOL)browser:(NSBrowser *)sender selectCellWithString:(NSString *)title inColumn:(int)column
{
    return YES;
}

@end





