/*
   GNUstep ProjectCenter - http://www.gnustep.org

   Copyright (C) 2001 Free Software Foundation

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

#include "PCMenuController.h"

#include <ProjectCenter/ProjectCenter.h>
#include "PCAppController.h"

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
  appController = anObject;
  RETAIN(appController);
}

- (void)setFileManager:(id)anObject
{
  [fileManager autorelease];
  fileManager = anObject;
  RETAIN(fileManager);
}

- (void)setProjectManager:(id)anObject
{
  [projectManager autorelease];
  projectManager = anObject;
  RETAIN(projectManager);
}

//============================================================================
//==== Menu stuff
//============================================================================

// Info
- (void)showPrefWindow:(id)sender
{
  [[[NSApp delegate] prefController] showPrefWindow:sender];
}

- (void)showInfoPanel:(id)sender
{
  [[[NSApp delegate] infoController] showInfoWindow:sender];
}

- (void)showEditorPanel:(id)sender
{
  [[projectManager activeProject] showEditorView:self];
}

// Project
- (void)projectOpen:(id)sender
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

- (void)projectNew:(id)sender
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

- (void)projectSave:(id)sender
{
  [projectManager saveProject];
}

- (void)projectSaveAs:(id)sender
{
  NSString    *proj = nil;

  // Show save panel
  NSRunAlertPanel(@"Attention!",
		  @"This feature is not yet implemented!", 
		  @"OK",nil,nil);

  [projectManager saveProjectAs:proj];
}

- (void)projectAddFiles:(id)sender
{
  [fileManager showAddFileWindow];
}

- (void)projectSaveFiles:(id)sender
{
  [projectManager saveAllFiles];
}

- (void)projectRemoveFiles:(id)sender
{
  NSString  *fileName = nil;
  PCProject *proj = [projectManager activeProject];
  NSArray   *files = [[proj browserController] selectedFiles];

  if ((fileName = [[proj browserController] nameOfSelectedFile]))
  {
      int ret;

      ret = NSRunAlertPanel(@"Remove File!",
			    @"Really remove %@ in project %@?",
			    @"Cancel",
			    @"...from Project only",
			    @"...from Project and Disk",
			    files, [proj projectName]);

      if (ret == NSAlertAlternateReturn || ret == NSAlertOtherReturn) 
      {
	  BOOL flag = (ret == NSAlertOtherReturn) ? YES : NO;

	  [projectManager removeFilesPermanently:flag];
       }
  }
}

- (void)projectRevertToSaved:(id)sender
{
  [projectManager revertToSaved];
}

- (void)projectClose:(id)sender
{
  [projectManager closeProject];
}

// Subproject
- (void)subprojectNew:(id)sender
{
  [projectManager newSubproject];
}

- (void)subprojectAdd:(id)sender
{
  NSString *proj = nil;

  // Show open panel

  [projectManager addSubprojectAt:proj];
}

- (void)subprojectRemove:(id)sender
{
  [projectManager removeSubproject];
}

// File
- (void)fileOpen:(id)sender
{
  NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
  NSString 	 *filePath;
  NSOpenPanel	 *openPanel;
  int		 retval;

  openPanel = [NSOpenPanel openPanel];
  [openPanel setAllowsMultipleSelection:NO];
  [openPanel setCanChooseDirectories:NO];
  [openPanel setCanChooseFiles:YES];

  retval = [openPanel 
    runModalForDirectory:[ud objectForKey:@"LastOpenDirectory"]
                    file:nil
                   types:nil];

  if (retval == NSOKButton)
    {
      BOOL isDir;
      NSFileManager *fm = [NSFileManager defaultManager];

      [ud setObject:[openPanel directory] forKey:@"LastOpenDirectory"];

      filePath = [[openPanel filenames] objectAtIndex:0];

      if (![fm fileExistsAtPath:filePath isDirectory:&isDir] && !isDir)
      {
	  NSRunAlertPanel(@"Attention!",
			  @"Couldn't open %@!",
			  @"OK",nil,nil,filePath);
      }
      else
      {
	  [PCEditorController openFileInEditor:filePath];
      }
  }
}

- (void)fileNew:(id)sender
{
  [fileManager showNewFileWindow];
}

- (void)fileSave:(id)sender
{
  [projectManager saveFile];
}

// Not finished
- (void)fileSaveAs:(id)sender
{
  NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
  NSSavePanel	 *savePanel = [NSSavePanel savePanel];;
  NSString       *oldFilePath = nil;
  NSString 	 *newFilePath = nil;
  NSString       *directory = nil;
  int		 retval = NSOKButton;

  oldFilePath = 
    [[[[projectManager activeProject] editorController] activeEditor] path];

  [savePanel setTitle: @"Save As..."];
  while (![directory isEqualToString: [projectManager projectPath]] 
	 && retval != NSCancelButton)
    {
      retval = [savePanel 
	runModalForDirectory:[projectManager projectPath]
	                file:[projectManager selectedFileName]];
      directory = [savePanel directory];
    }

  if (retval == NSOKButton)
    {
      [ud setObject:directory forKey:@"LastOpenDirectory"];

      newFilePath = [savePanel filename];
		  
      if (![projectManager saveFileAs:newFilePath]) 
	{
	  NSRunAlertPanel(@"Attention!",
			  @"Couldn't save file as\n%@!",
			  @"OK",nil,nil,newFilePath);
	}
      else
	{
	  PCProject *project = [projectManager activeProject];
	  NSString  *category = [[[project rootCategories] allKeysForObject:PCNonProject] objectAtIndex:0];

	  [projectManager closeFile];
	  [project addFile:newFilePath forKey:PCNonProject];
	  [project browserDidClickFile:[newFilePath lastPathComponent]
	                      category:category];
	}
    }
}

- (void)fileSaveTo:(id)sender
{
  NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
  NSString 	 *filePath = [projectManager selectedFileName];
  NSSavePanel	 *savePanel = [NSSavePanel savePanel];;
  int		 retval;

  [savePanel setTitle: @"Save To..."];
  retval = [savePanel runModalForDirectory:[projectManager projectPath]
                                      file:filePath];

  if (retval == NSOKButton)
    {
      [ud setObject:[savePanel directory] forKey:@"LastOpenDirectory"];

      filePath = [savePanel filename];
		  
      if (![projectManager saveFileTo:filePath]) 
	{
	  NSRunAlertPanel(@"Attention!",
			  @"Couldn't save file to\n%@!",
			  @"OK",nil,nil,filePath);
	}
    }
}

- (void)fileRevertToSaved:(id)sender
{
  [projectManager revertFileToSaved];
}

- (void)fileClose:(id)sender
{
  [projectManager closeFile];
}

- (void)fileOpenQuickly:(id)sender
{
  NSRunAlertPanel(@"PCMenuController: Sorry!",
		  @"This feature is not finished yet",
		  @"OK",nil,nil);
}

- (void)fileRename:(id)sender
{
/*  NSString *proj = nil;

  // Show Inspector panel with "File Attributes" section

  [projectManager renameFileTo:proj];*/

  NSRunAlertPanel(@"PCMenuController: Sorry!",
		  @"This feature is not finished yet",
		  @"OK",nil,nil);
}

- (void)fileNewUntitled:(id)sender
{
  NSRunAlertPanel(@"PCMenuController: Sorry!",
		  @"This feature is not finished yet",
		  @"OK",nil,nil);
}

// Edit
- (void)findShowPanel:(id)sender
{
  [[PCTextFinder sharedFinder] showFindPanel:self];
}

- (void)findNext:(id)sender
{
  [[PCTextFinder sharedFinder] findNext:self];
}

- (void)findPrevious:(id)sender
{
  [[PCTextFinder sharedFinder] findPrevious:self];
}

// Tools
- (void)showInspector:(id)sender
{
  [projectManager showInspectorForProject:[projectManager activeProject]];
}

- (void)showRunPanel:(id)sender
{
  [[projectManager activeProject] showRunView:self];
}

- (void)showBuildPanel:(id)sender
{
  [[projectManager activeProject] showBuildView:self];
}

- (void)runTarget:(id)sender
{
  [[projectManager activeProject] runSelectedTarget:self];
}

//============================================================================
//==== Delegate stuff
//============================================================================

- (BOOL)validateMenuItem:(id <NSMenuItem>)menuItem
{
  NSString    *menuTitle = [[menuItem menu] title];
  PCProject   *aProject = [projectManager activeProject];
  NSResponder *firstResponder = [[NSApp keyWindow] firstResponder];

  if ([[projectManager loadedProjects] count] == 0) 
    {
      // Project related menu items
      if ([menuTitle isEqualToString: @"Project"])
	{
	  if ([[menuItem title] isEqualToString:@"Save"]) return NO;
	  if ([[menuItem title] isEqualToString:@"Save As..."]) return NO;
	  if ([[menuItem title] isEqualToString:@"Add Files..."]) return NO;
	  if ([[menuItem title] isEqualToString:@"Save Files..."]) return NO;
	  if ([[menuItem title] isEqualToString:@"Remove Files..."]) return NO;
	  if ([[menuItem title] isEqualToString:@"Close"]) return NO;
	}

      // File related menu items
      if ([menuTitle isEqualToString: @"File"])
	{
	  if ([[menuItem title] isEqualToString:@"New in Project"]) return NO;
	  if ([[menuItem title] isEqualToString:@"Save"]) return NO;
	  if ([[menuItem title] isEqualToString:@"Save As..."]) return NO;
	  if ([[menuItem title] isEqualToString:@"Save To..."]) return NO;
	  if ([[menuItem title] isEqualToString:@"Revert to Saved"]) return NO;
	  if ([[menuItem title] isEqualToString:@"Close"]) return NO;
	  if ([[menuItem title] isEqualToString:@"Open Quickly..."]) return NO;
	  if ([[menuItem title] isEqualToString:@"Rename"]) return NO;
	  if ([[menuItem title] isEqualToString:@"New Untitled"]) return NO;
	}

      // Tools menu items
      if ([menuTitle isEqualToString: @"Tools"])
	{
	  if ([[menuItem title] isEqualToString:@"Inspector..."]) return NO;
	  if ([[menuItem title] isEqualToString:@"Hide Tool Bar"]) return NO;
	}
      if ([menuTitle isEqualToString: @"Project Build"])
	{
	  if ([[menuItem title] isEqualToString:@"Show Panel..."]) return NO;
	  if ([[menuItem title] isEqualToString:@"Build"]) return NO;
	  if ([[menuItem title] isEqualToString:@"Stop Build"]) return NO;
	  if ([[menuItem title] isEqualToString:@"Clean"]) return NO;
	  if ([[menuItem title] isEqualToString:@"Next Error"]) return NO;
	  if ([[menuItem title] isEqualToString:@"Previous Error"]) return NO;
	}
      if ([menuTitle isEqualToString: @"Project Find"])
	{
	  if ([[menuItem title] isEqualToString:@"Show Panel..."]) return NO;
	  if ([[menuItem title] isEqualToString:@"Find Preferences"]) return NO;
	  if ([[menuItem title] isEqualToString:@"Find Definitions"]) return NO;
	  if ([[menuItem title] isEqualToString:@"Find Text"]) return NO;
	  if ([[menuItem title] isEqualToString:@"Find Regular Expr"]) return NO;
	  if ([[menuItem title] isEqualToString:@"Next match"]) return NO;
	  if ([[menuItem title] isEqualToString:@"Previous match"]) return NO;
	}
      if ([menuTitle isEqualToString: @"Loaded Files"])
	{
	  if ([[menuItem title] isEqualToString:@"Show Panel..."]) return NO;
	  if ([[menuItem title] isEqualToString:@"Sort by Time Viewed"]) return NO;
	  if ([[menuItem title] isEqualToString:@"Sort by Name"]) return NO;
	  if ([[menuItem title] isEqualToString:@"Next File"]) return NO;
	  if ([[menuItem title] isEqualToString:@"Previous File"]) return NO;
	}
      if ([menuTitle isEqualToString: @"Launcher"])
	{
	  if ([[menuItem title] isEqualToString:@"Show Panel..."]) return NO;
	  if ([[menuItem title] isEqualToString:@"Run"]) return NO;
	  if ([[menuItem title] isEqualToString:@"Debug"]) return NO;
	}
      if ([menuTitle isEqualToString: @"Indexer"])
	{
	  if ([[menuItem title] isEqualToString:@"Show Panel..."]) return NO;
	  if ([[menuItem title] isEqualToString:@"Purge Indices"]) return NO;
	  if ([[menuItem title] isEqualToString:@"Index Subproject"]) return NO;
	  if ([[menuItem title] isEqualToString:@"Index File"]) return NO;
	}
      return YES;
    }

  // Project related menu items
  if ([menuTitle isEqualToString: @"Project"] 
      && [aProject selectedRootCategory] == nil)
    {
      if ([[menuItem title] isEqualToString:@"Add Files..."]) return NO;
      if ([[menuItem title] isEqualToString:@"Remove Files..."]) return NO;
    }

  // File related menu items
  if (([menuTitle isEqualToString: @"File"]))
    {
      if (![[firstResponder className] isEqualToString: @"PCEditorView"])
	{
	  if ([[menuItem title] isEqualToString:@"Save"]) return NO;
	  if ([[menuItem title] isEqualToString:@"Save As..."]) return NO;
	  if ([[menuItem title] isEqualToString:@"Save To..."]) return NO;
	  if ([[menuItem title] isEqualToString:@"Revert to Saved"]) return NO;
	  if ([[menuItem title] isEqualToString:@"Close"]) return NO;
	  if ([[menuItem title] isEqualToString:@"Rename"]) return NO;
	}
    }

  // Find menu items
  if (editorIsKey == NO && [menuTitle isEqualToString: @"Find"])
    {
      if (![[[PCTextFinder sharedFinder] findPanel] isVisible])
	{
	  if ([[menuItem title] isEqualToString:@"Find Next"]) return NO;
	  if ([[menuItem title] isEqualToString:@"Find Previous"]) return NO;
	}
      if ([[menuItem title] isEqualToString:@"Enter Selection"]) return NO;
      if ([[menuItem title] isEqualToString:@"Jump to Selection"]) return NO;
      if ([[menuItem title] isEqualToString:@"Line Number..."]) return NO;
      if ([[menuItem title] isEqualToString:@"Man Page"]) return NO;
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

