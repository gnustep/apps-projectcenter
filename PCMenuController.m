/*
   GNUstep ProjectCenter - http://www.gnustep.org

   Copyright (C) 2001 Free Software Foundation

   Author: Philippe C.D. Robert <phr@3dkit.org>

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

#include "PCMenuController.h"

#include <ProjectCenter/ProjectCenter.h>
#include "PCAppController.h"

#if defined(GNUSTEP)
#include <AppKit/IMLoading.h>
#endif

@implementation PCMenuController

- (id)init
{
    if ((self = [super init])) 
    {
      NSRect fr = NSMakeRect(20,30,160,20);

      [[NSNotificationCenter defaultCenter] addObserver:self 
                                         selector:@selector(editorDidBecomeKey:)
					 name:PCEditorDidBecomeKeyNotification 
					 object:nil];

      [[NSNotificationCenter defaultCenter] addObserver:self 
                                         selector:@selector(editorDidResignKey:)
					 name:PCEditorDidResignKeyNotification 
					 object:nil];

      editorIsKey = NO;
    
      projectTypeAccessaryView = [[NSBox alloc] init];
      projectTypePopup = [[NSPopUpButton alloc] initWithFrame:fr pullsDown:NO];
      [projectTypePopup setAutoenablesItems: NO];
      [projectTypePopup addItemWithTitle:@"No type available!"];
      
      [projectTypeAccessaryView setTitle:@"Project Types"];
      [projectTypeAccessaryView setTitlePosition:NSAtTop];
      [projectTypeAccessaryView setBorderType:NSGrooveBorder];
      [projectTypeAccessaryView addSubview:projectTypePopup];
      [projectTypeAccessaryView sizeToFit];
      [projectTypeAccessaryView setAutoresizingMask:
	NSViewMinXMargin | NSViewMaxXMargin];

      RELEASE(projectTypePopup);
    }
    return self;
}

- (void)dealloc
{
  [[NSNotificationCenter defaultCenter] removeObserver:self];

  RELEASE(projectTypeAccessaryView);

  [super dealloc];
}

- (void)addProjectTypeNamed:(NSString *)name
{
    static BOOL _firstItem = YES;

    if (_firstItem) 
    {
        _firstItem = NO;
        [projectTypePopup removeItemWithTitle:@"No type available!"];
    }

    [projectTypePopup addItemWithTitle:name];
    [projectTypePopup sizeToFit];
    [projectTypeAccessaryView sizeToFit];
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
    NSString 	*projPath;
    NSOpenPanel	*openPanel;
    int		retval;

    openPanel = [NSOpenPanel openPanel];
    [openPanel setAllowsMultipleSelection:NO];
    [openPanel setCanChooseDirectories:NO];
    [openPanel setCanChooseFiles:YES];

    retval = [openPanel runModalForDirectory:[[NSUserDefaults standardUserDefaults] objectForKey:@"LastOpenDirectory"] file:nil types:[NSArray arrayWithObjects:@"project",@"pcproj",nil]];

    if (retval == NSOKButton) 
    {
        BOOL isDir;

        [[NSUserDefaults standardUserDefaults] setObject:[openPanel directory] 
	                                          forKey:@"LastOpenDirectory"];

        projPath = [[openPanel filenames] objectAtIndex:0];

        if ([[NSFileManager defaultManager] fileExistsAtPath:projPath 
	                                         isDirectory:&isDir] && !isDir)
        {
            if (![projectManager openProjectAt:projPath]) 
	    {
                NSRunAlertPanel(@"Attention!",
		                @"Couldn't open %@!",
				@"OK",nil,nil,
				[projPath stringByDeletingLastPathComponent]);
            }
        }
    }
}

- (void)newProject:(id)sender
{
    NSSavePanel *sp;
    int 	 runResult;
    NSString    *dir = nil;

    sp = [NSSavePanel savePanel];

    [sp setTitle:@"Create new project..."];
    [sp setAccessoryView:nil];
    [sp setAccessoryView:projectTypeAccessaryView];

    dir = [[NSUserDefaults standardUserDefaults] objectForKey:@"LastNewDirectory"];
    if( !dir )
    {
        dir = NSHomeDirectory();
    }

    runResult = [sp runModalForDirectory:dir file:@""];
    if (runResult == NSOKButton) 
    {
        NSString *projectType = [projectTypePopup titleOfSelectedItem];
        NSString *className = [[appController projectTypes] objectForKey:projectType];

        [[NSUserDefaults standardUserDefaults] setObject:[sp directory] 
	                                          forKey:@"LastNewDirectory"];

        if (![projectManager createProjectOfType:className path:[sp filename]])
	{
            NSRunAlertPanel(@"Attention!",
	                    @"Failed to create %@!",
			    @"OK",nil,nil,[sp filename]);
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

        if ([[NSFileManager defaultManager] fileExistsAtPath:filePath isDirectory:&isDir] && !isDir) 
	{
            if (![projectManager openFile:filePath]) 
	    {
                NSRunAlertPanel(@"Attention!",
		                @"Couldn't open %@!",
				@"OK",nil,nil,filePath);
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
    
    if (ret == NSAlertAlternateReturn || ret == NSAlertOtherReturn) 
    {
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
    if ([[projectManager loadedProjects] count] == 0) 
    {
        // File related menu items
	if ([[menuItem title] isEqualToString:@"New in Project"]) return NO;
	if ([[menuItem title] isEqualToString:@"Add File"]) return NO;
	if ([[menuItem title] isEqualToString:@"Remove File"]) return NO;
	if ([[menuItem title] isEqualToString:@"Save File"]) return NO;
	if ([[menuItem title] isEqualToString:@"Revert"]) return NO;
	if ([[menuItem title] isEqualToString:@"Rename"]) return NO;

        // Project related menu items
        if ([[menuItem title] isEqualToString:@"Close"]) return NO;
        if ([[menuItem title] isEqualToString:@"Save..."]) return NO;
        if ([[menuItem title] isEqualToString:@"Save As..."]) return NO;

	// Embedded Project Views
        if ([[menuItem title] isEqualToString:@"Inspector Panel"]) return NO;
        if ([[menuItem title] isEqualToString:@"Launch Panel"]) return NO;
        if ([[menuItem title] isEqualToString:@"Build Panel"]) return NO;
        if ([[menuItem title] isEqualToString:@"Editor Panel"]) return NO;

        if ([[menuItem title] isEqualToString:@"Run..."]) return NO;
    }

    // File related menu items
    if( editorIsKey == NO )
    {
	if ([[menuItem title] isEqualToString:@"Save File"]) return NO;
	if ([[menuItem title] isEqualToString:@"Revert"]) return NO;
	if ([[menuItem title] isEqualToString:@"Rename"]) return NO;
    }

    if ([[menuItem title] isEqualToString:@"Find Next"]) 
    {
        if( ![[[PCTextFinder sharedFinder] findPanel] isVisible] ) return NO;
    }

    if ([[menuItem title] isEqualToString:@"Find Previous"]) 
    {
        if( ![[[PCTextFinder sharedFinder] findPanel] isVisible] ) return NO;
    }

    return YES;
}

- (void)editorDidResignKey:(NSNotification *)aNotification
{
    editorIsKey = NO;
}
- (void)editorDidBecomeKey:(NSNotification *)aNotification
{
    editorIsKey = YES;
}

@end