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
#include "PCEditorController.h"

NSString *ProjectDictDidSetNotification = @"ProjectDictDidSetNotification";
NSString *ProjectDictDidChangeNotification = @"ProjectDictDidChangeNotification";
NSString *ProjectDictDidSaveNotification = @"ProjectDictDidSaveNotification";

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
      projectWindow = [[PCProjectWindow alloc] initWithProject:self];

      projectBuilder = nil;
      projectLauncher = nil;

      editorController = [[PCEditorController alloc] init];
      [editorController setProject:self];
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

      if(![self assignProjectDict:dict])
	{
	  NSLog(@"<%@ %x>: could not load the project...",[self class],self);
	  [self autorelease];
	  return nil;
	}
    }

  return self;
}

- (void)setProjectManager:(PCProjectManager *)aManager
{
  projectManager = aManager;
}

- (PCProjectManager *)projectManager
{
  return projectManager;
}

- (void)close
{
  [editorController closeAllEditors];
  [projectManager closeProject:self];
}

- (void)dealloc
{
  NSLog (@"PCProject: dealloc");
  
  [[NSNotificationCenter defaultCenter] removeObserver:self];
  
  RELEASE(projectName);
  RELEASE(projectPath);
  RELEASE(projectDict);

  RELEASE(projectWindow);
  RELEASE(projectBrowser);

  if (projectHistory)  RELEASE(projectHistory);
  if (projectBuilder)  RELEASE(projectBuilder);
  if (projectLauncher) RELEASE(projectLauncher);
  if (projectEditor)   RELEASE(projectEditor);
  
  RELEASE(editorController);

  RELEASE(buildOptions);

  [super dealloc];
}

// ============================================================================
// ==== Accessor methods
// ============================================================================

- (PCProjectBrowser *)projectBrowser
{
  return projectBrowser;
}

- (PCProjectHistory *)projectHistory
{
  if (!projectHistory)
    {
      projectHistory = [[PCProjectHistory alloc] initWithProject:self];
    }

  return projectHistory;
}

- (PCProjectBuilder *)projectBuilder
{
  if (!projectBuilder)
    {
      projectBuilder = [[PCProjectBuilder alloc] initWithProject:self];
    }

  return projectBuilder;
}

- (PCProjectLauncher *)projectLauncher
{
  if (!projectLauncher)
    {
      projectLauncher = [[PCProjectLauncher alloc] initWithProject:self];
    }

  return projectLauncher;
}

- (PCProjectEditor *)projectEditor
{
  return projectEditor;
}

- (PCEditorController*)editorController
{
  return editorController;
}

- (NSString *)selectedRootCategory
{
  NSString *_path = [[self projectBrowser] pathOfSelectedFile];

  return [self projectKeyForKeyPath:_path];
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

// TEMP!
- (void)updateValuesFromProjectDict
{
}

- (void)createInspectors
{
}

- (NSView *)buildAttributesView
{
  return nil;
}

- (NSView *)projectAttributesView
{
  return nil;
}

- (NSView *)fileAttributesView
{
  return nil;
}

- (Class)builderClass
{
  return nil;
}

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

- (NSArray *)fileTypesForCategory:(NSString *)category
{
  return nil;
}

- (NSString *)dirForCategory:(NSString *)category
{
  return projectPath;
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

- (NSArray *)buildTargets
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

// ============================================================================
// ==== File Handling
// ============================================================================

- (void)browserDidClickFile:(NSString *)fileName category:(NSString*)c
{
  NSString *p = [[self projectPath] stringByAppendingPathComponent:fileName];
  PCEditor *e;

  // Set the name in the inspector
//  [fileNameField setStringValue:fileName];

  // Show the file in the internal editor!
  e = [editorController internalEditorForFile:p];

  if( e == nil )
    {
      NSLog(@"No editor for file '%@'...",p);
      return;
    }

  [self showEditorView:self];
  [e setCategory:c];
  [e showInProjectEditor:projectEditor];

  [projectWindow makeFirstResponder:(NSResponder*)[projectEditor editorView]];
}

- (void)browserDidDblClickFile:(NSString *)fileName category:(NSString*)c
{
  PCEditor *e;

  e = [editorController editorForFile:fileName];

  if (e)
    {
      [e setCategory:c];
      [e show];
    }
}

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
  NSString       *directory = [self dirForCategory:key];

  // Validate files
  while ((file = [fileEnum nextObject]))
    {
      if (![self doesAcceptFile:file forKey:key])
	{
	  [fileList removeObject:file];
	}
    }

  // Copy files
  if (![fileManager copyFiles:fileList intoDirectory:directory])
    {
      NSRunAlertPanel(@"Alert",
		      @"Error adding files to project %@!",
		      @"OK", nil, nil, projectName);
      return NO;
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
    postNotificationName:ProjectDictDidChangeNotification
                  object:self];
}

- (BOOL)removeFiles:(NSArray *)files forKey:(NSString *)key
{
  NSEnumerator   *enumerator = nil;
  NSString       *filePath = nil;
  NSString       *file = nil;
  NSMutableArray *projectFiles = nil;
  NSMutableArray *filesToRemove = [[files mutableCopy] autorelease];
  NSString       *mainNibFile = [projectDict objectForKey:PCMainInterfaceFile];

  if (!files || !key)
    {
      return NO;
    }

  // Check for main NIB files
  if ([key isEqualToString:PCInterfaces] && [files containsObject:mainNibFile])
    {
      int ret;
      ret = NSRunAlertPanel(@"Remove",
			    @"You've selected to remove main interface file.\nDo you still want to remove it?",
			    @"Remove", @"Leave", nil);
			    
      if (ret == NSAlertAlternateReturn) // Leave
	{
	  [filesToRemove removeObject:mainNibFile];
	}
    }

  // Remove files from project
  projectFiles = [NSMutableArray arrayWithArray:[projectDict objectForKey:key]];
  enumerator = [filesToRemove objectEnumerator];
  while ((file = [enumerator nextObject]))
    {
      [projectFiles removeObject:file];

      // Close editor
      filePath = [projectPath stringByAppendingPathComponent:file];
      [editorController closeEditorForFile:filePath];
    }

  [projectDict setObject:projectFiles forKey:key];

  [[NSNotificationCenter defaultCenter] 
    postNotificationName:ProjectDictDidChangeNotification
                  object:self];

  return YES;
}

- (void)renameFile:(NSString *)aFile
{
}

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
    postNotificationName:ProjectDictDidChangeNotification 
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

- (NSDictionary *)rootCategories
{
    return rootCategories;
}

- (BOOL)save
{
  NSString *file = [projectPath stringByAppendingPathComponent:@"PC.project"];
  NSString       *backup = [file stringByAppendingPathExtension:@"backup"];
  NSFileManager  *fm = [NSFileManager defaultManager];
  NSUserDefaults *defs = [NSUserDefaults standardUserDefaults];
  NSString       *keepBackup = [defs objectForKey:KeepBackup];
  BOOL           shouldKeep = [keepBackup isEqualToString:@"YES"];
  BOOL           ret = NO;

  if ( shouldKeep == YES && [fm isWritableFileAtPath:backup] )
    {
      ret = [fm removeFileAtPath:backup handler:nil];
      if( ret == NO ) {
	  NSRunAlertPanel(@"Attention!",
			  @"Could not remove the old project backup '%@'!",
			  @"OK",nil,nil,backup);
      }
    }

  if (shouldKeep && [fm isReadableFileAtPath:file]) 
    {
      ret = [fm copyPath:file toPath:backup handler:nil];
      if( ret == NO ) 
	{
	  NSRunAlertPanel(@"Attention!",
			  @"Could not save the project backup file '%@'!",
			  @"OK",nil,nil,file);
	}
    }

  ret = [projectDict writeToFile:file atomically:YES];
  if( ret == YES )
    {
      [[NSNotificationCenter defaultCenter] 
	postNotificationName:ProjectDictDidSaveNotification 
                      object:self];
    }

  [self writeMakefile];

  return ret;
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

// ============================================================================
// ==== Subprojects
// ============================================================================

- (NSArray *)subprojects
{
    return [projectDict objectForKey:PCSubprojects];
}

- (void)addSubproject:(PCProject *)aSubproject
{
}

- (PCProject *)superProject
{
    return nil;
}

- (PCProject *)rootProject
{
    return self;
}

- (void)newSubprojectNamed:(NSString *)aName
{
}

- (void)removeSubproject:(PCProject *)aSubproject
{
}

- (BOOL)isSubProject
{
    return NO;
}

// ============================================================================
// ==== Project Handling
// ============================================================================

- (BOOL)isValidDictionary:(NSDictionary *)aDict
{
    NSString *_file;
    NSString *key;
    Class projClass = [self builderClass];
    NSDictionary *origin;
    NSArray *keys;
    NSEnumerator *enumerator;

    _file = [[NSBundle bundleForClass:projClass] pathForResource:@"PC"
                                                          ofType:@"proj"];

    origin = [NSMutableDictionary dictionaryWithContentsOfFile:_file];
    keys   = [origin allKeys];

    enumerator = [keys objectEnumerator];
    while( (key = [enumerator nextObject]) )
    {
        if( [aDict objectForKey:key] == nil )
        {
            return NO;
        }
    }

    return YES;
}

- (void)updateProjectDict
{
    NSString *_file;
    NSString *key;
    Class projClass = [self builderClass];
    NSDictionary *origin;
    NSArray *keys;
    NSEnumerator *enumerator;
    BOOL projectHasChanged = NO;

    _file = [[NSBundle bundleForClass:projClass] pathForResource:@"PC"
                                                          ofType:@"proj"];

    origin = [NSMutableDictionary dictionaryWithContentsOfFile:_file];
    keys   = [origin allKeys];

    enumerator = [keys objectEnumerator];
    while( (key = [enumerator nextObject]) )
    {
        if( [projectDict objectForKey:key] == nil )
        {
            [projectDict setObject:[origin objectForKey:key] forKey:key];
	    projectHasChanged = YES;

            NSRunAlertPanel(@"New Project Key!",
                            @"The key '%@' has been added.",
                            @"OK",nil,nil,key);
        }
    }

    if (projectHasChanged == YES)
      {
    	[[NSNotificationCenter defaultCenter] 
  	  postNotificationName:ProjectDictDidChangeNotification 
	                object:self];
      }
}

- (void)validateProjectDict
{
    if( [self isValidDictionary:projectDict] == NO )
    {
	int ret = NSRunAlertPanel(@"Attention!", @"The project is not up to date, should it be updated automatically?", @"OK",@"No",nil);

        if( ret == NSAlertDefaultReturn )
	{
	    [self updateProjectDict];
	    [self save];

	    NSRunAlertPanel(@"Project updated!", @"The project file has been updated successfully!\nPlease make sure that all new project keys contain valid entries!", @"OK",nil,nil);
	}
    }
}

@end

@implementation PCProject (ProjectKeyPaths)

- (NSArray *)contentAtKeyPath:(NSString *)keyPath
{
    NSString *key;

#ifdef DEBUG
    NSLog(@"<%@ %x>: content at path %@",[self class],self,keyPath);
#endif

    if ([keyPath isEqualToString:@""] || [keyPath isEqualToString:@"/"])
    {
        return rootKeys;
    }

    key = [[keyPath componentsSeparatedByString:@"/"] lastObject];
    return [projectDict objectForKey:[rootCategories objectForKey:key]];
}

- (BOOL)hasChildrenAtKeyPath:(NSString *)keyPath
{
    NSString *key;

    if (!keyPath || [keyPath isEqualToString:@""]) {
        return NO;
    }

    key = [[keyPath componentsSeparatedByString:@"/"] lastObject];
    if ([[rootCategories allKeys] containsObject:key] || 
	[[projectDict objectForKey:PCSubprojects] containsObject:key]) {
        return YES;
    }
    
    return NO;
}

- (NSString *)projectKeyForKeyPath:(NSString *)kp
{
  NSString *type = [[kp componentsSeparatedByString:@"/"] objectAtIndex:1];
  
  return [rootCategories objectForKey:type];
}

@end

