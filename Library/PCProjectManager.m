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

#include "PCBundleLoader.h"
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

NSString *PCActiveProjectDidChangeNotification = @"PCActiveProjectDidChange";

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

      [self loadProjectTypeBunldes];

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

  RELEASE(bundleLoader);
  RELEASE(projectTypes);
  RELEASE(projectTypeAccessaryView);
  RELEASE(fileTypeAccessaryView);
  RELEASE(rootBuildPath);
  RELEASE(loadedProjects);

  if (projectInspector)  RELEASE(projectInspector);
  if (historyPanel)      RELEASE(historyPanel);
  if (buildPanel)        RELEASE(buildPanel);
  if (launchPanel)       RELEASE(launchPanel);

  [super dealloc];
}

- (void)setDelegate:(id)aDelegate 
{
  delegate = aDelegate;
}

- (void)createProjectTypeAccessaryView
{
  NSRect fr = NSMakeRect(20,30,160,20);

  if (projectTypeAccessaryView != nil)
    {
      return;
    }

  // For "Open Project" and "New Project" panels
  projectTypePopup = [[NSPopUpButton alloc] initWithFrame:fr pullsDown:NO];
  [projectTypePopup setAutoenablesItems:NO];
  [projectTypePopup addItemsWithTitles:
    [[projectTypes allKeys] 
    sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)]];
  [projectTypePopup sizeToFit];
  [projectTypeAccessaryView sizeToFit];
  [projectTypePopup selectItemAtIndex:0];

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
// ==== Accessary methods
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

- (PCProject *)rootActiveProject
{
  PCProject *rootProject = nil;

  if (!activeProject)
    {
      return nil;
    }
  
  rootProject = activeProject;
  while ([rootProject isSubproject] == YES)
    {
      rootProject = [rootProject superProject];
    }

  return rootProject;
}

- (void)setActiveProject:(PCProject *)aProject
{
  if (aProject != activeProject)
    {
      activeProject = aProject;

      [[NSNotificationCenter defaultCenter]
	postNotificationName:PCActiveProjectDidChangeNotification
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
  NSMutableDictionary *projectFile = nil;
  NSString            *projectTypeName = nil;
  NSString            *projectClassName = nil;
  id<ProjectType>     projectCreator;
  PCProject           *project = nil;

  projectFile = [NSMutableDictionary dictionaryWithContentsOfFile:aPath];
  
  // For compatibility with 0.3.x projects
  projectClassName = [projectFile objectForKey:PCProjectBuilderClass];
  
  if (projectClassName == nil)
    {
      projectTypeName = [projectFile objectForKey:PCProjectType];
      projectClassName = [projectTypes objectForKey:projectTypeName];
    }

  projectCreator = [NSClassFromString(projectClassName) sharedCreator];

   if (projectTypeName == nil)
    {
      NSString *pPath = nil;

      pPath = [[aPath stringByDeletingLastPathComponent]
        stringByAppendingPathComponent:@"PC.project"];

      [[NSFileManager defaultManager] removeFileAtPath:aPath handler:nil];

      [projectFile removeObjectForKey:PCProjectBuilderClass];
      projectTypeName = [projectCreator projectTypeName];
      [projectFile setObject:projectTypeName forKey:PCProjectType];
      [projectFile writeToFile:pPath atomically:YES];

      aPath = pPath;
    }

  if ((project = [projectCreator openProjectAt:aPath])) 
    {
      NSLog (@"Project %@ loaded as %@", [projectCreator projectTypeName]);
      return project;
    }

  NSRunAlertPanel(@"Loading Project Failed!",
		  @"Could not load project '%@'!",
		  @"OK",nil,nil,aPath); 

  return nil;
}

- (BOOL)openProjectAt:(NSString *)aPath
{
  BOOL      isDir = NO;
  NSString  *projectName = nil;
  PCProject *project = nil;

  projectName = [[aPath stringByDeletingLastPathComponent] lastPathComponent];

  if ((project = [loadedProjects objectForKey:projectName]) != nil)
    {
      [[project projectWindow] makeKeyAndOrderFront:self];
      return YES;
    }

  if ([[NSFileManager defaultManager] fileExistsAtPath:aPath 
                                           isDirectory:&isDir] && !isDir) 
    {
      project = [self loadProjectAt:aPath];

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

- (PCProject *)createProjectOfType:(NSString *)projectType 
                              path:(NSString *)aPath
{
  NSString  *className = [projectTypes objectForKey:projectType];
  Class	    creatorClass = NSClassFromString(className);
  PCProject *project = nil;
  NSString  *projectName = [aPath lastPathComponent];

  if ((project = [loadedProjects objectForKey:projectName]) != nil)
    {
      [[project projectWindow] makeKeyAndOrderFront:self];
      return project;
    }

  if (![creatorClass conformsToProtocol:@protocol(ProjectType)]) 
    {
      [NSException raise:NOT_A_PROJECT_TYPE_EXCEPTION 
	          format:@"%@ does not conform to ProjectType!", projectType];
      return nil;
    }

  if (!(project = [[creatorClass sharedCreator] createProjectAt:aPath])) 
    {
      return nil;
    }

  [project setProjectManager:self];

  return project;
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
  NSString  *filePath = nil;
  NSArray   *fileTypes = [NSArray arrayWithObjects:@"project",@"pcproj",nil];
  NSString  *projectType = nil;
  PCProject *project = nil;

  [self createProjectTypeAccessaryView];
  
  filePath = [fileManager fileForSaveOfType:fileTypes
	  		              title:@"New Project"
				    accView:projectTypeAccessaryView];
  if (filePath != nil) 
    {
      projectType = [projectTypePopup titleOfSelectedItem];

      if (!(project = [self createProjectOfType:projectType path:filePath]))
	{
	  NSRunAlertPanel(@"Attention!",
			  @"Failed to create %@!",
			  @"OK",nil,nil,filePath);
	}

      [loadedProjects setObject:project forKey:[project projectName]];
      [self setActiveProject:project];
      [[project projectWindow] orderFront:self];
    }
}

- (BOOL)saveProject
{
  PCProject *rootProject = [self rootActiveProject];

  if (!rootProject)
    {
      return NO;
    }
    
  NSLog(@"PCPM: save root project: %@", [rootProject projectName]);

  // Save PC.project and the makefiles!
  if ([rootProject save] == NO)
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
  NSString       *categoryKey = nil;
  NSArray        *fileTypes = nil;
  NSMutableArray *files = nil;

  categoryKey = [activeProject selectedRootCategoryKey];
  fileTypes = [activeProject fileTypesForCategoryKey:categoryKey];

  files = [fileManager filesForAdd];

  // No files was selected 
  if (!files)
    {
      return NO;
    }

  // Copy and add files
  [activeProject addAndCopyFiles:files forKey:categoryKey];

  return YES;
}

- (BOOL)saveProjectFiles
{
  return [[activeProject projectEditor] saveAllFiles];
}

- (BOOL)removeProjectFiles
{
  NSArray  *files = nil;
  NSString *categoryKey = nil;
  NSString *directory = nil;

  if (!activeProject)
    {
      return NO;
    }

  files = [[activeProject projectBrowser] selectedFiles];
  categoryKey = [activeProject selectedRootCategoryKey];
  directory = [activeProject dirForCategoryKey:categoryKey];

  if (files)
    {
      int ret;

      if ([categoryKey isEqualToString:PCLibraries])
	{
	  ret = NSRunAlertPanel(@"Remove",
				@"Remove libraries from Project?",
				@"Remove",
				@"Cancel",
				nil);
	}
      else
	{
	  ret = NSRunAlertPanel(@"Remove",
				@"Remove files...",
				@"...from Project and Disk",
				@"...from Project only",
				@"Cancel");
	}

      if (ret == NSAlertDefaultReturn || ret == NSAlertAlternateReturn)
	{
	  BOOL flag = (ret == NSAlertDefaultReturn) ? YES : NO;

	  ret = [activeProject removeFiles:files forKey:categoryKey];
	  if (flag && ret && ![categoryKey isEqualToString:PCLibraries])
	    {
	      ret = [fileManager removeFiles:files fromDirectory:directory];
	    }
	  if (!ret)
	    {
	      NSRunAlertPanel(@"Alert",
			      @"Error removing files from project %@!",
			      @"OK", nil, nil, [activeProject projectName]);
	    }
	  // Save project because we've removed file from disk
	  // Should be fixed later (add pending removal of files?)
	  else if (flag) 
	    {
	      [activeProject save];
	    }
	  return NO;
	}
    }

  return YES;
}

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
  PCProject    *project = nil;
  NSEnumerator *enumerator = [loadedProjects objectEnumerator];

  NSLog(@"ProjectManager: loaded %i projects", [loadedProjects count]);

  while ([loadedProjects count] > 0)
    {
      project = [enumerator nextObject];
      if ([project close:self] == NO)
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
  [fileManager showNewFilePanel];
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

- (BOOL)renameFile
{
  [self showProjectInspector:self];
  [projectInspector selectSectionWithTitle:@"File Attributes"];
  [projectInspector beginFileRename];

  return YES;
}

- (void)closeFile
{
  return [[activeProject projectEditor] closeActiveEditor:self];
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

@implementation PCProjectManager (FileManagerDelegates)

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

@implementation PCProjectManager (ProjectRegistration)

- (void)loadProjectTypeBunldes
{
  projectTypes = [[NSMutableDictionary alloc] init];

  bundleLoader = [[PCBundleLoader alloc] init];
  [bundleLoader setDelegate:self];
  [bundleLoader loadBundles];
}

- (PCBundleLoader *)bundleLoader
{
  return bundleLoader;
}

- (NSDictionary *)projectTypes
{
  return projectTypes;
}

- (void)bundleLoader:(id)sender didLoadBundle:(NSBundle *)aBundle
{
  Class    principalClass;
  NSString *projectTypeName = nil;

  NSAssert(aBundle,@"No valid bundle!");

  principalClass = [aBundle principalClass];
  projectTypeName = [[principalClass sharedCreator] projectTypeName];

  if (![projectTypes objectForKey:projectTypeName]) 
    {
      [projectTypes setObject:NSStringFromClass(principalClass)
	               forKey:projectTypeName];
    }
}

@end

@implementation PCProjectManager (Subprojects)

// --- New
- (BOOL)newSubproject
{
  NSLog (@"newSubproject");

  if (!nsPanel)
    {
      if ([NSBundle loadNibNamed:@"NewSubproject" owner:self] == NO)
	{
	  NSLog(@"PCProjectManager: error loading NewSubproject NIB!");
	  return NO;
	}

      [nsPanel setFrameAutosaveName:@"NewSubproject"];
      if (![nsPanel setFrameUsingName: @"NewSubproject"])
    	{
	  [nsPanel center];
	}

      [nsImage setImage:[NSApp applicationIconImage]];
      [nsTypePB removeAllItems];
      [nsTypePB addItemsWithTitles:
	[[activeProject allowableSubprojectTypes] 
	sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)]];
      [nsTypePB setRefusesFirstResponder:YES];
      [nsTypePB selectItemAtIndex:0];
      [nsCancelButton setRefusesFirstResponder:YES];
      [nsCreateButton setRefusesFirstResponder:YES];
    }
  [projectNameField setStringValue:[activeProject projectName]];
  [nsPanel makeKeyAndOrderFront:nil];
  [nsNameField setStringValue:@""];
  [nsPanel makeFirstResponder:nsNameField];

  return YES;
}

- (void)closeNewSubprojectPanel:(id)sender
{
  [nsPanel orderOut:self];
}

- (BOOL)createSubproject:(id)sender
{
  [nsPanel orderOut:self];

  return [self createSubproject];
}

- (BOOL)createSubproject
{
  PCProject *superProject = activeProject;
  PCProject *subproject = nil;
  NSString  *spName = [nsNameField stringValue];
  NSString  *spPath = nil;
  NSString  *spType = [nsTypePB titleOfSelectedItem];

  if (![[spName pathExtension] isEqualToString:@"subproj"])
    {
      spName = [[nsNameField stringValue] 
	stringByAppendingPathExtension:@"subproj"];
    }

  spPath = [[activeProject projectPath] stringByAppendingPathComponent:spName];

  NSLog(@"ProjectManager: creating subproject with type %@ at path %@",
	spType, spPath);
  // Create subproject
  subproject = [self createProjectOfType:spType path:spPath];

  // For now root project can contain subproject but suboproject can't.
  [subproject setIsSubproject:YES];
  [subproject setSuperProject:superProject];

  [superProject addSubproject:subproject];

  return YES;
}

- (void)controlTextDidChange:(NSNotification *)aNotif
{
  if ([aNotif object] != nsNameField)
    {
      return;
    }
    
  // TODO: Add check for valid subproject named
  if ([[nsNameField stringValue] length] > 0)
    {
      [nsCreateButton setEnabled:YES];
    }
  else
    {
      [nsCreateButton setEnabled:NO];
    }
}

// --- Add
- (BOOL)addSubprojectAt:(NSString *)path
{
  return NO;
}

// --- Remove
- (void)removeSubproject
{
}

@end

