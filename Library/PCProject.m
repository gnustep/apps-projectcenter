/*
   GNUstep ProjectCenter - http://www.gnustep.org

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

#include "PCFileManager.h"
#include "PCProject.h"
#include "PCDefines.h"

#include "PCProjectWindow.h"
#include "PCProjectBrowser.h"
#include "PCProjectLoadedFiles.h"

#include "PCProjectInspector.h"
#include "PCProjectBuilder.h"
#include "PCProjectEditor.h"
#include "PCProjectLauncher.h"
#include "PCEditor.h"

#include "PCLogController.h"

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

      PCLogStatus(self, @"initWithProjectDictionary");

      if (![self assignProjectDict:dict])
	{
	  PCLogError(self, @"could not load the project...");
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

  if (isSubproject)
    {
      return;
    }

  if (!projectBrowser && !isSubproject)
    {
      projectBrowser = [[PCProjectBrowser alloc] initWithProject:self];
    }

  if (!projectLoadedFiles && !isSubproject)
    {
      projectLoadedFiles = [[PCProjectLoadedFiles alloc] initWithProject:self];
    }

  if (!projectEditor && !isSubproject)
    {
      projectEditor = [[PCProjectEditor alloc] initWithProject:self];
    }
    
  if (!projectWindow && !isSubproject)
    {
      projectWindow = [[PCProjectWindow alloc] initWithProject:self];
    }
}

- (BOOL)close:(id)sender
{
//  PCLogInfo(self, @"Closing %@ project", projectName);
  
  // Save visible windows and panels positions to project dictionary
  if (isSubproject == NO)
    {
      [self saveProjectWindowsAndPanels];
      [projectBrowser setPath:@"/"];
      [projectManager setActiveProject:self];
    }
  
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

- (BOOL)saveProjectWindowsAndPanels
{
  NSUserDefaults      *ud = [NSUserDefaults standardUserDefaults];
  NSMutableDictionary *windows = [NSMutableDictionary dictionary];
  NSString            *projectFile = nil;
  NSMutableDictionary *projectFileDict = nil;

  projectFile = [projectPath stringByAppendingPathComponent:@"PC.project"];
  projectFileDict = [NSMutableDictionary 
    dictionaryWithContentsOfFile:projectFile];

  // Project Window
  [windows setObject:[projectWindow stringWithSavedFrame]
              forKey:@"ProjectWindow"];
  if ([projectWindow isToolbarVisible] == YES)
    {
      [windows setObject:[NSString stringWithString:@"YES"]
	          forKey:@"ShowToolbar"];
    }
  else
    {
      [windows setObject:[NSString stringWithString:@"NO"]
                  forKey:@"ShowToolbar"];
    }

  // Write to file and exit if prefernces wasn't set to save panels
  if (![[ud objectForKey:RememberWindows] isEqualToString:@"YES"])
    {
      [projectFileDict setObject:windows forKey:@"PC_WINDOWS"];
      [projectFileDict writeToFile:projectFile atomically:YES];
      return YES;
    }


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
  if (projectLoadedFiles && [[projectManager loadedFilesPanel] isVisible])
    {
      [windows 
	setObject:[[projectManager loadedFilesPanel] stringWithSavedFrame]
           forKey:@"LoadedFiles"];
    }
  else
    {
      [windows removeObjectForKey:@"LoadedFiles"];
    }

  // Set to project dict for case if project changed
  // Don't notify about projectDict changes
  [projectDict setObject:windows forKey:@"PC_WINDOWS"];

  // Now save it directly to PC.project file
  [projectFileDict setObject:windows forKey:@"PC_WINDOWS"];
  [projectFileDict writeToFile:projectFile atomically:YES];
  
//  PCLogInfo(self, @"Windows and geometries saved");

  return YES;
}

- (void)dealloc
{
#ifdef DEVELOPMENT
  NSLog (@"PCProject %@: dealloc", projectName);
#endif
  
  [[NSNotificationCenter defaultCenter] removeObserver:self];

  RELEASE(projectName);
  RELEASE(projectPath);
  RELEASE(projectDict);
  RELEASE(loadedSubprojects);
  RELEASE(buildOptions);

  // Initialized in -setProjectManager: of project and
  // in setSuperProject: of subproject
  RELEASE(projectWindow);
  RELEASE(projectBrowser);
  RELEASE(projectLoadedFiles);
  RELEASE(projectEditor);
  if (projectBuilder) RELEASE(projectBuilder);
  if (projectLauncher) RELEASE(projectLauncher);

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

- (PCProjectWindow *)projectWindow
{
  return projectWindow;
}

- (PCProjectBrowser *)projectBrowser
{
  return projectBrowser;
}

- (PCProjectLoadedFiles *)projectLoadedFiles
{
  if (!projectLoadedFiles && !isSubproject)
    {
      projectLoadedFiles = [[PCProjectLoadedFiles alloc] initWithProject:self];
    }

  return projectLoadedFiles;
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

- (void)setProjectDictObject:(id)object forKey:(NSString *)key notify:(BOOL)yn
{
  id                  currentObject = [projectDict objectForKey:key];
  NSMutableDictionary *notifObject = [NSMutableDictionary dictionary];

  if ([object isKindOfClass:[NSString class]]
      && [currentObject isEqualToString:object])
    {
      return;
    }

  [projectDict setObject:object forKey:key];

  // Send in notification project itself and project dictionary object key 
  // that was changed
  [notifObject setObject:self forKey:@"Project"];
  [notifObject setObject:key forKey:@"Attribute"];

  if (yn == YES)
    {
      [[NSNotificationCenter defaultCenter] 
	postNotificationName:PCProjectDictDidChangeNotification
                      object:notifObject];
    }
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

- (BOOL)isProjectChanged
{
  return [projectWindow isDocumentEdited];
}

// ============================================================================
// ==== Can be overriden
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

- (BOOL)canHavePublicHeaders
{
  return NO;
}

- (NSArray *)publicHeaders
{
  return nil;
}

- (void)setHeaderFile:(NSString *)file public:(BOOL)yn
{
}

- (void)setLocalizableFile:(NSString *)file public:(BOOL)yn
{
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

- (NSArray *)fileTypesForCategoryKey:(NSString *)key 
{
  if ([key isEqualToString:PCClasses])
    {
      return [NSArray arrayWithObjects:@"m",nil];
    }
  else if ([key isEqualToString:PCHeaders])
    {
      return [NSArray arrayWithObjects:@"h",nil];
    }
  else if ([key isEqualToString:PCOtherSources])
    {
      return [NSArray arrayWithObjects:@"c",@"C",@"m",nil];
    }
  else if ([key isEqualToString:PCInterfaces])
    {
      return [NSArray arrayWithObjects:@"gmodel",@"gorm",nil];
    }
  else if ([key isEqualToString:PCImages])
    {
      return [NSImage imageFileTypes];
    }
  else if ([key isEqualToString:PCSubprojects])
    {
      return [NSArray arrayWithObjects:@"subproj",nil];
    }
  else if ([key isEqualToString:PCLibraries])
    {
      return [NSArray arrayWithObjects:@"so",@"a",@"lib",nil];
    }

  return nil;
}

- (NSString *)categoryKeyForFileType:(NSString *)type
{
  NSEnumerator *keysEnum = [rootKeys objectEnumerator];
  NSString     *key = nil;

  while ((key = [keysEnum nextObject]))
    {
      if ([[self fileTypesForCategoryKey:key] containsObject:type])
	{
	  return key;
	}
    }

  return nil;
}

- (NSString *)dirForCategoryKey:(NSString *)key 
{
  if ([key isEqualToString:PCInterfaces] 
      || [key isEqualToString:PCImages]
      || [key isEqualToString:PCOtherResources]
      || [key isEqualToString:PCDocuFiles])
    {
      return [projectPath stringByAppendingPathComponent:@"Resources"];
    }

  return projectPath;
}

- (NSString *)complementaryTypeForType:(NSString *)type
{
  if ([type isEqualToString:@"m"] || [type isEqualToString:@"c"])
    {
      return [NSString stringWithString:@"h"];
    }
  else if ([type isEqualToString:@"h"])
    {
      return [NSString stringWithString:@"m"];
    }

  return nil;
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
  NSString        *path = nil;
  NSRange         pathRange;
  NSRange         slashRange;

  path = [file stringByDeletingLastPathComponent];
  pathRange = [path rangeOfString:projectPath];

  if (pathRange.length)
    {
      slashRange.location = pathRange.length;
      slashRange.length = 1;
    }
  
  if (pathRange.length 
      && slashRange.location != [path length]
      && [[path substringWithRange:slashRange] isEqualToString:@"/"])
    {
      pathRange.length++;
      projectFile = [NSMutableString stringWithString:file];
      [projectFile deleteCharactersInRange:pathRange];
    }
  else
    {
      projectFile = [NSMutableString stringWithString:[file lastPathComponent]];
    }

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
  NSString      *pFile = [self projectFileFromFile:file forKey:type];
  NSArray       *sourceKeys = [self sourceFileKeys];
  NSArray       *resourceKeys = [self resourceFileKeys];
  NSEnumerator  *keyEnum = nil;
  NSString      *key = nil;
  NSArray       *projectFiles = nil;

  if ([sourceKeys containsObject:type])
    {
      keyEnum = [sourceKeys objectEnumerator];
    }
  else if ([resourceKeys containsObject:type])
    {
      keyEnum = [resourceKeys objectEnumerator];
    }
  else
    {
      return YES;
    }

  while ((key = [keyEnum nextObject]))
    {
      projectFiles = [projectDict objectForKey:key];
      NSLog(@"KEY: %@ Files: %@ file: %@", key, projectFiles, pFile);
      if ([projectFiles containsObject:pFile])
	{
	  return NO;
	}
    }

  return YES;
}

- (BOOL)addAndCopyFiles:(NSArray *)files forKey:(NSString *)key
{
  NSEnumerator   *fileEnum = [files objectEnumerator];
  NSString       *file = nil;
  NSMutableArray *fileList = [[files mutableCopy] autorelease];
  NSString       *complementaryType = nil;
  NSString       *complementaryKey = nil;
  NSString       *complementaryDir = nil;
  NSMutableArray *complementaryFiles = [NSMutableArray array];
  PCFileManager  *fileManager = [projectManager fileManager];
  NSString       *directory = [self dirForCategoryKey:key];

  complementaryType = [self 
    complementaryTypeForType:[[files objectAtIndex:0] pathExtension]];
  if (complementaryType)
    {
      complementaryKey = [self categoryKeyForFileType:complementaryType];
      complementaryDir = [self dirForCategoryKey:complementaryKey];
    }
    
//  PCLogInfo(self, @"{%@} {addAndCopyFiles} %@", projectName, fileList);

  // Validate files
  while ((file = [fileEnum nextObject]))
    {
      if (![self doesAcceptFile:file forKey:key])
	{
	  [fileList removeObject:file];
	}
      else if (complementaryType != nil)
	{
	  NSString *compFile = nil;

	  compFile = [[file stringByDeletingPathExtension] 
	    stringByAppendingPathExtension:complementaryType];
	  if ([[NSFileManager defaultManager] fileExistsAtPath:compFile]
	      && [self doesAcceptFile:compFile forKey:complementaryKey])
	    {
	      [complementaryFiles addObject:compFile];
	    }
	}
    }

//  PCLogInfo(self, @"{addAndCopyFiles} %@", fileList);

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

//      PCLogInfo(self, @"Complementary files: %@", complementaryFiles);
      // Complementaries
      if (![fileManager copyFiles:complementaryFiles 
	            intoDirectory:complementaryDir])
	{
	  NSRunAlertPanel(@"Alert",
			  @"Error adding complementary files to project %@!",
			  @"OK", nil, nil, projectName);
	  return NO;
	}
    }

  if ([complementaryFiles count] > 0)
    {
      [self addFiles:complementaryFiles forKey:complementaryKey notify:NO];
    }
  // Add files to project
  [self addFiles:fileList forKey:key notify:YES];

  return YES;
}

- (void)addFiles:(NSArray *)files forKey:(NSString *)type notify:(BOOL)yn
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

  [self setProjectDictObject:projectFiles forKey:type notify:yn];
}

- (BOOL)removeFiles:(NSArray *)files forKey:(NSString *)key notify:(BOOL)yn
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
      if ([key isEqualToString:PCSubprojects])
	{
	  [self removeSubprojectWithName:file];
	}
      [projectFiles removeObject:file];

      // Close editor
      filePath = [projectPath stringByAppendingPathComponent:file];
      [projectEditor closeEditorForFile:filePath];
    }

  [self setProjectDictObject:projectFiles forKey:key notify:yn];

  return YES;
}

- (BOOL)renameFile:(NSString *)fromFile toFile:(NSString *)toFile
{
  NSFileManager       *fm = [NSFileManager defaultManager];
  NSString            *selectedCategory = nil;
  NSString            *selectedCategoryKey = nil;
  NSString            *fromPath = nil;
  NSString            *toPath = nil;
  NSMutableDictionary *_pDict = nil;
  NSString            *_file = nil;
  NSMutableArray      *_array = nil;
  BOOL                saveToFile = NO;
  int                 index = 0;
  PCEditor            *_editor = nil;
  NSString            *_editorPath = nil;
  NSString            *_editorCategory = nil;
  
  selectedCategory = [projectBrowser nameOfSelectedCategory];
  selectedCategoryKey = [self keyForCategory:selectedCategory];

  fromPath = [[self dirForCategoryKey:selectedCategoryKey]
    stringByAppendingPathComponent:fromFile];
  toPath = [[self dirForCategoryKey:selectedCategoryKey]
    stringByAppendingPathComponent:toFile];

  if ([fm fileExistsAtPath:toPath])
    {
      switch (NSRunAlertPanel(@"Rename file",
       			      @"File \"%@\" already exist",
			      @"Overwrite file",@"Cancel",nil, toFile))
	{
	case NSAlertDefaultReturn: // Overwrite
	  if ([fm removeFileAtPath:toPath handler:nil] == NO)
	    {
	      return NO;
	    }
	  break;
	case NSAlertAlternateReturn: // Stop rename
	  return NO;
	  break;

	}
    }

/*  PCLogInfo(self, @"{%@} move %@ to %@ category: %@", 
	    projectName, fromPath, toPath, selectedCategory);*/

  if ([fm movePath:fromPath toPath:toPath handler:nil] == YES)
    {
      if ([self isProjectChanged])
	{
	  // Project already has changes
	  saveToFile = YES;
	}

      // Make changes to projectDict
      _array = [projectDict objectForKey:selectedCategoryKey];
      index = [_array indexOfObject:fromFile];
      [_array replaceObjectAtIndex:index withObject:toFile];

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
	
      // Set browser path to new file name
      [projectBrowser reloadLastColumnAndSelectFile:toFile];

      // Handle editor(if any) information
//      if ([[[_editor path] lastPathComponent] isEqualToString:fromFile])
      _editor = [projectEditor activeEditor];
      if (_editor)
	{
	  _editorPath = [_editor path];
	  _editorPath = [_editorPath stringByDeletingLastPathComponent];
	  _editorPath = [_editorPath stringByAppendingPathComponent:toFile];
	  [_editor setPath:_editorPath];

	  _editorCategory = [_editor categoryPath];
	  _editorCategory = [_editorCategory stringByDeletingLastPathComponent];
	  _editorCategory = [_editorCategory 
	    stringByAppendingPathComponent:toFile];
	  [_editor setCategoryPath:_editorCategory];
	}
    }

  return YES;
}

// ============================================================================
// ==== Project handling
// ============================================================================

- (BOOL)assignProjectDict:(NSDictionary *)aDict
{
  NSAssert(aDict,@"No valid project dictionary!");

  [projectDict release];
  projectDict = [[NSMutableDictionary alloc] initWithDictionary:aDict];

  PCLogStatus(self, @"assignProjectDict");

  [self setProjectName:[projectDict objectForKey:PCProjectName]];
  [self writeMakefile];

  // Also notify on dictionary changes. Update the interface and so on.
  [projectDict setObject:[NSUserDefaults userLanguages] forKey:PCUserLanguages];

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

// Category - the name we see in project browser, e.g. "Classes"
// Key - the uppercase names located in PC.roject, e.g. "CLASS_FILES"
- (NSString *)keyForCategory:(NSString *)category
{
  int index = -1;

  if (![rootCategories containsObject:category])
    {
      return nil;
    }
    
  index = [rootCategories indexOfObject:category];
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

  // Remove backup file if exists
  if ([fm fileExistsAtPath:backup] && ![fm removeFileAtPath:backup handler:nil])
    {
      NSRunAlertPanel(@"Save project",
		      @"Error removing the old project backup!",
		      @"OK",nil,nil);
      return NO;
    }

  // Save backup
  if (shouldKeep == YES && [fm isReadableFileAtPath:file]) 
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
  NSString     *_file = nil;
  NSString     *key = nil;
  NSDictionary *origin = nil;
  NSArray      *keys = nil;
  NSEnumerator *enumerator = nil;

  _file = [[NSBundle bundleForClass:projClass] pathForResource:@"PC"
                                                        ofType:@"project"];

  origin = [NSMutableDictionary dictionaryWithContentsOfFile:_file];
  keys   = [origin allKeys];

  enumerator = [keys objectEnumerator];
  while ((key = [enumerator nextObject]))
    {
      if ([projectDict objectForKey:key] == nil)
	{
	  // Doesn't call setProjectDictObject:forKey for opimizations
	  [projectDict setObject:[origin objectForKey:key] forKey:key];
	}
    }

  [self save];
}

- (void)validateProjectDict
{
  if ([self isValidDictionary:projectDict] == NO)
    {
      [self updateProjectDict];

      NSRunAlertPanel(@"Project updated!", 
		      @"The project file was converted from previous version!\nPlease make sure that every project attribute contain valid values!", 
		      @"OK",nil,nil);
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
  ASSIGN(projectLoadedFiles,[project projectLoadedFiles]);
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
/*      PCLogInfo(self, @"{%@}Searching for loaded subproject: %@",
		projectName, name);*/
      // Search for subproject with name among loaded subprojects 
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

      // Subproject not found in array, load it
      if (sp == nil)
	{
	  spFile = [projectPath stringByAppendingPathComponent:name];
	  spFile = [spFile stringByAppendingPathExtension:@"subproj"];
	  spFile = [spFile stringByAppendingPathComponent:@"PC.project"];
/*	  PCLogInfo(self, @"Not found! Load subproject: %@ at path: %@",
		    name, spFile);*/
	  sp = [projectManager loadProjectAt:spFile];
	  if (sp)
	    {
	      [sp setIsSubproject:YES];
	      [sp setSuperProject:self];
	      [sp setProjectManager:projectManager];
	      [loadedSubprojects addObject:sp];
	    }
	}
    }
  
  return sp;
}

- (void)addSubproject:(PCProject *)aSubproject
{
  NSMutableArray *_subprojects;

  if (!aSubproject)
    {
      return;
    }

  _subprojects = [NSMutableArray 
    arrayWithArray:[projectDict objectForKey:PCSubprojects]];

  [_subprojects addObject:[aSubproject projectName]];
  [loadedSubprojects addObject:aSubproject];
  [self setProjectDictObject:_subprojects forKey:PCSubprojects notify:YES];
}

- (void)addSubprojectWithName:(NSString *)name
{
  NSMutableArray *_subprojects = nil;

  if (!name)
    {
      return;
    }

  _subprojects = [NSMutableArray 
    arrayWithArray:[projectDict objectForKey:PCSubprojects]];
  [_subprojects addObject:name];
  [self setProjectDictObject:_subprojects forKey:PCSubprojects notify:YES];
}

- (BOOL)removeSubprojectWithName:(NSString *)subprojectName
{
  NSString *extension = [subprojectName pathExtension];
  NSString *sName = subprojectName;
  
  if (extension && [extension isEqualToString:@"subproj"])
    {
      sName = [subprojectName stringByDeletingPathExtension];
    }

  return [self removeSubproject:[self subprojectWithName:sName]];
}

- (BOOL)removeSubproject:(PCProject *)aSubproject
{
  if ([loadedSubprojects containsObject:aSubproject])
    {
      [aSubproject close:self];
      [loadedSubprojects removeObject:aSubproject];
    }

  return YES;
}

@end

@implementation PCProject (CategoryPaths)
// TODO: Think about moving all category related methods into PCProjectBrowser

- (NSArray *)contentAtCategoryPath:(NSString *)categoryPath
{
  NSString *key = [self keyForRootCategoryInCategoryPath:categoryPath];
  NSArray  *pathArray = nil;

  pathArray = [categoryPath componentsSeparatedByString:@"/"];

/*  PCLogInfo(self, @"{%@}{contentAtCategoryPath:} %@",
	    projectName, categoryPath);*/

  // Click on /Category
  if ([pathArray count] == 2)
    {
      if ([projectManager activeProject] != self)
	{
	  [projectManager setActiveProject:self];
	}
      activeSubproject = nil;
    }

  if ([categoryPath isEqualToString:@""] || [categoryPath isEqualToString:@"/"])
    {
      if ([projectManager activeProject] != self)
	{
	  [projectManager setActiveProject:self];
	}
      return rootCategories;
    }
  else if ([key isEqualToString:PCSubprojects] && [pathArray count] > 2)
    { // Click on "/Subprojects/Name+"
      PCProject      *_subproject = nil;
      NSString       *spCategoryPath = nil;
      NSMutableArray *mCategoryPath = [NSMutableArray arrayWithArray:pathArray];

      _subproject = [self subprojectWithName:[pathArray objectAtIndex:2]];
      activeSubproject = _subproject;

      [mCategoryPath removeObjectAtIndex:1];
      [mCategoryPath removeObjectAtIndex:1];

      spCategoryPath = [mCategoryPath componentsJoinedByString:@"/"];

      return [_subproject contentAtCategoryPath:spCategoryPath];
    }

  return [projectDict objectForKey:key];
}

- (BOOL)hasChildrenAtCategoryPath:(NSString *)categoryPath
{
  NSString  *listEntry = nil;
  PCProject *activeProject = [projectManager activeProject];

  if (self != activeProject)
    {
      return [activeProject hasChildrenAtCategoryPath:categoryPath];
    }

  listEntry = [[categoryPath componentsSeparatedByString:@"/"] lastObject];
  if ([rootCategories containsObject:listEntry])
    {
      return YES;
    }
    
  if ([[projectDict objectForKey:PCSubprojects] containsObject:listEntry])
      {
	return YES;
      }
  
  return NO;
}

- (NSString *)rootCategoryForCategoryPath:(NSString *)categoryPath
{
  NSArray *pathComponents = nil;

  if ([categoryPath isEqualToString:@"/"] || [categoryPath isEqualToString:@""])
    {
      return nil;
    }
    
  pathComponents = [categoryPath componentsSeparatedByString:@"/"];

  return [pathComponents objectAtIndex:1];
}

/*- (NSString *)categoryForCategoryPath:(NSString *)categoryPath
{
  NSString *category = nil;
  NSString *key = nil;
  NSArray  *pathComponents = nil;
  int      i = 0;

  category = [self rootCategoryForCategoryPath:categoryPath];
  if (category == nil)
    {
      return nil;
    }

  key = [self keyForCategory:category];
  pathComponents = [categoryPath componentsSeparatedByString:@"/"];

  if ([key isEqualToString:PCSubprojects])
    {
      // /Subprojects/Name/Classes/Class.m, should return Classes
      //  0  1           2    3       4
      // ("",Subprojects,Name,Classes,Class.m)
      //  0  1           2    3           4
      // ("",Subprojects,Name,Subprojects,Name)
      if ([pathComponents count] > 4 && activeSubproject)
	{ 
	  i = [pathComponents count] - 1;

	  for (; i >= 0; i--)
	    {
	      category = [pathComponents objectAtIndex:i];
	      if ([[activeSubproject rootCategories] containsObject:category])
		{
		  return category;
		}
	    }
	}
    }
  
  return category;
}*/

/*- (NSString *)keyForCategoryPath:(NSString *)categoryPath
{
  return [self keyForCategory:[self categoryForCategoryPath:categoryPath]];
}*/

- (NSString *)keyForRootCategoryInCategoryPath:(NSString *)categoryPath
{
  NSString *category = nil;
  NSString *key = nil;

  if (categoryPath == nil 
      || [categoryPath isEqualToString:@""]
      || [categoryPath isEqualToString:@"/"])
    {
      return nil;
    }

  category = [self rootCategoryForCategoryPath:categoryPath];
  key = [self keyForCategory:category];

/*  PCLogInfo(self, @"{%@}(keyForRootCategoryInCategoryPath): %@ key:%@", 
	    projectName, categoryPath, key);*/

  return key;
}

@end

