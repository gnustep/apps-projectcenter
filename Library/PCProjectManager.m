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
#include "PCProjectManager.h"
#include "PCHistoryPanel.h"
#include "PCBuildPanel.h"
#include "PCLaunchPanel.h"

#include "PCProject.h"
#include "PCProjectWindow.h"
#include "PCProjectBrowser.h"
#include "PCProjectInspector.h"
#include "PCProjectEditor.h"
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

      [[NSNotificationCenter defaultCenter] addObserver:self 
	                                       selector:spdc 
	                                           name:SavePeriodDCN 
	                                         object:nil];

      fileManager = [PCFileManager fileManager];
      [fileManager setDelegate:self];
      
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

  RELEASE(rootBuildPath);
  RELEASE(loadedProjects);

  if (historyPanel) RELEASE(historyPanel);
  if (buildPanel)   RELEASE(buildPanel);
  if (launchPanel)  RELEASE(launchPanel);

  [super dealloc];
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

- (void)showProjectInspector:(id)sender
{
  [[[self projectInspector] panel] makeKeyAndOrderFront:self];
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

      [[NSNotificationCenter defaultCenter]
	postNotificationName:ActiveProjectDidChangeNotification
	              object:activeProject];
    }
}

- (void)saveAllProjectsIfNeeded
{
    NSUserDefaults *defs = [NSUserDefaults standardUserDefaults];

    if( [[defs objectForKey:AutoSave] isEqualToString:@"YES"] ) 
    {
        [self saveAllProjects];
    }
    else 
    {
        if( [saveTimer isValid] ) 
	{
	    [saveTimer invalidate];
	}
    }
}

- (void)saveAllProjects
{
    NSEnumerator *enumerator = [loadedProjects keyEnumerator];
    NSString *key;
    BOOL ret;
    PCProject *project;

    while ( (key = [enumerator nextObject]) )
    {
        project = [loadedProjects objectForKey:key];
	ret = [project save];

        if( ret == NO ) 
	{
            NSRunAlertPanel(@"Attention!",
                            @"Couldn't save project %@!", 
                            @"OK",nil,nil,[project projectName]);
        }
    }
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
// ==== Project actions
// ============================================================================

- (NSString *)projectNameAtPath:(NSString *)aPath
{
  return [[aPath stringByDeletingLastPathComponent] lastPathComponent];
}

- (PCProject *)loadProjectAt:(NSString *)aPath
{
  NSDictionary    *projectFile;
  NSString        *projectClassName;
  id<ProjectType> projectCreator;
  PCProject       *project;

  projectFile = [NSDictionary dictionaryWithContentsOfFile:aPath];
  projectClassName = [projectFile objectForKey:PCProjectBuilderClass];
  projectCreator = [NSClassFromString(projectClassName) sharedCreator];

  NSLog (@"Load project at %@", aPath);
  
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

  projectName = [self projectNameAtPath:aPath];

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
      [loadedProjects setObject:project forKey:projectName];
      [self setActiveProject:project];

      [project validateProjectDict];

      return YES;
    }

  return NO;
}

- (BOOL)createProjectOfType:(NSString *)projectType path:(NSString *)aPath
{
  Class	    creatorClass = NSClassFromString(projectType);
  PCProject *project;

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

  [loadedProjects setObject:project forKey:[self projectNameAtPath:aPath]];

  [self setActiveProject:project];

  return YES;
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
    }

  return YES;
}

- (BOOL)saveProjectAs:(NSString *)projName
{
  return NO;
}

- (void)revertToSaved
{
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

  // Remove it from the loaded projects! This is the only place it
  // is retained, so it should dealloc after this.
  [loadedProjects removeObjectForKey:projectName];

  if ([loadedProjects count] == 0)
    {
      [projectInspector close];
      [historyPanel close];
      [buildPanel close];
      [launchPanel close];
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
  [[activeProject projectWindow] performClose:self];
}

// ============================================================================
// ==== File actions
// ============================================================================

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

- (BOOL)saveFileTo:(NSString *)path
{
  return [[activeProject projectEditor] saveFileTo:path];
}

- (BOOL)revertFileToSaved
{
  return [[activeProject projectEditor] revertFileToSaved];
}

- (void)closeFile
{
  return [[activeProject projectEditor] closeFile:self];
}

- (BOOL)renameFileTo:(NSString *)path
{
  return YES;
}

// Project menu
- (BOOL)addProjectFiles
{
  NSString       *category = nil;
  NSString       *directory = nil;
  NSArray        *fileTypes = nil;
  NSMutableArray *files = nil;

  category = [activeProject selectedRootCategory];
  directory = [activeProject dirForCategory:category];
  fileTypes = [activeProject fileTypesForCategory:category];

  // Order Open panel and return selected files
  files = [fileManager selectFilesOfType:fileTypes multiple:YES];

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
			    @"Cancel",
			    @"...from Project only",
			    @"...from Project and Disk");

      if (ret == NSAlertAlternateReturn || ret == NSAlertOtherReturn) 
	{
	  BOOL flag = (ret == NSAlertOtherReturn) ? YES : NO;

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

