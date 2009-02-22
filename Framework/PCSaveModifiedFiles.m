/*
   GNUstep ProjectCenter - http://www.gnustep.org/experience/ProjectCenter.html

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

#import <ProjectCenter/PCEditorManager.h>

#import <ProjectCenter/PCSaveModifiedFiles.h>

@implementation PCSaveModifiedFiles

- (BOOL)openWithEditorManager:(PCEditorManager *)manager
	    defaultButtonText:(NSString *)defaultText
	  alternateButtonText:(NSString *)alternateText
	      otherButtonText:(NSString *)otherText
{
  NSArray *filesToSave = nil;

  if ([NSBundle loadNibNamed:@"SaveModifiedFiles" owner:self] == NO)
    {
      NSLog(@"Error loading SaveModifiedFiles NIB file!");
      return NO;
    }

  editorManager = manager;

  // Table
  [filesList setCornerView:nil];
  [filesList setHeaderView:nil];
  [filesList setDataSource:self];
  [filesList setTarget:self];
//  [filesList selectAll];
  [filesList reloadData];

  // Buttons
  [defaultButton setStringValue:defaultText];
  [alternateButton setStringValue:alternateText];
  [otherButton setStringValue:otherText];

  [panel makeKeyAndOrderFront:self];

  [NSApp runModalForWindow:panel];

  if (clickedButton == defaultButton)
    {
      // save files
      return YES;
    }
  else if (clickedButton == alternateButton)
    {
      return YES;
    }
  else if (clickedButton == otherButton)
    {
      return NO;
    }

  NSLog(@"MODAL is not BLOCKING!!!");

  return YES;
}

- (void)dealloc
{
#ifdef DEBUG
  NSLog(@"PCSaveModifiedFiles: dealloc");
#endif
  RELEASE(panel);

  [super dealloc];
}

- (BOOL)saveSelectedFiles
{
  return YES;
}

- (void)buttonClicked:(id)sender
{
  clickedButton = sender;
  [NSApp stopModal];
  [panel close];
}

- (int)numberOfRowsInTableView:(NSTableView *)aTableView
{
  if (aTableView != filesList)
    {
      return 0;
    }
  
  return [[editorManager modifiedFiles] count];
}

- (id)            tableView:(NSTableView *)aTableView
  objectValueForTableColumn:(NSTableColumn *)aTableColumn
                        row:(int)rowIndex
{
  if (aTableView != filesList)
    {
      return nil;
    }

  return [[[editorManager modifiedFiles] objectAtIndex:rowIndex] lastPathComponent];
}

@end

