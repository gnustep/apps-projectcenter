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

#import "PCMenuController.h"

#import <ProjectCenter/ProjectCenter.h>
#import "PCAppController.h"

#if defined(GNUSTEP)
#import <AppKit/IMLoading.h>
#endif

@implementation PCMenuController

- (id)init
{
    if ((self = [super init])) {
      // The accessory view
      projectTypeAccessaryView = [[NSBox alloc] init];
      projectTypePopup = [[[NSPopUpButton alloc] initWithFrame:NSMakeRect(20,30,160,20) pullsDown:NO] autorelease];
      [projectTypePopup addItemWithTitle:@"No type available!"];
      
      [projectTypeAccessaryView setTitle:@"Project Types"];
      [projectTypeAccessaryView setTitlePosition:NSAtTop];
      [projectTypeAccessaryView setBorderType:NSGrooveBorder];
      [projectTypeAccessaryView addSubview:projectTypePopup];
      [projectTypeAccessaryView sizeToFit];
      [projectTypeAccessaryView setAutoresizingMask: NSViewWidthSizable];
    }
    return self;
}

- (void)dealloc
{
  [projectTypeAccessaryView release];
  [super dealloc];
}

- (void)addProjectTypeNamed:(NSString *)name
{
    static BOOL _firstItem = YES;

    if (_firstItem) {
        _firstItem = NO;
        [projectTypePopup removeItemWithTitle:@"No type available!"];
    }

    [projectTypePopup addItemWithTitle:name];
}

- (void)setAppController:(id)anObject
{
  [appController autorelease];
  appController = [anObject retain];
}

- (void)setFileManager:(id)anObject
{
  [fileManager autorelease];
  fileManager = [anObject retain];
}

- (void)setProjectManager:(id)anObject
{
  [projectManager autorelease];
  projectManager = [anObject retain];
}

//============================================================================
//==== Menu stuff
//============================================================================

- (void)openProject:(id)sender
{
    NSString 	*projectPath;
    NSOpenPanel	*openPanel;
    int		retval;

    openPanel = [NSOpenPanel openPanel];
    [openPanel setAllowsMultipleSelection:NO];
    [openPanel setCanChooseDirectories:NO];
    [openPanel setCanChooseFiles:YES];

    retval = [openPanel runModalForDirectory:[[NSUserDefaults standardUserDefaults] objectForKey:@"LastOpenDirectory"] file:nil types:[NSArray arrayWithObjects:@"project",nil]];

    if (retval == NSOKButton) {
        BOOL isDir;

        [[NSUserDefaults standardUserDefaults] setObject:[openPanel directory] forKey:@"LastOpenDirectory"];
        projectPath = [[openPanel filenames] objectAtIndex:0];

        if ([[NSFileManager defaultManager] fileExistsAtPath:projectPath isDirectory:&isDir] && !isDir) {
            if (![projectManager openProjectAt:projectPath]) {
                NSRunAlertPanel(@"Attention!",@"Couldn't open %@!",@"OK",nil,nil,[projectPath stringByDeletingLastPathComponent]);
            }
        }
    }
}

- (void)newProject:(id)sender
{
    NSSavePanel *sp;
    int 	runResult;

    sp = [NSSavePanel savePanel];

    [sp setTitle:@"Create new project..."];
    [sp setAccessoryView:projectTypeAccessaryView];

    runResult = [sp runModalForDirectory:NSHomeDirectory() file:@""];
    if (runResult == NSOKButton) {
        NSString *projectType = [projectTypePopup titleOfSelectedItem];
        NSString *className = [[appController projectTypes] objectForKey:projectType];

        if (![projectManager createProjectOfType:className path:[sp filename]]) {
            NSRunAlertPanel(@"Attention!",@"Failed to create %@!",@"OK",nil,nil,[sp filename]);
        }
    }
}

- (void)saveProject:(id)sender
{
    [projectManager saveProject];
}

- (void)saveProjectAs:(id)sender
{
    NSString *proj;

// Show save panel

    [projectManager saveProjectAs:proj];
}

- (void)showLoadedProjects:(id)sender
{
    [projectManager showLoadedProjects];
}

- (void)saveFiles:(id)sender
{
    [projectManager saveFiles];
}

- (void)revertToSaved:(id)sender
{
    [projectManager revertToSaved];
}

- (void)newSubproject:(id)sender
{
    [projectManager newSubproject];
}

- (void)addSubproject:(id)sender
{
    NSString *proj;

// Show open panel

    [projectManager addSubprojectAt:proj];
}

- (void)removeSubproject:(id)sender
{
    [projectManager removeSubproject];
}

- (void)closeProject:(id)sender
{
    [projectManager closeProject];
}

- (void)newFile:(id)sender
{
    [fileManager showNewFileWindow];
}

- (void)openFile:(id)sender
{
    NSString 	*filePath;
    NSOpenPanel	*openPanel;
    int		retval;

    openPanel = [NSOpenPanel openPanel];
    [openPanel setAllowsMultipleSelection:NO];
    [openPanel setCanChooseDirectories:NO];
    [openPanel setCanChooseFiles:YES];

    retval = [openPanel runModalForDirectory:[[NSUserDefaults standardUserDefaults] objectForKey:@"LastOpenDirectory"] file:nil types:nil];

    if (retval == NSOKButton) {
        BOOL isDir;

        [[NSUserDefaults standardUserDefaults] setObject:[openPanel directory] forKey:@"LastOpenDirectory"];
        filePath = [[openPanel filenames] objectAtIndex:0];

        if ([[NSFileManager defaultManager] fileExistsAtPath:filePath isDirectory:&isDir] && !isDir) {
            if (![projectManager openFile:filePath]) {
                NSRunAlertPanel(@"Attention!",@"Couldn't open %@!",@"OK",nil,nil,filePath);
            }
        }
    }
}

- (void)addFile:(id)sender
{
    [fileManager showAddFileWindow];
}

- (void)saveFile:(id)sender
{
    [projectManager saveFile];
}

- (void)saveFileAs:(id)sender
{
    NSString *proj;

// Show open panel

    [projectManager saveFileAs:proj];
}

- (void)revertFile:(id)sender
{
    [projectManager revertFile];
}

- (void)renameFile:(id)sender
{
    NSString *proj;

// Show open panel

    [projectManager renameFileTo:proj];
}

- (void)removeFile:(id)sender
{
  NSString *file = nil;
  PCProject *proj = [projectManager activeProject];
  
  if ((file = [[proj browserController] nameOfSelectedFile])) {
    int ret;
    
    ret = NSRunAlertPanel(@"Remove File!",@"Really remove %@ in project %@?",@"Cancel",@"...from Project only",@"...from Project and Disk",file,[proj projectName]);
    
    if (ret == NSAlertAlternateReturn || ret == NSAlertOtherReturn) {
      BOOL flag = (ret == NSAlertOtherReturn) ? YES : NO;
      
      [projectManager removeFilePermanently:flag];
    }
  }    
}

//============================================================================
//==== Delegate stuff
//============================================================================

- (BOOL)validateMenuItem:(id <NSMenuItem>)menuItem
{
    if (![[projectManager loadedProjects] count]) {
        if ([menuItem title] == @"New in Project") return NO;
        if ([menuItem title] == @"Add File") return NO;
        if ([menuItem title] == @"Remove File") return NO;
    }

    return YES;
}

@end
