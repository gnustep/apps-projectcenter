/*
   GNUstep ProjectCenter - http://www.gnustep.org/experience/ProjectCenter.html

   Copyright (C) 2001 Free Software Foundation

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
#include <ProjectCenter/PCPrefController.h>
#include <ProjectCenter/PCLogController.h>
#include <ProjectCenter/ProjectCenter.h>

#include <Protocols/CodeEditor.h>

#include "PCAppController.h"
#include "PCMenuController.h"
#include "PCInfoController.h"

@implementation PCMenuController

- (id)init
{
  if ((self = [super init])) 
    {
      [[NSNotificationCenter defaultCenter]
	addObserver:self 
	   selector:@selector(editorDidBecomeActive:)
	       name:PCEditorDidBecomeActiveNotification 
	     object:nil];

      [[NSNotificationCenter defaultCenter]
	addObserver:self 
	   selector:@selector(editorDidResignActive:)
	       name:PCEditorDidResignActiveNotification 
	     object:nil];

      editorIsActive = NO;
    }

  return self;
}

- (void)dealloc
{
#ifdef DEVELOPMENT
  NSLog(@"PCMenuController: dealloc");
#endif
  [[NSNotificationCenter defaultCenter] removeObserver:self];

  [super dealloc];
}

- (void)setAppController:(id)anObject
{
  appController = anObject;
}

- (void)setProjectManager:(id)anObject
{
  projectManager = anObject;
}

//============================================================================
//==== Menu stuff
//============================================================================

// Info
- (void)showPrefWindow:(id)sender
{
  [[appController prefController] showPanel:sender];
}

- (void)showInfoPanel:(id)sender
{
  [[[NSApp delegate] infoController] showInfoWindow:sender];
}

- (void)showEditorPanel:(id)sender
{
  [[[projectManager rootActiveProject] projectWindow] showProjectEditor:self];
}

- (void)showLogPanel:(id)sender
{
  [[appController logController] showPanel];
}

// Project
- (void)projectOpen:(id)sender
{
  [projectManager openProject];
}

- (void)projectNew:(id)sender
{
  [projectManager newProject];
}

- (void)projectSave:(id)sender
{
  [projectManager saveProject];
}

- (void)projectAddFiles:(id)sender
{
  [projectManager addProjectFiles];
}

- (void)projectSaveFiles:(id)sender
{
  [projectManager saveProjectFiles];
}

- (void)projectRemoveFiles:(id)sender
{
  [projectManager removeProjectFiles];
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
  [projectManager addSubproject];
}

// File
- (void)fileOpen:(id)sender
{
  [projectManager openFile];
}

- (void)fileNew:(id)sender
{
  [projectManager newFile];
}

- (void)fileSave:(id)sender
{
  [projectManager saveFile];
}

- (void)fileSaveAs:(id)sender
{
  NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
  NSSavePanel	 *savePanel = [NSSavePanel savePanel];
  NSString       *oldFilePath = nil;
  NSString 	 *newFilePath = nil;
  NSString       *directory = nil;
  int		 retval = NSOKButton;

  oldFilePath = 
    [[[[projectManager rootActiveProject] projectEditor] activeEditor] path];

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
	  NSString  *categoryPath =  nil;

	  categoryPath = [NSString stringWithString:@"/"];
	  categoryPath = [categoryPath stringByAppendingPathComponent:
	    [[project rootEntries] objectForKey:PCNonProject]];

	  [projectManager closeFile];
	  [project addFiles:[NSArray arrayWithObject:newFilePath]
	             forKey:PCNonProject
		     notify:YES];
	  [[project projectEditor] openEditorForFile:newFilePath
					categoryPath:categoryPath
					    editable:YES
					    windowed:NO];
	}
    }
}


- (void)fileSaveTo:(id)sender
{
  [projectManager saveFileTo];
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
  // Show Inspector panel with "File Attributes" section
  [projectManager renameFile];

/*  NSRunAlertPanel(@"PCMenuController: Sorry!",
		  @"This feature is not finished yet",
		  @"OK",nil,nil);*/
}

- (void)fileNewUntitled:(id)sender
{
  NSRunAlertPanel(@"PCMenuController: Sorry!",
		  @"This feature is not finished yet",
		  @"OK",nil,nil);
}

// Edit. PCProjectEditor have to provide this menu and functionality
/*- (void)findShowPanel:(id)sender
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
}*/

// Tools

- (void)toggleToolbar:(id)sender
{
  [[[projectManager rootActiveProject] projectWindow] toggleToolbar];

  if ([[sender title] isEqualToString:@"Hide Tool Bar"])
    {
      [sender setTitle:@"Show Tool Bar"];
    }
  else
    {
      [sender setTitle:@"Hide Tool Bar"];
    }
}

- (void)showInspector:(id)sender
{
  [projectManager showProjectInspector:self];
}

// Build Panel
- (void)showBuildPanel:(id)sender
{
  [[[projectManager rootActiveProject] projectWindow] showProjectBuild:self];
}

- (void)executeBuild:(id)sender
{
  [self showBuildPanel:self];
  [[[projectManager rootActiveProject] projectBuilder] performStartBuild];
}

- (void)stopBuild:(id)sender
{
  [[[projectManager rootActiveProject] projectBuilder] performStopBuild];
}

- (void)startClean:(id)sender
{
  [self showBuildPanel:self];
  [[[projectManager rootActiveProject] projectBuilder] performStartClean];
}

// Loaded Files
- (void)showLoadedFilesPanel:(id)sender
{
  [projectManager showProjectLoadedFiles:self];
}

- (void)loadedFilesSortByTime:(id)sender
{
  [[[projectManager rootActiveProject] projectLoadedFiles] setSortByTime];
}

- (void)loadedFilesSortByName:(id)sender
{
  [[[projectManager rootActiveProject] projectLoadedFiles] setSortByName];
}

- (void)loadedFilesNextFile:(id)sender
{
  [[[projectManager rootActiveProject] projectLoadedFiles] selectNextFile];
}

- (void)loadedFilesPreviousFile:(id)sender
{
  [[[projectManager rootActiveProject] projectLoadedFiles] selectPreviousFile];
}

// Launch Panel
- (void)showLaunchPanel:(id)sender
{
  [[[projectManager rootActiveProject] projectWindow] showProjectLaunch:self];
}

- (void)runTarget:(id)sender
{
  [self showLaunchPanel:self];
  [[[projectManager rootActiveProject] projectLauncher] performRun];
}

- (void)debugTarget:(id)sender
{
  [self showLaunchPanel:self];
  [[[projectManager rootActiveProject] projectLauncher] performDebug];
}

//============================================================================
//==== Delegate stuff
//============================================================================

- (BOOL)validateMenuItem:(id <NSMenuItem>)menuItem
{
  NSString         *menuTitle = [[menuItem menu] title];
  PCProject        *aProject = [projectManager activeProject];
  PCProjectEditor  *projectEditor = [aProject projectEditor];
  PCProjectBrowser *projectBrowser = [aProject projectBrowser];

  if ([[projectManager loadedProjects] count] == 0) 
    {
      // Project related menu items
      if ([menuTitle isEqualToString: @"Project"])
	{
	  if ([[menuItem title] isEqualToString:@"Save"]) return NO;
	  if ([[menuItem title] isEqualToString:@"Add Files..."]) return NO;
	  if ([[menuItem title] isEqualToString:@"Save Files..."]) return NO;
	  if ([[menuItem title] isEqualToString:@"Remove Files..."]) return NO;
	  if ([[menuItem title] isEqualToString:@"New Subproject..."]) 
	    return NO;
	  if ([[menuItem title] isEqualToString:@"Add Subproject..."]) 
	    return NO;
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
	  if ([[menuItem title] isEqualToString:@"Show Tool Bar"]) return NO;
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
      && [projectBrowser nameOfSelectedFile] == nil
      && [projectBrowser selectedFiles] == nil)
    {
      if ([[menuItem title] isEqualToString:@"Remove Files..."]) return NO;
    }
  if ([menuTitle isEqualToString: @"Project"] 
      && [[projectEditor allEditors] count] == 0)
    {
      if ([[menuItem title] isEqualToString:@"Save Files..."]) return NO;
    }
  if ([menuTitle isEqualToString: @"Project"] 
      && [projectBrowser nameOfSelectedCategory] == nil)
    {
      if ([[menuItem title] isEqualToString:@"Add Subproject..."]) return NO;
      if ([[menuItem title] isEqualToString:@"Add Files..."]) return NO;
    }
  if ([menuTitle isEqualToString: @"Project"] 
      && [[projectBrowser nameOfSelectedCategory] 
         isEqualToString:@"Subprojects"])
    {
      if ([[menuItem title] isEqualToString:@"Add Files..."]) return NO;
    }
  if ([menuTitle isEqualToString: @"Project"] 
      && ![[projectBrowser nameOfSelectedRootCategory] isEqualToString:@"Subprojects"])
    {
      if ([[menuItem title] isEqualToString:@"Add Subproject..."]) return NO;
    }

  // File related menu items
  if (([menuTitle isEqualToString: @"File"]))
    {
      if (!editorIsActive)
	{
	  if ([[menuItem title] isEqualToString:@"Save"]) return NO;
	  if ([[menuItem title] isEqualToString:@"Save As..."]) return NO;
	  if ([[menuItem title] isEqualToString:@"Save To..."]) return NO;
	  if ([[menuItem title] isEqualToString:@"Revert to Saved"]) return NO;
	  if ([[menuItem title] isEqualToString:@"Close"]) return NO;
	}
    }
  if ([projectBrowser nameOfSelectedFile] == nil)
    {
      if ([[menuItem title] isEqualToString:@"Rename"]) return NO;
    }

  // Find menu items
/*  if (editorIsActive == NO && [menuTitle isEqualToString: @"Find"])
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
    }*/

  // Toolbar
  if ([[menuItem title] isEqualToString:@"Hide Tool Bar"]
      && ![[[projectManager activeProject] projectWindow] isToolbarVisible])
    {
      [menuItem setTitle:@"Show Tool Bar"];
    }
  if ([[menuItem title] isEqualToString:@"Show Tool Bar"]
      && [[[projectManager activeProject] projectWindow] isToolbarVisible])
    {
      [menuItem setTitle:@"Hide Tool Bar"];
    }
    
  // Project Build related
  if (([menuTitle isEqualToString: @"Project Build"]))
    {
      if ([[[projectManager activeProject] projectBuilder] isBuilding]
	  || [[[projectManager activeProject] projectBuilder] isCleaning])
	{
	  if ([[menuItem title] isEqualToString:@"Build"]) return NO;
	  if ([[menuItem title] isEqualToString:@"Clean"]) return NO;
	  if ([[menuItem title] isEqualToString:@"Next error"]) return NO;
	  if ([[menuItem title] isEqualToString:@"Previous error"]) return NO;
	}
      else
	{
	  if ([[menuItem title] isEqualToString:@"Stop Build"]) return NO;
	}
    }
    
  // Project Launcher related
  if (([menuTitle isEqualToString: @"Launcher"]))
    {
      if ([[[projectManager activeProject] projectLauncher] isRunning]
	  || [[[projectManager activeProject] projectLauncher] isDebugging])
	{
	  if ([[menuItem title] isEqualToString:@"Run"]) return NO;
	  if ([[menuItem title] isEqualToString:@"Debug"]) return NO;
	}
    }
    
  // Loaded Files related
  if (([menuTitle isEqualToString: @"Loaded Files"]))
    {
      if ([[[aProject projectLoadedFiles] editedFilesRep] count] <= 0)
	{
	  if ([[menuItem title] isEqualToString:@"Sort by Time Viewed"])
	    return NO;
	  if ([[menuItem title] isEqualToString:@"Sort by Name"]) return NO;
	  if ([[menuItem title] isEqualToString:@"Next File"]) return NO;
	  if ([[menuItem title] isEqualToString:@"Previous File"]) return NO;
	}
    }

  return YES;
}

- (void)editorDidResignActive:(NSNotification *)aNotif
{
  editorIsActive = NO;
}

- (void)editorDidBecomeActive:(NSNotification *)aNotif
{
  editorIsActive = YES;
}

@end

