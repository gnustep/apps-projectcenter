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

#include "PCFileManager.h"
#include "PCProjectManager.h"
#include "PCProject.h"
#include "PCDefines.h"
#include "ProjectBuilder.h"
#include "PCProject+ComponentHandling.h"

#include "PCProjectWindow.h"
#include "PCProjectBrowser.h"
#include "PCProjectHistory.h"

#include "PCProjectInspector.h"
#include "PCProjectBuilder.h"
#include "PCProjectEditor.h"
#include "PCProjectLauncher.h"
#include "PCEditor.h"

NSString 
*PCProjectDictDidChangeNotification = @"PCProjectDictDidChangeNotification";
NSString 
*PCProjectDictDidSaveNotification = @"PCProjectDictDidSaveNotification";

@implementation PCProject

// ============================================================================
// ==== Init and free
// ============================================================================

- (id)init
{
  if ((self = [super init])) 
    {
      buildOptions = [[NSMutableDictionary alloc] init];
      projectBrowser = [[PCProjectBrowser alloc] initWithProject:self];
      projectHistory = [[PCProjectHistory alloc] initWithProject:self];
      projectEditor = [[PCProjectEditor alloc] initWithProject:self];
      projectWindow = [[PCProjectWindow alloc] initWithProject:self];
      projectBuilder = nil;
      projectLauncher = nil;

      loadedSubprojects = [[NSMutableArray alloc] init];
      isSubproject = NO;
      activeSubproject = nil;
    }

  return self;
}

- (id)initWithProjectDictionary:(NSDictionary *)dict path:(NSString *)path;
{
  NSAssert(dict,@"No valid project dictionary!");

  if ((self = [self init])) 
    {
      if ([[path lastPathComponent] isEqualToString:@"PC.project"])
	{
	  projectPath = [[path stringByDeletingLastPathComponent] copy];
	}
      else
	{
	  projectPath = [path copy];
	}

      NSLog (@"PCProject initWithProjectDictionary");

      if (![self assignProjectDict:dict])
	{
	  NSLog(@"<%@ %x>: could not load the project...",[self class],self);
	  [self autorelease];
	  return nil;
	}
      [self save];
    }

  return self;
}

- (void)setProjectManager:(PCProjectManager *)aManager
{
  projectManager = aManager;
}

- (BOOL)close:(id)sender
{
  NSLog(@"Closing %@ project", projectName);

  // Project files (GNUmakefile, PC.project etc.)
  if (isSubproject == NO && [self isProjectChanged] == YES)
    {
      int ret;

      ret = NSRunAlertPanel(@"Alert",
			    @"Project or subprojects are modified",
			    @"Save and Close",@"Don't save",@"Cancel");
      switch (ret)
	{
	case NSAlertDefaultReturn:
	  if ([self save] == NO)
	    {
	      return NO;
	    }
	  break;
	  
	case NSAlertAlternateReturn:
	  break;

	case NSAlertOtherReturn:
	  return NO;
	  break;
	}
    }
    
  // Close subprojects
  while ([loadedSubprojects count])
    {
      [(PCProject *)[loadedSubprojects objectAtIndex:0] close:self];
      // We should release subproject here, because it retains us
      // and we never reach -dealloc in other case.
      [loadedSubprojects removeObjectAtIndex:0];
    }

  if (isSubproject == YES)
    {
      return YES;
    }

  // Save visible windows and panels positions to project dictionary
/*  if ([self saveProjectWindowsAndPanels] == NO)
    {
      return NO;
    }*/
    
  // Editors
  // "Cancel" button on "Save Edited Files" panel selected
  if ([projectEditor closeAllEditors] == NO)
    {
      return NO;
    }

  // Project window
  if (sender != projectWindow)
    {
      [projectWindow close];
    }

  // Remove self from loaded projects
  [projectManager closeProject:self];

  return YES;
}

// For future use. Doesn't save now. Should omit saving project dict when
// it's changed and option "Save Project On Quit" doesn't set.
- (BOOL)saveProjectWindowsAndPanels
{
  NSMutableDictionary *windows = [projectDict objectForKey:@"PC_WINDOWS"];

  if (windows == nil)
    {
      windows = [[NSMutableDictionary alloc] init];
    }
  
  // Project Window
  [windows setObject:[projectWindow stringWithSavedFrame]
              forKey:@"ProjectWindow"];

  // Project Build
  if (projectBuilder && [[projectManager buildPanel] isVisible])
    {
      [windows setObject:[[projectManager buildPanel] stringWithSavedFrame]
	          forKey:@"ProjectBuild"];
    }
  else
    {
      [windows removeObjectForKey:@"ProjectBuild"];
    }

  // Project Launch
  if (projectLauncher && [[projectManager launchPanel] isVisible])
    {
      [windows setObject:[[projectManager launchPanel] stringWithSavedFrame]
                  forKey:@"ProjectLaunch"];
    }
  else
    {
      [windows removeObjectForKey:@"ProjectLaunch"];
    }

  // Project Inspector
/*  if ([[projectManager inspectorPanel] isVisible])
    {
      [windows setObject:[[projectManager inspectorPanel] stringWithSavedFrame]
                  forKey:@"ProjectInspector"];
    }
  else
    {
      [windows removeObjectForKey:@"ProjectInspector"];
    }*/

  // Loaded Files
  if (projectHistory && [[projectManager historyPanel] isVisible])
    {
      [windows setObject:[[projectManager historyPanel] stringWithSavedFrame]
                  forKey:@"LoadedFiles"];
    }
  else
    {
      [windows removeObjectForKey:@"LoadedFiles"];
    }
    
  [projectDict setObject:windows forKey:@"PC_WINDOWS"];
  NSLog(@"Windows saved");

  return YES;
}

- (void)dealloc
{
  NSLog (@"PCProject %@: dealloc", projectName);
  
  [[NSNotificationCenter defaultCenter] removeObserver:self];

  RELEASE(projectName);
  RELEASE(projectPath);
  RELEASE(projectDict);
  RELEASE(loadedSubprojects);

  // Initialized in -init
  // For subprojects we should release these objects, because we 
  // use ASSIGN() macro.
  RELEASE(projectWindow);
  RELEASE(projectBrowser);
  RELEASE(projectHistory);
  RELEASE(projectEditor);
  
  if (projectBuilder) RELEASE(projectBuilder);
  if (projectLauncher) RELEASE(projectLauncher);

  RELEASE(buildOptions);

  if (isSubproject == YES)
    {
      RELEASE(rootProject);
      RELEASE(superProject);
    }

  [super dealloc];
}

// ============================================================================
// ==== Accessory methods
// ============================================================================

- (PCProjectManager *)projectManager
{
  return projectManager;
}

- (PCProjectBrowser *)projectBrowser
{
  return projectBrowser;
}

- (PCProjectHistory *)projectHistory
{
  if (!projectHistory && !isSubproject)
    {
      projectHistory = [[PCProjectHistory alloc] initWithProject:self];
    }

  return projectHistory;
}

- (PCProjectBuilder *)projectBuilder
{
  if (!projectBuilder && !isSubproject)
    {
      projectBuilder = [[PCProjectBuilder alloc] initWithProject:self];
    }

  return projectBuilder;
}

- (PCProjectLauncher *)projectLauncher
{
  if (!projectLauncher && !isSubproject)
    {
      projectLauncher = [[PCProjectLauncher alloc] initWithProject:self];
    }

  return projectLauncher;
}

- (PCProjectEditor *)projectEditor
{
  return projectEditor;
}

- (NSString *)selectedRootCategory
{
  NSString *_path = [[self projectBrowser] pathOfSelectedFile];

  return [self categoryForCategoryPath:_path];
}

- (NSString *)selectedRootCategoryKey
{
  NSString *_path = [[self projectBrowser] pathOfSelectedFile];
  NSString *key = [self keyForCategoryPath:_path];

  NSLog(@"PCProject: selected category: %@. key: %@", _path, key);

  return key;
}

- (void)setProjectDictObject:(id)object forKey:(NSString *)key
{
  id currentObject = [projectDict objectForKey:key];

  if ([object isKindOfClass:[NSString class]]
      && [currentObject isEqualToString:object])
    {
      return;
    }

  [projectDict setObject:object forKey:key];

  [[NSNotificationCenter defaultCenter] 
    postNotificationName:PCProjectDictDidChangeNotification
                  object:self];
}

- (void)setProjectName:(NSString *)aName
{
  AUTORELEASE(projectName);
  projectName = [aName copy];
  [projectWindow setFileIconTitle:projectName];
}

- (NSString *)projectName
{
  return projectName;
}

- (PCProjectWindow *)projectWindow
{
  return projectWindow;
}

- (BOOL)isProjectChanged
{
  return [projectWindow isDocumentEdited];
}

- (Class)principalClass
{
  return [self class];
}

// ============================================================================
// ==== To be overriden
// ============================================================================

- (NSView *)projectAttributesView
{
  return nil;
}

- (Class)builderClass
{
  return nil;
}

- (NSString *)projectDescription
{
  return @"Abstract PCProject class!";
}

- (BOOL)isExecutable
{
  return NO;
}

- (NSString *)execToolName
{
  return nil;
}

- (NSArray *)fileTypesForCategoryKey:(NSString *)key 
{
  return nil;
}

- (NSString *)dirForCategoryKey:(NSString *)key 
{
  return projectPath;
}

- (NSArray *)buildTargets
{
  return nil;
}

- (NSArray *)sourceFileKeys
{
  return nil;
}

- (NSArray *)resourceFileKeys
{
  return nil;
}

- (NSArray *)otherKeys
{
  return nil;
}

- (NSArray *)allowableSubprojectTypes
{
  return nil;
}

- (NSArray *)defaultLocalizableKeys
{
  return nil;
}

- (NSArray *)localizableKeys
{
  return nil;
}

- (BOOL)isEditableCategory:(NSString *)category
{
  NSString *key = [self keyForCategory:category];

  if ([key isEqualToString:PCClasses]
      || [key isEqualToString:PCHeaders]
      || [key isEqualToString:PCSupportingFiles]
      || [key isEqualToString:PCDocuFiles]
      || [key isEqualToString:PCOtherSources]
      || [key isEqualToString:PCOtherResources]
      || [key isEqualToString:PCNonProject]) 
    {
      return YES;
    }

  return NO;
}

// Saves backup file
- (BOOL)writeMakefile
{
  NSString *mf = [projectPath stringByAppendingPathComponent:@"GNUmakefile"];
  NSString *bu = [projectPath stringByAppendingPathComponent:@"GNUmakefile~"];
  NSFileManager *fm = [NSFileManager defaultManager];

  if ([fm isReadableFileAtPath:mf])
    {
      if ([fm isWritableFileAtPath:bu])
	{
	  [fm removeFileAtPath:bu handler:nil];
	}

      if (![fm copyPath:mf toPath:bu handler:nil])
	{
	  NSRunAlertPanel(@"Attention!",
			  @"Could not keep a backup of the GNUMakefile!",
			  @"OK",nil,nil);
	}
    }

  return YES;
}

// ============================================================================
// ==== File Handling
// ============================================================================

- (NSString *)projectFileFromFile:(NSString *)file forKey:(NSString *)type
{
  NSMutableString *projectFile = nil;

  projectFile = [NSMutableString stringWithString:[file lastPathComponent]];

  if ([type isEqualToString:PCLibraries])
    {
      [projectFile deleteCharactersInRange:NSMakeRange(0,3)];
      projectFile = 
	(NSMutableString*)[projectFile stringByDeletingPathExtension];
    }

  return projectFile;
}

- (BOOL)doesAcceptFile:(NSString *)file forKey:(NSString *)type
{
  NSArray  *projectFiles = [projectDict objectForKey:type];
  NSString *pFile = [self projectFileFromFile:file forKey:type];

  if ([[projectDict allKeys] containsObject:type])
    {
      if (![projectFiles containsObject:pFile])
	{
	  return YES;
	}
    }

  return NO;
}

- (BOOL)addAndCopyFiles:(NSArray *)files forKey:(NSString *)key
{
  NSEnumerator   *fileEnum = [files objectEnumerator];
  NSString       *file = nil;
  NSMutableArray *fileList = [[files mutableCopy] autorelease];
  PCFileManager  *fileManager = [projectManager fileManager];
  NSString       *directory = [self dirForCategoryKey:key];

  // Validate files
  while ((file = [fileEnum nextObject]))
    {
      if (![self doesAcceptFile:file forKey:key])
	{
	  [fileList removeObject:file];
	}
    }

  // Copy files
  if (![key isEqualToString:PCLibraries]) // Don't copy libraries
    {
      if (![fileManager copyFiles:fileList intoDirectory:directory])
	{
	  NSRunAlertPanel(@"Alert",
			  @"Error adding files to project %@!",
			  @"OK", nil, nil, projectName);
	  return NO;
	}
    }

  // Add files to project
  [self addFiles:fileList forKey:key];
  
  return YES;
}

- (void)addFiles:(NSArray *)files forKey:(NSString *)type
{
  NSEnumerator   *enumerator = nil;
  NSString       *file = nil;
  NSString       *pFile = nil;
  NSArray        *types = [projectDict objectForKey:type];
  NSMutableArray *projectFiles = [NSMutableArray arrayWithArray:types];

  enumerator = [files objectEnumerator];
  while ((file = [enumerator nextObject]))
    {
      pFile = [self projectFileFromFile:file forKey:type];
      [projectFiles addObject:pFile];
    }

  [projectDict setObject:projectFiles forKey:type];

  [[NSNotificationCenter defaultCenter] 
    postNotificationName:PCProjectDictDidChangeNotification
                  object:self];
}

- (BOOL)removeFiles:(NSArray *)files forKey:(NSString *)key
{
  NSEnumerator   *enumerator = nil;
  NSString       *filePath = nil;
  NSString       *file = nil;
  NSMutableArray *projectFiles = nil;

  // Remove files from project
  projectFiles = [NSMutableArray arrayWithArray:[projectDict objectForKey:key]];
  enumerator = [files objectEnumerator];
  while ((file = [enumerator nextObject]))
    {
      [projectFiles removeObject:file];

      // Close editor
      filePath = [projectPath stringByAppendingPathComponent:file];
      [projectEditor closeEditorForFile:filePath];
    }

  [projectDict setObject:projectFiles forKey:key];

  [[NSNotificationCenter defaultCenter] 
    postNotificationName:PCProjectDictDidChangeNotification
                  object:self];

  return YES;
}

- (BOOL)renameFile:(NSString *)fromFile toFile:(NSString *)toFile
{
  NSFileManager *fm = [NSFileManager defaultManager];
  NSString      *selectedCategory = [self selectedRootCategory];
  NSString      *selectedCategoryKey = [self selectedRootCategoryKey];
  NSString      *fromPath = nil;
  NSString      *toPath = nil;
  NSMutableDictionary *_pDict = nil;
  NSString            *_file = nil;
  NSMutableArray      *_array = nil;
  BOOL                saveToFile = NO;

  fromPath = [[self dirForCategoryKey:selectedCategoryKey]
    stringByAppendingPathComponent:fromFile];
  toPath = [[self dirForCategoryKey:selectedCategoryKey]
    stringByAppendingPathComponent:toFile];

  NSLog(@"PCProject: move %@ to %@", fromPath, toPath);

  if ([fm movePath:fromPath toPath:toPath handler:nil] == YES)
    {
      if ([self isProjectChanged])
	{
	  // Project already has changes
	  saveToFile = YES;
	}

      // Make changes to projectDict
      [self removeFiles:[NSArray arrayWithObjects:fromFile,nil] 
 	         forKey:selectedCategoryKey];
      [self addFiles:[NSArray arrayWithObjects:toFile,nil] 
   	      forKey:selectedCategoryKey];

      // Put only this change to project file, leaving 
      // other changes in memory(projectDict)
      if (saveToFile)
	{
	  _file = [projectPath stringByAppendingPathComponent:@"PC.project"];
	  _pDict = [NSMutableDictionary dictionaryWithContentsOfFile:_file];
	  _array = [_pDict objectForKey:selectedCategoryKey];
	  [_array removeObject:fromFile];
	  [_array addObject:toFile];
	  [_pDict setObject:_array forKey:selectedCategoryKey];
	  [_pDict writeToFile:_file atomically:YES];
	}
      else
	{
	  [self save];
	}

      [projectBrowser setPathForFile:toFile category:selectedCategory];
    }

  return YES;
}

// ============================================================================
// ==== Project handling
// ============================================================================

- (BOOL)assignProjectDict:(NSDictionary *)aDict
{
  NSAssert(aDict,@"No valid project dictionary!");

  [projectDict autorelease];
  projectDict = [[NSMutableDictionary alloc] initWithDictionary:aDict];

  NSLog (@"PCProject assignProjectDict");

  [self setProjectName:[projectDict objectForKey:PCProjectName]];
  [self writeMakefile];

  // Notify on dictionary changes. Update the interface and so on.
  [[NSNotificationCenter defaultCenter] 
    postNotificationName:PCProjectDictDidChangeNotification 
                  object:self];

  return YES;
}

- (NSDictionary *)projectDict
{
  return (NSDictionary *)projectDict;
}

- (void)setProjectPath:(NSString *)aPath
{
    [projectPath autorelease];
    projectPath = [aPath copy];
}

- (NSString *)projectPath
{
    return projectPath;
}

- (NSArray *)rootKeys
{
  // e.g. CLASS_FILES
  return rootKeys;
}

- (NSArray *)rootCategories
{
  // e.g. Classes
  return rootCategories;
}

- (NSDictionary *)rootEntries
{
  return rootEntries;
}

// Category is the name we see in project browser, e.g.
// Classes. 
// Key is the uppercase names which are located in PC.roject, e.g.
// CLASS_FILES
- (NSString *)keyForCategory:(NSString *)category
{
  int index = [rootCategories indexOfObject:category];

  return [rootKeys objectAtIndex:index];
}

- (NSString *)categoryForKey:(NSString *)key
{
  return [rootEntries objectForKey:key];
}

- (BOOL)save
{
  NSString *file = [projectPath stringByAppendingPathComponent:@"PC.project"];
  NSString       *backup = [file stringByAppendingPathExtension:@"backup"];
  NSFileManager  *fm = [NSFileManager defaultManager];
  NSUserDefaults *defs = [NSUserDefaults standardUserDefaults];
  NSString       *keepBackup = [defs objectForKey:KeepBackup];
  BOOL           shouldKeep = [keepBackup isEqualToString:@"YES"];
  int            spCount = [loadedSubprojects count];
  int            i;

  for (i = 0; i < spCount; i++)
    {
      [[loadedSubprojects objectAtIndex:i] save];
    }

  if (shouldKeep == YES && [fm isWritableFileAtPath:backup])
    {
      if (![fm removeFileAtPath:backup handler:nil])
	{
	  NSRunAlertPanel(@"Save project",
			  @"Error removing the old project backup!",
			  @"OK",nil,nil);
	  return NO;
	}
    }

  // Save backup
  if (shouldKeep && [fm isReadableFileAtPath:file]) 
    {
      if ([fm copyPath:file toPath:backup handler:nil] == NO)
	{
	  NSRunAlertPanel(@"Save project",
			  @"Error when saving project backup file!",
			  @"OK",nil,nil);
	  return NO;
	}
    }

  // Save project file
  [projectDict setObject:[[NSCalendarDate date] description]
                  forKey:PCLastEditing];
  if ([projectDict writeToFile:file atomically:YES] == NO)
    {
      return NO;
    }
  [[NSNotificationCenter defaultCenter] 
    postNotificationName:PCProjectDictDidSaveNotification 
                  object:self];

  // Save GNUmakefile
  if ([self writeMakefile] == NO)
    {
      NSRunAlertPanel(@"Save project",
		      @"Error when writing makefile for project %@",
		      @"OK",nil,nil,projectName);
      return NO;
    }

  return YES;
}

- (BOOL)saveAt:(NSString *)projPath
{
  return NO;
}

- (BOOL)writeSpecFile
{
  NSString *name = [projectDict objectForKey:PCProjectName];
  NSString *specInPath = [projectPath stringByAppendingPathComponent:name];
  NSMutableString *specIn = [NSMutableString string];

  if( [[projectDict objectForKey:PCRelease] intValue] < 1 )
    {
      NSRunAlertPanel(@"Spec Input File Creation!",
		      @"The Release entry seems to be wrong, please fix it!",
		      @"OK",nil,nil);
      return NO;
    }

  specInPath = [specInPath stringByAppendingPathExtension:@"spec.in"];

  [specIn appendString:@"# Automatically generated by ProjectCenter.app\n"];
  [specIn appendString:@"#\nsummary: "];
  [specIn appendString:[projectDict objectForKey:PCSummary]];
  [specIn appendString:@"\nRelease: "];
  [specIn appendString:[projectDict objectForKey:PCRelease]];
  [specIn appendString:@"\nCopyright: "];
  [specIn appendString:[projectDict objectForKey:PCCopyright]];
  [specIn appendString:@"\nGroup: "];
  [specIn appendString:[projectDict objectForKey:PCGroup]];
  [specIn appendString:@"\nSource: "];
  [specIn appendString:[projectDict objectForKey:PCSource]];
  [specIn appendString:@"\n\n%description\n\n"];
  [specIn appendString:[projectDict objectForKey:PCDescription]];

  return [specIn writeToFile:specInPath atomically:YES];
}

- (BOOL)isValidDictionary:(NSDictionary *)aDict
{
  NSString     *_file;
  NSString     *key;
  Class        projClass = [self builderClass];
  NSDictionary *origin;
  NSArray      *keys;
  NSEnumerator *enumerator;

  _file = [[NSBundle bundleForClass:projClass] pathForResource:@"PC"
                                                        ofType:@"project"];

  origin = [NSMutableDictionary dictionaryWithContentsOfFile:_file];
  keys   = [origin allKeys];

  enumerator = [keys objectEnumerator];
  while ((key = [enumerator nextObject]))
    {
      if ([aDict objectForKey:key] == nil)
	{
	  return NO;
	}
    }

  return YES;
}

- (void)updateProjectDict
{
  Class        projClass = [self builderClass];
  NSString     *_file;
  NSString     *key;
  NSDictionary *origin;
  NSArray      *keys;
  NSEnumerator *enumerator;
  BOOL         projectHasChanged = NO;

  _file = [[NSBundle bundleForClass:projClass] pathForResource:@"PC"
                                                        ofType:@"project"];

  origin = [NSMutableDictionary dictionaryWithContentsOfFile:_file];
  keys   = [origin allKeys];

  enumerator = [keys objectEnumerator];
  while ((key = [enumerator nextObject]))
    {
      if ([projectDict objectForKey:key] == nil)
	{
	  [projectDict setObject:[origin objectForKey:key] forKey:key];
	  projectHasChanged = YES;

/*	  NSRunAlertPanel(@"New Project Key!",
			  @"The key '%@' has been added.",
			  @"OK",nil,nil,key);*/
	}
    }

  if (projectHasChanged == YES)
    {
      [[NSNotificationCenter defaultCenter] 
	postNotificationName:PCProjectDictDidChangeNotification 
	              object:self];
    }
}

- (void)validateProjectDict
{
  if ([self isValidDictionary:projectDict] == NO)
    {
      int ret = NSRunAlertPanel(@"Attention!", 
				@"The project file lacks some entries\nUpdate it automatically?", 
				@"Update",@"Leave",nil);

      if (ret == NSAlertDefaultReturn)
	{
	  [self updateProjectDict];
	  [self save];

	  NSRunAlertPanel(@"Project updated!", 
			  @"The project file has been updated successfully!\nPlease make sure that all new project keys contain valid entries!", 
			  @"OK",nil,nil);
	}
    }
}

// ============================================================================
// ==== Subprojects
// ============================================================================

- (NSArray *)loadedSubprojects
{
  return loadedSubprojects;
}

- (PCProject *)activeSubproject
{
  return activeSubproject;
}

- (BOOL)isSubproject
{
  return isSubproject;
}

- (void)setIsSubproject:(BOOL)yn
{
  isSubproject = yn;
}

- (PCProject *)superProject
{
  return superProject;
}

- (void)setSuperProject:(PCProject *)project
{
  if (superProject != nil)
    {
      return;
    }

  ASSIGN(superProject, project);

  // Assigning releases left part
  ASSIGN(projectBrowser,[project projectBrowser]);
  ASSIGN(projectHistory,[project projectHistory]);
  ASSIGN(projectEditor,[project projectEditor]);
  ASSIGN(projectWindow,[project projectWindow]);
}

- (PCProject *)subprojectWithName:(NSString *)name
{
  int       count = [loadedSubprojects count];
  int       i;
  PCProject *sp = nil;
  NSString  *spName = nil;
  NSString  *spFile = nil;

  // Subproject in project but not loaded
  if ([[projectDict objectForKey:PCSubprojects] containsObject:name])
    {
      // Search for subproject with name in subprojects array
      for (i = 0; i < count; i++)
	{
	  sp = [loadedSubprojects objectAtIndex:i];
	  spName = [sp projectName];
	  if ([spName isEqualToString:name])
	    {
	      break;
	    }
	  sp = nil;
	}

      // Subproject not found in array, load subproject
      if (sp == nil)
	{
	  spFile = [projectPath stringByAppendingPathComponent:name];
	  spFile = [spFile stringByAppendingPathExtension:@"subproj"];
	  spFile = [spFile stringByAppendingPathComponent:@"PC.project"];
	  sp = [projectManager loadProjectAt:spFile];
	  [sp setIsSubproject:YES];
	  [sp setSuperProject:self];
	  [loadedSubprojects addObject:sp];
	}
    }
  
  return sp;
}


- (void)addSubproject:(PCProject *)aSubproject
{
  NSMutableArray *_subprojects;

  _subprojects = [NSMutableArray 
    arrayWithArray:[projectDict objectForKey:PCSubprojects]];

  [_subprojects addObject:[aSubproject projectName]];
  [loadedSubprojects addObject:aSubproject];
  [self setProjectDictObject:_subprojects forKey:PCSubprojects];
}

- (void)newSubprojectNamed:(NSString *)aName
{
}

- (void)removeSubproject:(PCProject *)aSubproject
{
}

@end

@implementation PCProject (CategoryPaths)

- (NSArray *)contentAtCategoryPath:(NSString *)categoryPath
{
  NSString *key = [self keyForCategoryPath:categoryPath];
  NSArray  *pathArray = nil;

  pathArray = [categoryPath componentsSeparatedByString:@"/"];

  if ([pathArray count] == 2)
    {
      [projectManager setActiveProject:self];
      activeSubproject = nil;
    }

  if ([categoryPath isEqualToString:@""] || [categoryPath isEqualToString:@"/"])
    {
      return rootCategories;
    }
  else if ([key isEqualToString:PCSubprojects])
    {
      PCProject      *_subproject = nil;
      NSString       *spCategoryPath = nil;
      NSMutableArray *mCategoryPath = nil;

      mCategoryPath = [pathArray mutableCopy];
//      NSLog(@"1. mCategoryPath: %@", mCategoryPath);

//      NSLog(@"path: %@ array count: %i", categoryPath, [pathArray count]);
      if ([pathArray count] == 2)
	{ // Click on "/Subprojects"
	  return [projectDict objectForKey:PCSubprojects];
	}
      else if ([pathArray count] > 2)
	{ // CLick on "/Subprojects/Name.subproj+"
	  _subproject = [self 
	    subprojectWithName:[pathArray objectAtIndex:2]];

	  [projectManager setActiveProject:_subproject];
	  activeSubproject = _subproject;

	  [mCategoryPath removeObjectAtIndex:1];
	  [mCategoryPath removeObjectAtIndex:1];
//	  NSLog(@"2. mCategoryPath: %@", mCategoryPath);

     	  spCategoryPath = [mCategoryPath componentsJoinedByString:@"/"];
	  
/*	  NSLog(@"%@: retreiving content from %@ subproject\n> path: %@", 
		projectName, [_subproject projectName], spCategoryPath);*/

	  return [_subproject contentAtCategoryPath:spCategoryPath];
	}
    }

  return [projectDict objectForKey:key];
}

- (BOOL)hasChildrenAtCategoryPath:(NSString *)categoryPath
{
  NSString       *listEntry = nil;
/*  NSString       *key = nil;
  NSMutableArray *pathArray = nil;
  NSString       *path = nil;
  PCProject      *_subproject = nil;

  pathArray = [[categoryPath componentsSeparatedByString:@"/"] mutableCopy];

  NSLog(@"PCP: hasChildren %@", categoryPath);
  if ([categoryPath isEqualToString:@""] 
      || [categoryPath isEqualToString:@"/"])
    {
      return NO;
    }*/

  listEntry = [[categoryPath componentsSeparatedByString:@"/"] lastObject];
  if ([rootCategories containsObject:listEntry]
      || [[projectDict objectForKey:PCSubprojects] containsObject:listEntry])
    {
      return YES;
    }
  
/*  key = [self keyForCategoryPath:categoryPath];
  if ([key isEqualToString:PCSubprojects])
    {
      NSLog(@"PCP: has choldren subprojects");
      _subproject = [self subprojectWithName:[pathArray objectAtIndex:2]];

      [pathArray removeObjectAtIndex:1];
      [pathArray removeObjectAtIndex:1];
      path = [pathArray componentsJoinedByString:@"/"];
      return [_subproject hasChildrenAtCategoryPath:path];
    }*/

  return NO;
}

- (NSString *)categoryForCategoryPath:(NSString *)categoryPath
{
  NSString *category = nil;
  
  if (![categoryPath isEqualToString:@"/"] 
      && ![categoryPath isEqualToString:@""])
    {
      category = [[categoryPath componentsSeparatedByString:@"/"] 
	objectAtIndex:1];
    }

  return category;
}

- (NSString *)keyForCategoryPath:(NSString *)categoryPath
{
  NSString *category = nil;
  NSString *key = nil;

  if (![categoryPath isEqualToString:@"/"] 
      && ![categoryPath isEqualToString:@""])
    {
      category = 
	[[categoryPath componentsSeparatedByString:@"/"] objectAtIndex:1];
      key = [self keyForCategory:category];
    }
  
  return key;
}

@end

