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

#include "PCDefines.h"

#include "PCFileManager.h"
#include "PCFileManager+UInterface.h"
#include "PCProjectManager.h"
#include "PCHistoryPanel.h"
#include "PCBuildPanel.h"
#include "PCLaunchPanel.h"

#include "PCProject.h"
#include "PCProjectWindow.h"
#include "PCProjectBrowser.h"
#include "PCProjectInspector.h"
#include "PCProjectEditor.h"
#include "PCEditor.h"
#include "ProjectComponent.h"
#include "PCProject+ComponentHandling.h"
#include "PCServer.h"

#include "ProjectType.h"
#include "ProjectBuilder.h"

#define SavePeriodDCN @"SavePeriodDidChangeNotification"

NSString *ActiveProjectDidChangeNotification = @"ActiveProjectDidChange";

@implementation PCProjectManager

// ============================================================================
// ==== Intialization & deallocation
// ============================================================================

- (id)init
{
  if ((self = [super init]))
    {
      NSUserDefaults *defs = [NSUserDefaults standardUserDefaults];
      SEL            sall = @selector(saveAllProjectsIfNeeded);
      SEL            spdc = @selector(resetSaveTimer:);
      NSTimeInterval interval = [[defs objectForKey:AutoSavePeriod] intValue];

      loadedProjects = [[NSMutableDictionary alloc] init];

      rootBuildPath = [[defs stringForKey:RootBuildDirectory] copy];
      if (!rootBuildPath || [rootBuildPath isEqualToString:@""])
	{
	  rootBuildPath = [NSTemporaryDirectory() copy];
	}

      if ( [[defs objectForKey:AutoSave] isEqualToString:@"YES"] )
	{
	  saveTimer = [NSTimer scheduledTimerWithTimeInterval:interval
	                                               target:self
	                                             selector:sall
	                                             userInfo:nil
	                                              repeats:YES];
	}

      [[NSNotificationCenter defaultCenter] 
	addObserver:self 
	   selector:spdc 
	       name:SavePeriodDCN 
	     object:nil];

      nonProjectEditors = [[NSMutableDictionary alloc] init];

      [[NSNotificationCenter defaultCenter] 
	addObserver:self 
	   selector:@selector(editorDidClose:)
	       name:PCEditorDidCloseNotification
	     object:nil];
	     
      fileManager = [[PCFileManager alloc] initWithProjectManager:self];
//      [fileManager setDelegate:self];

      [self _initUI];
      
      _needsReleasing = NO;
    }

  return self;
}

- (void)dealloc
{
  NSLog (@"PCProjectManager: dealloc");
  [[NSNotificationCenter defaultCenter] removeObserver:self];

  if ([saveTimer isValid])
    {
      [saveTimer invalidate];
    }

  RELEASE(projectTypeAccessaryView);
  RELEASE(fileTypeAccessaryView);
  RELEASE(rootBuildPath);
  RELEASE(loadedProjects);

  if (historyPanel) RELEASE(historyPanel);
  if (buildPanel)   RELEASE(buildPanel);
  if (launchPanel)  RELEASE(launchPanel);

  [super dealloc];
}

- (void)setDelegate:(id)aDelegate 
{
  delegate = aDelegate;
}

// ============================================================================
// ==== Intialization & deallocation
// ============================================================================

- (void)_initUI
{
  NSRect fr = NSMakeRect(20,30,160,20);

  // For "Open Project" and "New Project" panels
  projectTypePopup = [[NSPopUpButton alloc] initWithFrame:fr pullsDown:NO];
  [projectTypePopup setAutoenablesItems:NO];
  [projectTypePopup addItemWithTitle:@"No type available!"];

  projectTypeAccessaryView = [[NSBox alloc] init];
  [projectTypeAccessaryView setTitle:@"Project Types"];
  [projectTypeAccessaryView setTitlePosition:NSAtTop];
  [projectTypeAccessaryView setBorderType:NSGrooveBorder];
  [projectTypeAccessaryView addSubview:projectTypePopup];
  [projectTypeAccessaryView sizeToFit];
  [projectTypeAccessaryView setAutoresizingMask:NSViewMinXMargin 
                                                | NSViewMaxXMargin];
  RELEASE(projectTypePopup);
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
  [projectTypePopup selectItemAtIndex:0];
}

// ============================================================================
// ==== Timer handling
// ============================================================================

- (void)resetSaveTimer:(NSNotification *)notif
{
    NSTimeInterval interval = [[notif object] intValue];
    SEL sall = @selector(saveAllProjectsIfNeeded);

    if( [saveTimer isValid] ) 
    {
        [saveTimer invalidate];
    }
  
    saveTimer = [NSTimer scheduledTimerWithTimeInterval:interval
						 target:self
					       selector:sall
					       userInfo:nil
						repeats:YES];
}

// ============================================================================
// ==== Accessory methods
// ============================================================================
- (PCFileManager *)fileManager
{
  return fileManager;
}

- (PCProjectInspector *)projectInspector
{
  if (!projectInspector)
    {
      projectInspector = 
	[[PCProjectInspector alloc] initWithProjectManager:self];
    }

  return projectInspector;
}

- (NSPanel *)inspectorPanel
{
  return [[self projectInspector] panel];
}

- (void)showProjectInspector:(id)sender
{
  [[[self projectInspector] panel] orderFront:self];
}

- (NSPanel *)historyPanel
{
  if (!historyPanel)
    {
      historyPanel = [[PCHistoryPanel alloc] initWithProjectManager:self];
    }

  return historyPanel;
}

- (void)showProjectHistory:(id)sender
{
  if ([[[[NSUserDefaults standardUserDefaults] dictionaryRepresentation]
              objectForKey: SeparateHistory] isEqualToString: @"YES"])
    {
      [[self historyPanel] orderFront: nil];
    }
}

- (NSPanel *)buildPanel
{
  if (!buildPanel)
    {
      buildPanel = [[PCBuildPanel alloc] initWithProjectManager:self];
    }

  return buildPanel;
}

- (NSPanel *)launchPanel
{
  if (!launchPanel)
    {
      launchPanel = [[PCLaunchPanel alloc] initWithProjectManager:self];
    }

  return launchPanel;
}

- (NSPanel *)projectFinderPanel
{
  return findPanel;
}

- (NSString *)rootBuildPath
{
  return rootBuildPath;
}

- (NSString *)projectPath
{
  return [activeProject projectPath];
}

- (NSString *)selectedFileName
{
  return [[activeProject projectBrowser] nameOfSelectedFile];
}

// ============================================================================
// ==== Project management
// ============================================================================

- (NSMutableDictionary *)loadedProjects
{
  return loadedProjects;
}

- (PCProject *)activeProject
{
  return activeProject;
}

- (void)setActiveProject:(PCProject *)aProject
{
  if (aProject != activeProject)
    {
      activeProject = aProject;

      NSLog(@"PCProjectManager: setActiveProject: %@", 
	    [activeProject projectName]);

      [[NSNotificationCenter defaultCenter]
	postNotificationName:ActiveProjectDidChangeNotification
	              object:activeProject];
    }
}

- (void)saveAllProjectsIfNeeded
{
  NSUserDefaults *defs = [NSUserDefaults standardUserDefaults];

  if ([[defs objectForKey:AutoSave] isEqualToString:@"YES"])
    {
      [self saveAllProjects];
    }
  else 
    {
      if ([saveTimer isValid])
	{
	  [saveTimer invalidate];
	}
    }
}

- (BOOL)saveAllProjects
{
  NSEnumerator *enumerator = [loadedProjects keyEnumerator];
  NSString     *key;
  PCProject    *project;

  while ((key = [enumerator nextObject]))
    {
      project = [loadedProjects objectForKey:key];

      if ([project save] == NO)
	{
	  return NO;
	}
    }

  return YES;
}

// ============================================================================
// ==== Project actions
// ============================================================================

- (PCProject *)loadProjectAt:(NSString *)aPath
{
  NSDictionary    *projectFile = nil;
  NSString        *projectTypeName = nil;
  NSString        *projectClassName = nil;
  id<ProjectType> projectCreator;
  PCProject       *project = nil;

  projectFile = [NSDictionary dictionaryWithContentsOfFile:aPath];
  // For compatibility with 0.3.x projects
  projectClassName = [projectFile objectForKey:PCProjectBuilderClass];
  if (projectClassName == nil)
    {
      projectTypeName = [projectFile objectForKey:PCProjectType];
      projectClassName = [[delegate projectTypes]objectForKey:projectTypeName];
    }
  projectCreator = [NSClassFromString(projectClassName) sharedCreator];

  if ((project = [projectCreator openProjectAt:aPath])) 
    {
      NSLog (@"Project loaded as %@", [projectCreator projectTypeName]);
      return project;
    }

  NSRunAlertPanel(@"Loading Project Failed!",
		  @"Could not load project '%@'!",
		  @"OK",nil,nil,aPath); 

  return nil;
}

- (BOOL)openProjectAt:(NSString *)aPath
{
  BOOL     isDir = NO;
  NSString *projectName = nil;

  projectName = [[aPath stringByDeletingLastPathComponent] lastPathComponent];

  if ([loadedProjects objectForKey:projectName]) 
    {
      NSRunAlertPanel(@"Attention!",
		      @"Project '%@' has already been opened!", 
		      @"OK",nil,nil,projectName);
      return NO;
    }

  if ([[NSFileManager defaultManager] fileExistsAtPath:aPath 
                                           isDirectory:&isDir] && !isDir) 
    {
      PCProject *project = [self loadProjectAt:aPath];

      if (!project) 
	{
	  return NO;
	}

      [project setProjectManager:self];
      [project validateProjectDict];
      [loadedProjects setObject:project forKey:projectName];
      [self setActiveProject:project];
      [[project projectWindow] orderFront:self];

      return YES;
    }

  return NO;
}

- (BOOL)createProjectOfType:(NSString *)projectType path:(NSString *)aPath
{
  Class	    creatorClass = NSClassFromString(projectType);
  PCProject *project;
  NSString  *projectName = [aPath lastPathComponent];

  if ([loadedProjects objectForKey:projectName]) 
    {
      NSRunAlertPanel(@"Attention!",
		      @"Project '%@' has already been opened!", 
		      @"OK",nil,nil,projectName);
      return NO;
    }

  if (![creatorClass conformsToProtocol:@protocol(ProjectType)]) 
    {
      [NSException raise:NOT_A_PROJECT_TYPE_EXCEPTION 
	          format:@"%@ does not conform to ProjectType!",projectType];
      return NO;
    }

  if (!(project = [[creatorClass sharedCreator] createProjectAt:aPath])) 
    {
      return NO;
    }

  [project setProjectManager:self];
  [loadedProjects setObject:project forKey:projectName];
  [self setActiveProject:project];
  [[project projectWindow] orderFront:self];

  return YES;
}

- (void)openProject
{
  NSArray  *files = nil;
  NSString *filePath = nil;
  NSArray  *fileTypes = [NSArray arrayWithObjects:@"project",@"pcproj",nil];

  files = [fileManager filesForOpenOfType:fileTypes
                                 multiple:NO
			            title:@"Open Project"
				  accView:nil];
  filePath = [files objectAtIndex:0];

  if (filePath != nil && [self openProjectAt:filePath] == NO)
    {
      NSRunAlertPanel(@"Attention!",
		      @"Couldn't open project %@!",
		      @"OK",nil,nil,
		      [filePath stringByDeletingLastPathComponent]);
    }
}

- (void)newProject
{
  NSString *filePath = nil;
  NSArray  *fileTypes = [NSArray arrayWithObjects:@"project",@"pcproj",nil];
  NSString *projectType = nil;
  NSString *className = nil;

  filePath = [fileManager fileForSaveOfType:fileTypes
	  		              title:@"New Project"
				    accView:projectTypeAccessaryView];
  if (filePath != nil) 
    {
      projectType = [projectTypePopup titleOfSelectedItem];
      className = [[delegate projectTypes] objectForKey:projectType];

      if (![self createProjectOfType:className path:filePath])
	{
	  NSRunAlertPanel(@"Attention!",
			  @"Failed to create %@!",
			  @"OK",nil,nil,filePath);
	}
    }
}

- (BOOL)saveProject
{
  if (![self activeProject])
    {
      return NO;
    }

  // Save PC.project and the makefiles!
  if ([activeProject save] == NO)
    {
      NSRunAlertPanel(@"Attention!",
		      @"Couldn't save project %@!", 
		      @"OK",nil,nil,[activeProject projectName]);
      return NO;
    }

  return YES;
}

- (BOOL)addProjectFiles
{
  NSString       *category = nil;
  NSArray        *fileTypes = nil;
  NSMutableArray *files = nil;

  category = [activeProject selectedRootCategory];
  fileTypes = [activeProject fileTypesForCategory:category];

/*  [fileTypePopup removeAllItems];
  [fileTypePopup addItemsWithTitles:[activeProject rootKeys]];
  // Order Open panel and return selected files
  files = [fileManager filesForOpenOfType:fileTypes
                                 multiple:YES
				    title:@"Add files"
				  accView:fileTypeAccessaryView];*/
  files = [fileManager filesForAdd];

  // No files was selected 
  if (!files)
    {
      return NO;
    }

  // Copy and add files
  [activeProject addAndCopyFiles:files forKey:category];

  return YES;
}

- (BOOL)saveProjectFiles
{
  return [[activeProject projectEditor] saveAllFiles];
}

- (BOOL)removeProjectFiles
{
  NSArray  *files = nil;
  NSString *category = nil;
  NSString *directory = nil;

  if (!activeProject)
    {
      return NO;
    }

  files = [[activeProject projectBrowser] selectedFiles];
  category = [activeProject selectedRootCategory];
  directory = [activeProject dirForCategory:category];

  if (files)
    {
      int ret;

      ret = NSRunAlertPanel(@"Remove",
			    @"Remove files...",
			    @"...from Project and Disk",
			    @"...from Project only",
			    @"Cancel");

      if (ret == NSAlertDefaultReturn || ret == NSAlertAlternateReturn)
	{
	  BOOL flag = (ret == NSAlertDefaultReturn) ? YES : NO;

	  ret = [activeProject removeFiles:files forKey:category];
	  if (flag && ret)
	    {
	      ret = [fileManager removeFiles:files fromDirectory:directory];
	    }

	  if (!ret)
	    {
	      NSRunAlertPanel(@"Alert",
			      @"Error removing files from project %@!",
			      @"OK", nil, nil, [activeProject projectName]);
	    }
	  return NO;
	}
    }

  return YES;
}

// subprojects
- (BOOL)newSubproject
{
    return NO;
}

- (BOOL)addSubprojectAt:(NSString *)path
{
    return NO;
}

- (void)removeSubproject
{
}
//

- (void)closeProject:(PCProject *)aProject
{
  PCProject *currentProject = nil;
  NSString  *projectName = [aProject projectName];

  currentProject = RETAIN([loadedProjects objectForKey:projectName]);
  if (!currentProject)
    {
      return;
    }

  // Remove it from the loaded projects!
  [loadedProjects removeObjectForKey:projectName];

  if ([loadedProjects count] == 0)
    {
      if (projectInspector) [projectInspector close];
      if (historyPanel) [historyPanel close];
      if (buildPanel) [buildPanel close];
      if (launchPanel) [launchPanel close];
      [self setActiveProject: nil];
    }
  else if (currentProject == [self activeProject])
    {
      [self setActiveProject:[[loadedProjects allValues] lastObject]];
    }

  RELEASE(currentProject);
}

- (void)closeProject
{
  [activeProject close:self];
}

- (BOOL)closeAllProjects
{
  while ([loadedProjects count] > 0)
    {
      if ([activeProject close:self] == NO)
	{
	  return NO;
	}
    }
   
  return YES;
}

// ============================================================================
// ==== File actions
// ============================================================================

- (void)openFile
{
  NSArray  *files = nil;
  NSString *filePath = nil;

  files = [fileManager filesForOpenOfType:nil
                                 multiple:NO
			            title:@"Open File"
				  accView:nil];
  filePath = [files objectAtIndex:0];

  if (filePath != nil)
    {
      [self openFileWithEditor:filePath];
    }
}

- (void)newFile
{
  [fileManager showNewFileWindow];
}

- (BOOL)saveFile
{
  return [[activeProject projectEditor] saveFile];
}

- (BOOL)saveFileAs:(NSString *)path
{
  return [[activeProject projectEditor] saveFileAs:path];
}

- (BOOL)saveFileTo
{
  NSString *filePath = nil;

  filePath = [fileManager fileForSaveOfType:nil
			              title:@"Save To..."
				    accView:nil];

  if (filePath != nil && ![[activeProject projectEditor] saveFileTo:filePath]) 
    {
      NSRunAlertPanel(@"Alert", @"Couldn't save file to\n%@!",
		      @"OK", nil, nil, filePath);
      return NO;
    }

  return YES;
}

- (BOOL)revertFileToSaved
{
  return [[activeProject projectEditor] revertFileToSaved];
}

- (void)closeFile
{
  return [[activeProject projectEditor] closeActiveEditor:self];
}

- (BOOL)renameFileTo:(NSString *)path
{
  return YES;
}

// Project menu
// ============================================================================
// ==== Non project editors
// ============================================================================

- (void)openFileWithEditor:(NSString *)path
{
  PCEditor *editor;

  editor = [PCProjectEditor openFileInEditor:path];
  
  [nonProjectEditors setObject:editor forKey:path];
  RELEASE(editor);
}

- (void)editorDidClose:(NSNotification *)aNotif
{
  PCEditor *editor = [aNotif object];
  
  [nonProjectEditors removeObjectForKey:[editor path]];
}

@end

@implementation  PCProjectManager (FileManagerDelegates)

// willCreateFile
- (NSString *)fileManager:(id)sender
           willCreateFile:(NSString *)aFile
	          withKey:(NSString *)key
{
  NSString *path = nil;

  if ([activeProject doesAcceptFile:aFile forKey:key]) 
    {
      path = [[activeProject projectPath] stringByAppendingPathComponent:aFile];
    }

  return path;
}

// didCreateFiles
- (void)fileManager:(id)sender
      didCreateFile:(NSString *)aFile
            withKey:(NSString *)key
{
  [activeProject addFiles:[NSArray arrayWithObject:aFile] forKey:key];
}

@end

