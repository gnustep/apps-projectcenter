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

#include "PCProject.h"
#include "PCDefines.h"
#include "ProjectBuilder.h"
#include "PCProject+ComponentHandling.h"
#include "PCProjectBuilder.h"
#include "PCProjectEditor.h"
#include "PCProjectDebugger.h"
#include "PCEditor.h"
#include "PCEditorController.h"
#include "PCHistoryController.h"
#include "PCBrowserController.h"

#include "PCProject+UInterface.h"

@implementation PCProject

//==============================================================================
// ==== Init and free
//==============================================================================

- (id)init
{
    if ((self = [super init])) 
    {
	buildOptions = [[NSMutableDictionary alloc] init];
        [self _initUI];

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
        if ([[path lastPathComponent] isEqualToString:@"PC.project"]) {
            projectPath = [[path stringByDeletingLastPathComponent] copy];
        }
        else {
            projectPath = [path copy];
        }

        if(![self assignProjectDict:dict]) {
            NSLog(@"<%@ %x>: could not load the project...",[self class],self);
            [self autorelease];
            return nil;
        }
    }
    return self;
}

- (void)dealloc
{
  RELEASE(projectName);
  RELEASE(projectPath);
  RELEASE(projectDict);

  if( projectBuilder)  RELEASE(projectBuilder);
  if( projectDebugger) RELEASE(projectDebugger);
  if( projectEditor)   RELEASE(projectEditor);
  
  RELEASE(historyController);
  RELEASE(browserController);

  RELEASE(buildTargetPanel);
  RELEASE(buildTargetHostField);
  RELEASE(buildTargetArgsField);
  
  RELEASE(buildOptions);
 
  RELEASE(projectAttributeInspectorView);
  RELEASE(installPathField);
  RELEASE(toolField);
  RELEASE(ccOptField);
  RELEASE(ldOptField);

  RELEASE(projectProjectInspectorView);
  RELEASE(projectTypeField);

  RELEASE(projectFileInspectorView);
  RELEASE(fileNameField);
  RELEASE(changeFileNameButton);
 
  RELEASE(box);
  RELEASE(editorController);

  [super dealloc];
}

//==============================================================================
// ==== Accessor methods
//==============================================================================

- (id)browserController
{
  return browserController;
}

- (NSString *)selectedRootCategory
{
  NSString *_path = [browserController pathOfSelectedFile];

  return [self projectKeyForKeyPath:_path];
}

- (NSArray *)fileExtensionsForCategory:(NSString *)key
{
  if ([key isEqualToString:PCGModels]) {
    return [NSArray arrayWithObjects:@"gmodel",@"gorm",nil];
  }
  if ([key isEqualToString:PCGSMarkupFiles]) {
    return [NSArray arrayWithObjects:@"gsmarkup",nil];
  }
  else if ([key isEqualToString:PCClasses]) {
    return [NSArray arrayWithObjects:@"m",nil];
  }
  else if ([key isEqualToString:PCHeaders]) {
    return [NSArray arrayWithObjects:@"h",nil];
  }
  else if ([key isEqualToString:PCOtherSources]) {
    return [NSArray arrayWithObjects:@"c",@"C",@"m",@"M",nil];
  }
  else if ([key isEqualToString:PCLibraries]) {
    return [NSArray arrayWithObjects:@"so",@"a",@"lib",nil];
  }
  else if ([key isEqualToString:PCSubprojects]) {
    return [NSArray arrayWithObjects:@"subproj",nil];
  }
  else if ([key isEqualToString:PCImages]) {
    return [NSImage imageFileTypes];
  }

  return nil;
}

- (NSString *)categoryForFile:(NSString *)file
{
  NSString *fileExt = [[file componentsSeparatedByString: @"."] lastObject];

  if ([fileExt isEqualToString:@"gmodel"] || [fileExt isEqualToString:@"gorm"])
    {
      return PCGModels;
    }
  else if ([fileExt isEqualToString:@"gsmarkup"])
    {
      return PCGSMarkupFiles;
    }
  else if ([fileExt isEqualToString:@"h"] || [fileExt isEqualToString:@"H"])
    {
      return PCHeaders;
    }
  else if ([fileExt isEqualToString:@"m"] || [fileExt isEqualToString:@"M"])
    {
      return PCClasses;
    }
  else if ([fileExt isEqualToString:@"c"] || [fileExt isEqualToString:@"C"])
    {
      return PCOtherSources;
    }
  else if ([fileExt isEqualToString:@"so"] || [fileExt isEqualToString:@"lib"]
	   || [fileExt isEqualToString:@"a"])
    {
      return PCLibraries;
    }
  else if ([fileExt isEqualToString:@"subproj"])
    {
      return PCSubprojects;
    }
  else if ([[NSImage imageFileTypes] containsObject: fileExt])
    {
      return PCImages;
    }
  else if ([file hasPrefix: @"GNUmakefile"])
    {
      return PCSupportingFiles;
    }
  else if (file != nil)
    {
      return PCOtherResources;
    }

  return nil;
}

- (void)setProjectName:(NSString *)aName
{
    AUTORELEASE(projectName);
    projectName = [aName copy];
}

- (NSString *)projectName
{
    return projectName;
}

- (NSWindow *)projectWindow
{
    return projectWindow;
}

- (Class)principalClass
{
    return [self class];
}

- (PCProjectEditor *)projectEditor
{
  return projectEditor;
}

- (PCEditorController*)editorController
{
    return editorController;
}

//==============================================================================
// ==== Delegate and manager
//==============================================================================

- (id)delegate
{
    return delegate;
}

- (void)setDelegate:(id)aDelegate
{
    delegate = aDelegate;
}

- (void)setProjectBuilder:(id<ProjectBuilder,NSObject>)aBuilder
{
  // This is our owner, don't retain.
  //projectManager = aBuilder;
  ASSIGN(projectManager, aBuilder);
}

- (id<ProjectBuilder>)projectBuilder
{
    return projectManager;
}

//==============================================================================
// ==== To be overriden
//==============================================================================

- (Class)builderClass
{
    return Nil;
}

- (BOOL)writeMakefile
{
    NSString *mf = [projectPath stringByAppendingPathComponent:@"GNUmakefile"];
    NSString *bu = [projectPath stringByAppendingPathComponent:@"GNUmakefile~"];
    NSFileManager *fm = [NSFileManager defaultManager];

    if( [fm isReadableFileAtPath:mf] ) {
        if( [fm isWritableFileAtPath:bu] ) {
	    [fm removeFileAtPath:bu handler:nil];
	}

        if (![fm copyPath:mf toPath:bu handler:nil]) {
            NSRunAlertPanel(@"Attention!",
    	                    @"Could not keep a backup of the GNUMakefile!",
	                    @"OK",nil,nil);
        }
    }

    return YES;
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

//=============================================================================
// ==== File Handling
//=============================================================================

- (void)browserDidClickFile:(NSString *)fileName category:(NSString*)c
{
  NSString *p = [[self projectPath] stringByAppendingPathComponent:fileName];
  PCEditor *e;

  // Set the name in the inspector
  [fileNameField setStringValue:fileName];

  // Show the file in the internal editor!
  e = [editorController internalEditorForFile:p];

  if( e == nil )
    {
      NSLog(@"No editor for file '%@'...",p);
      return;
    }

  [self showEditorView:self];
  [e showInProjectEditor:projectEditor];

  [projectWindow makeFirstResponder:(NSResponder*)[projectEditor editorView]];
}

- (void)browserDidDblClickFile:(NSString *)fileName category:(NSString*)c
{
    PCEditor *e;

    e = [editorController editorForFile:fileName];

    if( e )
    {
	[e show];
    }
}

- (BOOL)doesAcceptFile:(NSString *)file forKey:(NSString *)type
{
    if ([[projectDict allKeys] containsObject:type]) {
        NSArray *files = [projectDict objectForKey:type];

        if (![files containsObject:file]) {
            return YES;
        }
    }
    
    return NO;
}

- (void)addFile:(NSString *)file forKey:(NSString *)type
{
    [self addFile:file forKey:type copy:NO];
}

- (void)addFile:(NSString *)file forKey:(NSString *)type copy:(BOOL)yn
{
    NSArray *types = [projectDict objectForKey:type];
    NSMutableArray *files = [NSMutableArray arrayWithArray:types];
    NSString *lpc = [file lastPathComponent];
    NSMutableString *newFile = [NSMutableString stringWithString:lpc];
  
    if ([type isEqualToString:PCLibraries]) {
        [newFile deleteCharactersInRange:NSMakeRange(0,3)];
        newFile = (NSMutableString*)[newFile stringByDeletingPathExtension];
    }
  
    if ([files containsObject:newFile]) {
        NSRunAlertPanel(@"Attention!",
	                @"The file %@ is already part of this project!",
			@"OK",nil,nil,newFile);
        return;
    }
  
#ifdef DEBUG
    NSLog(@"<%@ %x>: adding file %@ for key %@",[self class],self,newFile,type);
#endif// DEBUG
  
    // Add the new file
    [files addObject:newFile];
    [projectDict setObject:files forKey:type];

    [projectWindow setDocumentEdited:YES];
  
    if (yn) {
        NSFileManager *manager = [NSFileManager defaultManager];
        NSString *destination = [[self projectPath] stringByAppendingPathComponent:newFile];
    
        if (![manager copyPath:file toPath:destination handler:nil]) {
            NSRunAlertPanel(@"Attention!",
	                    @"The file %@ could not be copied to %@!",
			    @"OK",nil,nil,newFile,destination);
        }
    }

    [[NSNotificationCenter defaultCenter] postNotificationName:@"ProjectDictDidChangeNotification" object:self];
}

- (void)removeFile:(NSString *)file forKey:(NSString *)key
{
    NSMutableArray *array;

    if (!file || !key) {
        return;
    }

    array = [NSMutableArray arrayWithArray:[projectDict objectForKey:key]];
    [array removeObject:file];
    [projectDict setObject:array forKey:key];

    [projectWindow setDocumentEdited:YES];
}

- (BOOL)removeSelectedFilePermanently:(BOOL)yn
{
  NSEnumerator *files = [[browserController selectedFiles] objectEnumerator];
  NSString     *file = nil;
  NSString     *key = nil;
  NSString     *otherKey = nil;
  NSString     *ext = nil;
  NSString     *fn = nil;
  BOOL         ret = NO;

  if (!files)
    {
      return NO;
    }

  key = [self projectKeyForKeyPath:[browserController pathOfSelectedFile]];

  while ((file = [files nextObject]))
    {
      [self removeFile:file forKey:key];

      if ([key isEqualToString:PCClasses])
	{
	  otherKey = PCHeaders;
	  ext = [NSString stringWithString:@"h"];

	  fn = [file stringByDeletingPathExtension];
	  fn = [fn stringByAppendingPathExtension:ext];

	  if ([self doesAcceptFile:fn forKey:otherKey] == NO)
	    {
	      ret = NSRunAlertPanel(@"Removing Header?",
				    @"Should %@ be removed from the project %@ as well?",
				    @"Yes", @"No", nil, 
				    fn, [self projectName]);
	    }
	}
      else if ([key isEqualToString:PCHeaders])
	{
	  otherKey = PCClasses;
	  ext = [NSString stringWithString:@"m"];

	  fn = [file stringByDeletingPathExtension];
	  fn = [fn stringByAppendingPathExtension:ext];

	  if ([self doesAcceptFile:fn forKey:otherKey] == NO)
	    {
	      ret = NSRunAlertPanel(@"Removing Class?",
				    @"Should %@ be removed from the project %@ as well?",
				    @"Yes", @"No", nil,
				    fn, [self projectName]);
	    }
	}

      if (ret)
	{
	  [self removeFile:fn forKey:otherKey];
	}

      // Remove the file permanently?!
      if (yn)
	{
	  NSString *pth = [projectPath stringByAppendingPathComponent:file];

	  [[NSFileManager defaultManager] removeFileAtPath:pth handler:nil];

	  if (ret)
	    {
	      pth = [projectPath stringByAppendingPathComponent:fn];
	      [[NSFileManager defaultManager] removeFileAtPath:pth handler:nil];
	    }
	}
    }

  [[NSNotificationCenter defaultCenter] 
    postNotificationName:@"ProjectDictDidChangeNotification" object:self];

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

    [self setProjectName:[projectDict objectForKey:PCProjectName]];
    [projectWindow setTitle:[NSString stringWithFormat: @"%@ - %@", 
      projectName, 
      [projectPath stringByAbbreviatingWithTildeInPath]]];

    // Update the interface
    [self updateValuesFromProjectDict];

    [[NSNotificationCenter defaultCenter] postNotificationName:@"ProjectDictDidChangeNotification" object:self];

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
  NSString *file = [[projectPath stringByAppendingPathComponent:projectName] 
                    stringByAppendingPathExtension:@"pcproj"];
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
      [projectWindow setDocumentEdited:NO];
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

//=============================================================================
// ==== Subprojects
//=============================================================================

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

//=============================================================================
// ==== Project Handling
//=============================================================================

- (void)updateValuesFromProjectDict
{
    [projectTypeField setStringValue:[projectDict objectForKey:PCProjType]];
    [installPathField setStringValue:[projectDict objectForKey:PCInstallDir]];
    [toolField setStringValue:[projectDict objectForKey:PCBuildTool]];
    [ccOptField setStringValue:[projectDict objectForKey:PCCompilerOptions]];
    [ldOptField setStringValue:[projectDict objectForKey:PCLinkerOptions]];
}

- (void)changeCommonProjectEntry:(id)sender
{
    NSString *newEntry = [sender stringValue];

    if( sender == installPathField )
    {
        [projectDict setObject:newEntry forKey:PCInstallDir];
    }
    else if ( sender == toolField )
    {
        [projectDict setObject:newEntry forKey:PCBuildTool];

	if( ![[NSFileManager defaultManager] isExecutableFileAtPath:newEntry] )
	{
            NSRunAlertPanel(@"Build Tool Error!",
                            @"No valid executable found at '%@'!",
                            @"OK",nil,nil,newEntry);
	}
    }
    else if ( sender == ccOptField )
    {
        [projectDict setObject:newEntry forKey:PCCompilerOptions];
    }
    else if ( sender == ldOptField )
    {
        [projectDict setObject:newEntry forKey:PCLinkerOptions];
    }

    [projectWindow setDocumentEdited:YES];
}

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

    if( projectHasChanged == YES )
    {
	[projectWindow setDocumentEdited:YES];
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

//=============================================================================
//=============================================================================

@implementation PCProject (ProjectKeyPaths)

- (NSArray *)contentAtKeyPath:(NSString *)keyPath
{
    NSString *key;

#ifdef DEBUG
    NSLog(@"<%@ %x>: content at path %@",[self class],self,keyPath);
#endif

    if ([keyPath isEqualToString:@""] || [keyPath isEqualToString:@"/"]) {
        return [rootCategories allKeys];
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

@implementation PCProject (ProjectWindowDelegate)

- (void)windowDidResignKey:(NSNotification *)aNotification
{
}

- (void)windowDidBecomeKey:(NSNotification *)aNotification
{
  [projectManager setActiveProject:self];
}

- (void)windowDidBecomeMain:(NSNotification *)aNotification
{
  [projectManager setActiveProject:self];
}

- (void)windowWillClose:(NSNotification *)aNotification
{
  id object = [aNotification object];

  if (object == [self projectWindow]) 
    {
      if ([[self projectWindow] isDocumentEdited]) 
	{
	  if (NSRunAlertPanel(@"Close Project",
			      @"The project %@ has been edited!\nShould it be saved before closing?",
			      @"Yes", @"No", nil,[self projectName])) 
	    {
	      [self save];
	    }
	}

      [editorController closeAllEditors];

      if (projectBuilder && [projectBuilder buildPanel])
	{
	  [[projectBuilder buildPanel] performClose: self];
	  [[projectBuilder buildPanel] release];
	}
      if (projectDebugger && [projectDebugger launchPanel])
	{
	  [[projectDebugger launchPanel] performClose: self];
	  [[projectDebugger launchPanel] release];
	}

      // The PCProjectController is our delegate!
      [[NSNotificationCenter defaultCenter] removeObserver:browserController];
      [projectManager closeProject:self];
    }
}

@end
