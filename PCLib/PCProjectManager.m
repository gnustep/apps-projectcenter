/*
   GNUstep ProjectCenter - http://www.projectcenter.ch

   Copyright (C) 2000 Philippe C.D. Robert

   Author: Philippe C.D. Robert <phr@projectcenter.ch>

   This file is part of ProjectCenter.

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

#import "PCProjectManager.h"
#import "ProjectCenter.h"

#if defined(GNUSTEP)
#import <AppKit/IMLoading.h>
#endif

NSString *ActiveProjectDidChangeNotification = @"ActiveProjectDidChange";

@interface PCProjectManager (CreateUI)

- (void)_initUI;

@end

@implementation PCProjectManager (CreateUI)

- (void)_initUI
{
  NSView *_c_view;
  unsigned int style = NSTitledWindowMask | NSClosableWindowMask;
  NSRect _w_frame;
  NSBox *line;

  /*
   * Projects Window
   *
   */
 
  _w_frame = NSMakeRect(200,300,560,384);
  loadedProjectsWindow = [[NSWindow alloc] initWithContentRect:_w_frame
					   styleMask:style
					   backing:NSBackingStoreBuffered
					   defer:YES];
  [loadedProjectsWindow setMinSize:NSMakeSize(560,384)];
  [loadedProjectsWindow setTitle:@"Loaded Projects"];
  [loadedProjectsWindow setReleasedWhenClosed:NO];
  [loadedProjectsWindow setFrameAutosaveName:@"LoadedProjects"];

  /*
   * Inspector Window
   *
   */

  _w_frame = NSMakeRect(200,300,280,384);
  inspector = [[NSWindow alloc] initWithContentRect:_w_frame
                                          styleMask:style
                                            backing:NSBackingStoreBuffered
                                              defer:YES];
  [inspector setMinSize:NSMakeSize(280,384)];
  [inspector setTitle:@"Inspector"];
  [inspector setReleasedWhenClosed:NO];
  [inspector setFrameAutosaveName:@"Inspector"];
  _c_view = [inspector contentView];

  _w_frame = NSMakeRect(80,352,128,20);
  inspectorPopup = [[NSPopUpButton alloc] initWithFrame:_w_frame];
  [inspectorPopup addItemWithTitle:@"None"];
  [inspectorPopup setTarget:self];
  [inspectorPopup setAction:@selector(inspectorPopupDidChange:)];
  [_c_view addSubview:inspectorPopup];

  line = [[[NSBox alloc] init] autorelease];
  [line setTitlePosition:NSNoTitle];
  [line setFrame:NSMakeRect(0,336,280,2)];
  [_c_view addSubview:line];

  inspectorView = [[NSBox alloc] init];
  [inspectorView setTitlePosition:NSNoTitle];
  [inspectorView setFrame:NSMakeRect(-2,-2,284,334)];
  [inspectorView setBorderType:NSNoBorder];
  [_c_view addSubview:inspectorView];
	
  _needsReleasing = YES;
}

@end

@implementation PCProjectManager

// ===========================================================================
// ==== Class methods
// ===========================================================================

+ (void)initialize
{
}

// ===========================================================================
// ==== Intialization & deallocation
// ===========================================================================

- (id)init
{
    if ((self = [super init])) {
       	loadedProjects = [[NSMutableDictionary alloc] init];

        rootBuildPath = [[[NSUserDefaults standardUserDefaults] stringForKey:RootBuildDirectory] copy];
        if (!rootBuildPath || rootBuildPath == @"") {
            rootBuildPath = [NSTemporaryDirectory() copy];
        }
	_needsReleasing = NO;
    }
    return self;
}

- (void)dealloc
{
  [rootBuildPath release];
  [loadedProjects release];
  
  if (_needsReleasing) {
    [inspector release];
    [inspectorView release];
    [inspectorPopup release];
    [loadedProjectsWindow release];
  }
  
  [super dealloc];
}

// ===========================================================================
// ==== Delegate
// ===========================================================================

- (id)delegate
{
    return delegate;
}

- (void)setDelegate:(id)aDelegate
{
    delegate = aDelegate;
}

// ===========================================================================
// ==== Project management
// ===========================================================================

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
  if (aProject != activeProject) {
    activeProject = aProject;

    [[NSNotificationCenter defaultCenter] postNotificationName:ActiveProjectDidChangeNotification object:activeProject];
    
    //~ Is this needed?
    if (activeProject) {
      [[activeProject projectWindow] makeKeyAndOrderFront:self];
    }
    
    if ([inspector isVisible]) {
      [self inspectorPopupDidChange:inspectorPopup];
    }
  }
}

- (void)saveAllProjects
{
}

- (NSString *)rootBuildPath
{
    return rootBuildPath;
}

// ===========================================================================
// ==== Project actions
// ===========================================================================

- (PCProject *)loadProjectAt:(NSString *)aPath
{    
  if (delegate && [delegate respondsToSelector:@selector(projectTypes)]) {
    NSDictionary	*builders = [delegate projectTypes];
    NSEnumerator 	*enumerator = [builders keyEnumerator];
    NSString 	*builderKey;
    
    while (builderKey = [enumerator nextObject]) {
      id<ProjectType>	concretBuilder;
      PCProject		*project;
      
#ifdef DEBUG
      NSLog([NSString stringWithFormat:@"Builders %@ for key %@",[builders description],builderKey]);
#endif DEBUG
      
      concretBuilder = [NSClassFromString([builders objectForKey:builderKey]) sharedCreator];
      
      if ((project = [concretBuilder openProjectAt:aPath])) {
	[[project projectWindow] center];

	return project;
      }
    }
  }
#ifdef DEBUG
  else {
    NSLog(@"No project manager delegate available!");
  }
#endif DEBUG
  
  return nil;
}

- (BOOL)openProjectAt:(NSString *)aPath
{
    BOOL isDir = NO;

    if ([loadedProjects objectForKey:aPath]) {
#ifdef DEBUG
      NSLog([NSString stringWithFormat:@"Project %@ is already loaded!",aPath]);
#endif DEBUG
      return NO;
    }
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:aPath isDirectory:&isDir] && !isDir) {
      PCProject *project = [self loadProjectAt:aPath];
      
      if (!project) {
#ifdef DEBUG
	NSLog(@"Couldn't instantiate the project...");
#endif DEBUG
	return NO;
      }
      
      [project setProjectBuilder:self];
      [loadedProjects setObject:project forKey:aPath];
      [self setActiveProject:project];
      [project setDelegate:self];
      
      return YES;
    }
    return NO;
}

- (BOOL)createProjectOfType:(NSString *)projectType path:(NSString *)aPath
{
    Class	creatorClass = NSClassFromString(projectType);
    PCProject * project;

    if (![creatorClass conformsToProtocol:@protocol(ProjectType)]) {
        [NSException raise:NOT_A_PROJECT_TYPE_EXCEPTION format:@"%@ does not conform to ProjectType!",projectType];
        return NO;
    }

    if (!(project = [[creatorClass sharedCreator] createProjectAt:aPath])) {
        return NO;
    }

    [[project projectWindow] center];

    [project setProjectBuilder:self];
    [loadedProjects setObject:project forKey:aPath];
    [self setActiveProject:project];
    [project setDelegate:self];
    
    return YES;
}

- (BOOL)saveProject
{
    // Save all files that need to be saved

    // Save PC.project and the makefile!
}

- (BOOL)saveProjectAs:(NSString *)projName
{
}

- (void)inspectorPopupDidChange:(id)sender
{
  NSView *view = nil;
  
  if (![self activeProject]) {
    return;
  }
  
  switch([sender indexOfSelectedItem]) {
  case 0:
    view = [[[self activeProject] updatedAttributeView] retain];
    break;
  case 1:
    view = [[[self activeProject] updatedProjectView] retain];
    break;
  case 2:
    view = [[[self activeProject] updatedFilesView] retain];
    break;
  }
  [(NSBox *)inspectorView setContentView:view];
  [inspectorView display];
}

- (void)showInspectorForProject:(PCProject *)aProject
{
  if (!inspectorPopup) {
    [self _initUI];
    
    [inspectorPopup removeAllItems];
    [inspectorPopup addItemWithTitle:@"Build Attributes"];
    [inspectorPopup addItemWithTitle:@"Project Attributes"];
    [inspectorPopup addItemWithTitle:@"File Attributes"];
  }
  
  [self inspectorPopupDidChange:inspectorPopup];  

  if (![inspector isVisible]) {
    [inspector setFrameUsingName:@"Inspector"];
  }
  [inspector makeKeyAndOrderFront:self];
}

- (void)showLoadedProjects
{
  if (![loadedProjectsWindow isVisible]) {
    [loadedProjectsWindow center];
  }
  [loadedProjectsWindow makeKeyAndOrderFront:self];
}

- (void)saveFiles
{
}

- (void)revertToSaved
{
}

- (BOOL)newSubproject
{
}

- (BOOL)addSubprojectAt:(NSString *)path
{
}

- (void)removeSubproject
{
}

- (void)closeProject:(PCProject *)aProject
{
  PCProject	*currentProject;
  NSString 	*key = [[aProject projectPath] stringByAppendingPathComponent:@"PC.project"];
  
  currentProject = [[loadedProjects objectForKey:key] retain];
    
  // Remove it from the loaded projects!
  [loadedProjects removeObjectForKey:key];
  [self setActiveProject:[[loadedProjects allValues] lastObject]];

  if ([loadedProjects count] == 0) {
    [inspector performClose:self];
  }

  AUTORELEASE(currentProject);
}

- (void)closeProject
{
  [[[self activeProject] projectWindow] performClose:self];
}

// ===========================================================================
// ==== File actions
// ===========================================================================

- (BOOL)openFile:(NSString *)path
{
  BOOL isDir;
  NSFileManager *fm = [NSFileManager defaultManager];
  NSDictionary *ui =[NSDictionary dictionaryWithObjectsAndKeys:
				    path,@"FilePathKey",
				  nil];

  if ([fm fileExistsAtPath:path isDirectory:&isDir] && !isDir) {
    [[NSNotificationCenter defaultCenter] postNotificationName:FileShouldOpenNotification object:self userInfo:ui];
    return YES;
  }

  return NO;
}

- (BOOL)saveFile
{
}

- (BOOL)saveFileAs:(NSString *)path
{
}

- (BOOL)revertFile
{
}

- (BOOL)renameFileTo:(NSString *)path
{
}

- (BOOL)removeFilePermanently:(BOOL)yn
{
    if (!activeProject) {
        return NO;
    }

    return [activeProject removeSelectedFilePermanently:yn];
}

@end

@implementation  PCProjectManager (FileManagerDelegates)

- (NSString *)fileManager:(id)sender willCreateFile:(NSString *)aFile withKey:(NSString *)key
{
  NSString *path = nil;
  
#ifdef DEBUG
  NSLog(@"%@ %x: will create file %@ for key %@.",[self class],self,aFile,key);
  #endif DEBUG

  if ([activeProject doesAcceptFile:aFile forKey:key] ) {
    path = [[activeProject projectPath] stringByAppendingPathComponent:aFile];
  }
  
  return path;
}

- (void)fileManager:(id)sender didCreateFile:(NSString *)aFile withKey:(NSString *)key
{
#ifdef DEBUG
    NSLog(@"<%@ %x>: did create file %@ for key %@",[self class],self,aFile,key);
#endif DEBUG

    [activeProject addFile:aFile forKey:key];
}

- (id)fileManagerWillAddFiles:(id)sender
{
    return activeProject;
}

- (BOOL)fileManager:(id)sender shouldAddFile:(NSString *)file forKey:(NSString *)key
{
  NSMutableString *fn = [NSMutableString stringWithString:[file lastPathComponent]];

#ifdef DEBUG
  NSLog(@"<%@ %x>: should add file %@ for key %@",[self class],self,file,key);
#endif DEBUG
  
  if ([key isEqualToString:PCLibraries]) {
    [fn deleteCharactersInRange:NSMakeRange(1,3)];
    fn = [fn stringByDeletingPathExtension];
  }
  
  if ([[[activeProject projectDict] objectForKey:key] containsObject:fn]) {
    NSRunAlertPanel(@"Attention!",@"The file %@ is already part of project %@!",@"OK",nil,nil,fn,[activeProject projectName]);
    return NO;
  }
  return YES;
}

- (void)fileManager:(id)sender didAddFile:(NSString *)file forKey:(NSString *)key
{
#ifdef DEBUG
  NSLog(@"<%@ %x>: did add file %@ for key %@",[self class],self,file,key);
#endif DEBUG

  [activeProject addFile:file forKey:key];
}


@end


