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

#import "PCProject.h"
#import "ProjectCenter.h"
#import "PCProjectBuilder.h"

#if defined(GNUSTEP)
#import <AppKit/IMLoading.h>
#endif

@interface PCProject (CreateUI)

- (void)_initUI;

@end

@implementation PCProject (CreateUI)

- (void)_initUI
{
  NSView *_c_view;
  unsigned int style = NSTitledWindowMask | NSClosableWindowMask | 
                       NSMiniaturizableWindowMask | NSResizableWindowMask;
  NSBrowser *browser;
  NSRect _w_frame;
  NSMatrix* matrix;
  NSButtonCell* buttonCell = [[[NSButtonCell alloc] init] autorelease];
  id textField;
  id button;

  browserController = [[PCBrowserController alloc] init];

  /*
   * Project Window
   *
   */

  _w_frame = NSMakeRect(100,100,560,440);
  projectWindow = [[NSWindow alloc] initWithContentRect:_w_frame
                                              styleMask:style
                                                backing:NSBackingStoreBuffered
                                                  defer:YES];
  [projectWindow setDelegate:self];
  [projectWindow setMinSize:NSMakeSize(560,448)];

  browser = [[NSBrowser alloc] initWithFrame:NSMakeRect(8,251,544,128)];
  [browser setDelegate:browserController];
  [browser setMaxVisibleColumns:3];
  [browser setAllowsMultipleSelection:NO];
  [browser setAutoresizingMask: NSViewWidthSizable | NSViewMinYMargin];

  [browserController setBrowser:browser];
  [browserController setProject:self];
  [browser autorelease];

  box = [[NSBox alloc] initWithFrame:NSMakeRect (0,-1,560,252)];
  [box setTitlePosition:NSNoTitle];
  [box setBorderType:NSNoBorder];
  [box setAutoresizingMask: NSViewWidthSizable | NSViewHeightSizable];

  textField = [[NSTextField alloc] initWithFrame:NSMakeRect(16,200,500,21)];
  [textField setAlignment: NSLeftTextAlignment];
  [textField setBordered: NO];
  [textField setEditable: NO];
  [textField setBezeled: NO];
  [textField setDrawsBackground: NO];
  [textField setStringValue:@"Welcome to the GNUstep ProjectCenter!"];
  [box addSubview:[textField autorelease]];

  textField = [[NSTextField alloc] initWithFrame:NSMakeRect(16,178,500,21)];
  [textField setAlignment: NSLeftTextAlignment];
  [textField setBordered: NO];
  [textField setEditable: NO];
  [textField setBezeled: NO];
  [textField setDrawsBackground: NO];
  [textField setStringValue:@"\tPlease report all bugs or other issues you don't like to phr@projectcenter.ch!"];
  [box addSubview:[textField autorelease]];

  _c_view = [projectWindow contentView];
  [_c_view addSubview:browser];
  [_c_view addSubview:box];

  /*
   * Left button matrix
   */

  _w_frame = NSMakeRect(8,388,330,48);
  matrix = [[[NSMatrix alloc] initWithFrame: _w_frame
                                       mode: NSHighlightModeMatrix
                                  prototype: buttonCell
                               numberOfRows: 1
                            numberOfColumns: 7] autorelease];
  [matrix sizeToCells];
  [matrix setTarget:self];
  [matrix setAction:@selector(topButtonsPressed:)];
  [matrix setSelectionByRect:YES];
  [matrix setAutoresizingMask: (NSViewMaxXMargin | NSViewMinYMargin)];
  [_c_view addSubview:matrix];

  button = [matrix cellAtRow:0 column:0];
  [button setTag:0];
  [button setImagePosition:NSImageOnly];
  [button setImage:IMAGE(@"ProjectCentre_build")];
  [button setButtonType:NSMomentaryPushButton];

  button = [matrix cellAtRow:0 column:1];
  [button setTag:1];
  [button setImagePosition:NSImageOnly];
  [button setImage:IMAGE(@"ProjectCentre_settings.tiff")];
  [button setButtonType:NSMomentaryPushButton];

  button = [matrix cellAtRow:0 column:2];
  [button setTag:2];
  [button setImagePosition:NSImageOnly];
  [button setImage:IMAGE(@"ProjectCentre_prefs.tiff")];
  [button setButtonType:NSMomentaryPushButton];

  button = [matrix cellAtRow:0 column:3];
  [button setTag:3];
  [button setImagePosition:NSImageOnly];
  [button setImage:IMAGE(@"ProjectCentre_run.tiff")];
  [button setButtonType:NSMomentaryPushButton];

  button = [matrix cellAtRow:0 column:4];
  [button setTag:4];
  [button setImagePosition:NSImageOnly];
  [button setImage:IMAGE(@"ProjectCentre_uml.tiff")];
  [button setButtonType:NSMomentaryPushButton];

  button = [matrix cellAtRow:0 column:5];
  [button setTag:5];
  [button setImagePosition:NSImageOnly];
  [button setImage:IMAGE(@"ProjectCentre_documentation.tiff")];
  [button setButtonType:NSMomentaryPushButton];

  button = [matrix cellAtRow:0 column:6];
  [button setTag:6];
  [button setImagePosition:NSImageOnly];
  [button setImage:IMAGE(@"ProjectCentre_find.tiff")];
  [button setButtonType:NSMomentaryPushButton];

  /*
   * Build Options Panel
   *
   */

  _w_frame = NSMakeRect(100,100,272,80);
  style = NSTitledWindowMask | NSClosableWindowMask;
  buildTargetPanel = [[NSWindow alloc] initWithContentRect:_w_frame 
				       styleMask:style 
				       backing:NSBackingStoreBuffered 
				       defer:YES];
  [buildTargetPanel setDelegate:self];
  [buildTargetPanel setReleasedWhenClosed:NO];
  [buildTargetPanel setTitle:@"Build Options"];
  _c_view = [buildTargetPanel contentView];

  // Host
  textField = [[NSTextField alloc] initWithFrame:NSMakeRect(16,24,56,21)];
  [textField setAlignment: NSRightTextAlignment];
  [textField setBordered: NO];
  [textField setEditable: NO];
  [textField setBezeled: NO];
  [textField setDrawsBackground: NO];
  [textField setStringValue:@"Host:"];
  [_c_view addSubview:[textField autorelease]];

  // Host message
  buildTargetHostField = [[NSTextField alloc] initWithFrame:NSMakeRect(72,24,184,21)];
  [buildTargetHostField setAlignment: NSLeftTextAlignment];
  [buildTargetHostField setBordered: NO];
  [buildTargetHostField setEditable: YES];
  [buildTargetHostField setBezeled: YES];
  [buildTargetHostField setDrawsBackground: YES];
  [buildTargetHostField setStringValue:@"localhost"];
  [buildTargetHostField setDelegate:self];
  [buildTargetHostField setTarget:self];
  [buildTargetHostField setAction:@selector(setHost:)];
  [_c_view addSubview:[buildTargetHostField autorelease]];

  // Args
  textField = [[NSTextField alloc] initWithFrame:NSMakeRect(12,44,60,21)];
  [textField setAlignment: NSRightTextAlignment];
  [textField setBordered: NO];
  [textField setEditable: NO];
  [textField setBezeled: NO];
  [textField setDrawsBackground: NO];
  [textField setStringValue:@"Arguments:"];
  [_c_view addSubview:[textField autorelease]];

  // Args message
  buildTargetArgsField = [[NSTextField alloc] initWithFrame:NSMakeRect(72,44,184,21)];
  [buildTargetArgsField setAlignment: NSLeftTextAlignment];
  [buildTargetArgsField setBordered: NO];
  [buildTargetArgsField setEditable: YES];
  [buildTargetArgsField setBezeled: YES];
  [buildTargetArgsField setDrawsBackground: YES];
  [buildTargetArgsField setStringValue:@""];
  [buildTargetArgsField setDelegate:self];
  [buildTargetArgsField setTarget:self];
  [buildTargetArgsField setAction:@selector(setArguments:)];
  [_c_view addSubview:[buildTargetArgsField autorelease]];

  /*
   * Model the standard inspector UI
   *
   */

  projectAttributeInspectorView = [[NSBox alloc] init];
  [projectAttributeInspectorView setFrame:NSMakeRect(-2,-2,284,334)];
  [projectAttributeInspectorView setTitlePosition:NSNoTitle];
  [projectAttributeInspectorView setBorderType:NSNoBorder];
  [projectAttributeInspectorView setAutoresizingMask:(NSViewWidthSizable | NSViewHeightSizable)];

  textField =[[NSTextField alloc] initWithFrame:NSMakeRect(16,280,64,21)];
  [textField setAlignment: NSRightTextAlignment];
  [textField setBordered: NO];
  [textField setEditable: NO];
  [textField setBezeled: NO];
  [textField setDrawsBackground: NO];
  [textField setStringValue:@"Install in:"];
  [projectAttributeInspectorView addSubview:[textField autorelease]];

  installPathField =[[NSTextField alloc] initWithFrame:NSMakeRect(84,280,176,21)];
  [installPathField setAlignment: NSLeftTextAlignment];
  [installPathField setBordered: YES];
  [installPathField setEditable: YES];
  [installPathField setBezeled: YES];
  [installPathField setDrawsBackground: YES];
  [installPathField setStringValue:@""];
  [projectAttributeInspectorView addSubview:installPathField];

  textField =[[NSTextField alloc] initWithFrame:NSMakeRect(16,256,64,21)];
  [textField setAlignment: NSRightTextAlignment];
  [textField setBordered: NO];
  [textField setEditable: NO];
  [textField setBezeled: NO];
  [textField setDrawsBackground: NO];
  [textField setStringValue:@"Build tool:"];
  [projectAttributeInspectorView addSubview:[textField autorelease]];

  toolField =[[NSTextField alloc] initWithFrame:NSMakeRect(84,256,176,21)];
  [toolField setAlignment: NSLeftTextAlignment];
  [toolField setBordered: YES];
  [toolField setEditable: YES];
  [toolField setBezeled: YES];
  [toolField setDrawsBackground: YES];
  [toolField setStringValue:@""];
  [projectAttributeInspectorView addSubview:toolField];

  textField =[[NSTextField alloc] initWithFrame:NSMakeRect(16,232,64,21)];
  [textField setAlignment: NSRightTextAlignment];
  [textField setBordered: NO];
  [textField setEditable: NO];
  [textField setBezeled: NO];
  [textField setDrawsBackground: NO];
  [textField setStringValue:@"CC options:"];
  [projectAttributeInspectorView addSubview:[textField autorelease]];

  ccOptField =[[NSTextField alloc] initWithFrame:NSMakeRect(84,232,176,21)];
  [ccOptField setAlignment: NSLeftTextAlignment];
  [ccOptField setBordered: YES];
  [ccOptField setEditable: YES];
  [ccOptField setBezeled: YES];
  [ccOptField setDrawsBackground: YES];
  [ccOptField setStringValue:@""];
  [projectAttributeInspectorView addSubview:ccOptField];

  textField =[[NSTextField alloc] initWithFrame:NSMakeRect(16,204,64,21)];
  [textField setAlignment: NSRightTextAlignment];
  [textField setBordered: NO];
  [textField setEditable: NO];
  [textField setBezeled: NO];
  [textField setDrawsBackground: NO];
  [textField setStringValue:@"LD options:"];
  [projectAttributeInspectorView addSubview:[textField autorelease]];

  ldOptField =[[NSTextField alloc] initWithFrame:NSMakeRect(84,204,176,21)];
  [ldOptField setAlignment: NSLeftTextAlignment];
  [ldOptField setBordered: YES];
  [ldOptField setEditable: YES];
  [ldOptField setBezeled: YES];
  [ldOptField setDrawsBackground: YES];
  [ldOptField setStringValue:@""];
  [projectAttributeInspectorView addSubview:ldOptField];

  projectProjectInspectorView = [[NSBox alloc] init];
  [projectProjectInspectorView setFrame:NSMakeRect(-2,-2,284,334)];
  [projectProjectInspectorView setTitlePosition:NSNoTitle];
  [projectProjectInspectorView setBorderType:NSNoBorder];
  [projectProjectInspectorView setAutoresizingMask:(NSViewWidthSizable | NSViewHeightSizable)];

  textField =[[NSTextField alloc] initWithFrame:NSMakeRect(16,280,64,21)];
  [textField setAlignment: NSRightTextAlignment];
  [textField setBordered: NO];
  [textField setEditable: NO];
  [textField setBezeled: NO];
  [textField setDrawsBackground: NO];
  [textField setStringValue:@"Type:"];
  [projectProjectInspectorView addSubview:[textField autorelease]];

  projectTypeField =[[NSTextField alloc] initWithFrame:NSMakeRect(84,280,176,21)];
  [projectTypeField setAlignment: NSLeftTextAlignment];
  [projectTypeField setBordered: NO];
  [projectTypeField setEditable: NO];
  [projectTypeField setBezeled: NO];
  [projectTypeField setDrawsBackground: NO];
  [projectTypeField setStringValue:@""];
  [projectProjectInspectorView addSubview:projectTypeField];

  projectFileInspectorView = [[NSBox alloc] init];
  [projectFileInspectorView setFrame:NSMakeRect(-2,-2,284,334)];
  [projectFileInspectorView setTitlePosition:NSNoTitle];
  [projectFileInspectorView setBorderType:NSNoBorder];
  [projectFileInspectorView setAutoresizingMask:(NSViewWidthSizable | NSViewHeightSizable)];

  textField =[[NSTextField alloc] initWithFrame:NSMakeRect(16,280,64,21)];
  [textField setAlignment: NSRightTextAlignment];
  [textField setBordered: NO];
  [textField setEditable: NO];
  [textField setBezeled: NO];
  [textField setDrawsBackground: NO];
  [textField setStringValue:@"Filename:"];
  [projectFileInspectorView addSubview:[textField autorelease]];

  fileNameField =[[NSTextField alloc] initWithFrame:NSMakeRect(84,280,176,21)];
  [fileNameField setAlignment: NSLeftTextAlignment];
  [fileNameField setBordered: NO];
  [fileNameField setEditable: NO];
  [fileNameField setBezeled: NO];
  [fileNameField setDrawsBackground: NO];
  [fileNameField setStringValue:@""];
  [projectFileInspectorView addSubview:fileNameField];

  changeFileNameButton = [[NSButton alloc] initWithFrame:NSMakeRect(84,240,104,21)];
  [changeFileNameButton setTitle:@"Rename..."];
  [changeFileNameButton setTarget:self];
  [changeFileNameButton setAction:@selector(renameFile:)];
  [projectFileInspectorView addSubview:changeFileNameButton];

  /*
   *
   */

  // Redisplay!
  [browser loadColumnZero];
}

@end

@implementation PCProject

//===========================================================================================
// ==== Init and free
//===========================================================================================

- (id)init
{
    if ((self = [super init])) {
	buildOptions = [[NSMutableDictionary alloc] init];
        [self _initUI];
    }
    return self;
}

- (id)initWithProjectDictionary:(NSDictionary *)dict path:(NSString *)path;
{
    NSAssert(dict,@"No valid project dictionary!");
    
    if ((self = [self init])) {
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
  [projectName release];
  [projectPath release];
  [projectDict release];
  
  [browserController release];
  [projectWindow release];
  [buildTargetPanel release];
  
  [buildOptions release];
 
  [projectAttributeInspectorView release];
  [installPathField release];
  [toolField release];
  [ccOptField release];
  [ldOptField release];
  [projectTypeField release];

  [projectProjectInspectorView release];
  [projectFileInspectorView release];
  [fileNameField release];
  [changeFileNameButton release];
 
  [box release];

  [super dealloc];
}

//===========================================================================================
// ==== Accessor methods
//===========================================================================================

- (id)browserController
{
  return browserController;
}

- (NSString *)selectedRootCategory
{
  return [self projectKeyForKeyPath:[browserController pathOfSelectedFile]];
}

- (NSArray *)fileExtensionsForCategory:(NSString *)key
{
  if ([key isEqualToString:PCGModels]) {
    return [NSArray arrayWithObjects:@"gmodel",@"gorm",nil];
  }
  else if ([key isEqualToString:PCClasses]) {
    return [NSArray arrayWithObjects:@"m",nil];
  }
  else if ([key isEqualToString:PCHeaders]) {
    return [NSArray arrayWithObjects:@"h",nil];
  }
  else if ([key isEqualToString:PCOtherSources]) {
    return [NSArray arrayWithObjects:@"c",@"C",nil];
  }
  else if ([key isEqualToString:PCLibraries]) {
    return [NSArray arrayWithObjects:@"so",@"a",@"lib",nil];
  }
  else if ([key isEqualToString:PCSubprojects]) {
    return [NSArray arrayWithObjects:@"subproj",nil];
  }
  else if ([key isEqualToString:PCImages]) {
    return [NSImage imageFileTypes];
    //return [NSArray arrayWithObjects:@"tiff",@"TIFF",@"jpg",@"JPG",@"jpeg",@"JPEG",@"bmp",@"BMP",nil];
  }

  return nil;
}

- (void)setProjectName:(NSString *)aName
{
    [projectName autorelease];
    projectName = [aName copy];
}

- (NSString *)projectName
{
    return projectName;
}

- (NSWindow *)projectWindow
{
  if (!projectWindow) NSLog(@"No window??????");
  
  return projectWindow;
}

- (Class)principalClass
{
    return [self class];
}

//===========================================================================================
// ==== Delegate and manager
//===========================================================================================

- (id)delegate
{
  return delegate;
}

- (void)setDelegate:(id)aDelegate
{
  delegate = aDelegate;
}

- (void)setProjectBuilder:(id<ProjectBuilder>)aBuilder
{
  [projectManager autorelease];
  projectManager = [aBuilder retain];
}

- (id<ProjectBuilder>)projectBuilder
{
  return projectManager;
}

//===========================================================================================
// ==== To be overriden
//===========================================================================================

- (BOOL)writeMakefile
{
    return [projectDict writeToFile:[projectPath stringByAppendingPathComponent:@"PC.project"] atomically:YES];
}

- (BOOL)isValidDictionary:(NSDictionary *)aDict
{
    return NO;
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

//===========================================================================================
// ==== Miscellaneous
//===========================================================================================

- (void)browserDidSelectFileNamed:(NSString *)fileName
{
  [fileNameField setStringValue:fileName];
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
    NSMutableArray *files = [NSMutableArray arrayWithArray:[projectDict objectForKey:type]];
    NSMutableString *newFile = [NSMutableString stringWithString:[file lastPathComponent]];

    if ([type isEqualToString:PCLibraries]) {
      [newFile deleteCharactersInRange:NSMakeRange(0,3)];
      newFile = [newFile stringByDeletingPathExtension];
    }

    if ([files containsObject:newFile]) {
        NSRunAlertPanel(@"Attention!",@"The file %@ is already part of this project!",@"OK",nil,nil,newFile);
        return;
    }

    NSLog(@"<%@ %x>: adding file %@ for key %@",[self class],self,newFile,type);
    
    // Add the new file
    [files addObject:newFile];
    [projectDict setObject:files forKey:type];
    
    // Synchronise the makefile!
    [self writeMakefile];
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
    [self writeMakefile];
}

- (BOOL)removeSelectedFilePermanently:(BOOL)yn
{
    NSString *file = [browserController nameOfSelectedFile];
    NSMutableArray *array;
    NSString *key;
    NSString *otherKey;
    NSString *ext;
    NSString *fn;
    BOOL ret = NO;

    if (!file) {
        return NO;
    }

    key = [self projectKeyForKeyPath:[browserController pathOfSelectedFile]];
    [self removeFile:file forKey:key];

    if ([key isEqualToString:PCClasses]) {
      otherKey = PCHeaders;
      ext = [NSString stringWithString:@"h"];
      
      fn = [file stringByDeletingPathExtension];
      fn = [fn stringByAppendingPathExtension:ext];
      
      if ([self doesAcceptFile:fn forKey:otherKey] == NO) {
	ret = NSRunAlertPanel(@"Removing Header?",@"Should %@ be removed from the project %@ as well?",@"Yes",@"No",nil,fn,[self projectName]);
      }
    }
    else if ([key isEqualToString:PCHeaders]) {
      otherKey = PCClasses;
      ext = [NSString stringWithString:@"m"];
      
      fn = [file stringByDeletingPathExtension];
      fn = [fn stringByAppendingPathExtension:ext];
      
      if ([self doesAcceptFile:fn forKey:otherKey] == NO) {
	ret = NSRunAlertPanel(@"Removing Class?",@"Should %@ be removed from the project %@ as well?",@"Yes",@"No",nil,fn,[self projectName]);
      }
    }

    if (ret) {
      [self removeFile:fn forKey:otherKey];
    }
    
    // Remove the file permanently?!
    if (yn) {
        NSString *pth = [projectPath stringByAppendingPathComponent:file];

        [[NSFileManager defaultManager] removeFileAtPath:pth handler:nil];

	if (ret) {
	  pth = [projectPath stringByAppendingPathComponent:fn];
	  [[NSFileManager defaultManager] removeFileAtPath:pth handler:nil];
	}
    }

    return YES;
}

- (void)renameFile:(NSString *)aFile
{
}

- (BOOL)assignProjectDict:(NSDictionary *)aDict
{
    NSAssert(aDict,@"No valid project dictionary!");

    if (![self isValidDictionary:aDict]) {
        return NO;
    }
    
    [projectDict autorelease];
    projectDict = [[NSMutableDictionary alloc] initWithDictionary:aDict];

    [self setProjectName:[projectDict objectForKey:PCProjectName]];

    [projectWindow setTitle:[NSString stringWithFormat:@"%@ - %@",projectName,projectPath]];

    // Update the GNUmakefile!
    [self writeMakefile];

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
}

- (BOOL)saveAt:(NSString *)projPath
{
}

- (BOOL)saveFileNamed:(NSString *)file
{
}

- (BOOL)saveAllFiles
{
}

- (BOOL)saveAllFilesIfNeeded
{
}

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
}

@end

@implementation PCProject (ProjectBuilding)

- (void)topButtonsPressed:(id)sender
{
  switch ([[sender selectedCell] tag]) {
  case 0:
    [self showBuildView:self];
    break;
  case 1:
    [self showInspector:self];
    break;
  case 2:
    [self showBuildTargetPanel:self];
    break;
  case 3:
    [self showRunView:self];
    break;
  case 4:
  case 5:
  case 6:
    NSRunAlertPanel(@"Help!",@"This feature is not yet implemented! Please contact me if you are interested in volunteering.",@"Of course!",nil,nil);
    break;
  default:
    break;
  }
}

- (void)showBuildView:(id)sender
{
  NSView *view = nil;

  if (!projectBuilder) {
    projectBuilder = [[PCProjectBuilder alloc] initWithProject:self];
  }

  view = [[projectBuilder componentView] retain];
  
  [box setContentView:view];
  [box display];
}

- (void)showRunView:(id)sender
{
  NSView *view = nil;

  if (!projectDebugger) {
    projectDebugger = [[PCProjectDebugger alloc] initWithProject:self];
  }

  view = [[projectDebugger componentView] retain];
  
  [box setContentView:view];
  [box display];
}

- (void)showInspector:(id)sender
{
  [projectManager showInspectorForProject:self];
}

- (id)updatedAttributeView
{
  return projectAttributeInspectorView;
}

- (id)updatedProjectView
{
  return projectProjectInspectorView;
}

- (id)updatedFilesView
{
  return projectFileInspectorView;
}

- (void)showBuildTargetPanel:(id)sender
{
  if (![buildTargetPanel isVisible]) {
    [buildTargetPanel center];
  }
  [buildTargetPanel makeKeyAndOrderFront:self];
}

- (void)setHost:(id)sender
{
  NSString *host = [buildTargetHostField stringValue];
  [buildOptions setObject:host forKey:BUILD_HOST_KEY];
}

- (void)setArguments:(id)sender
{
  NSString *args = [buildTargetArgsField stringValue];
  [buildOptions setObject:args forKey:BUILD_ARGS_KEY];
}

- (NSDictionary *)buildOptions
{
  return (NSDictionary *)buildOptions;
}

@end

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
  
  if (object == buildTargetPanel) {
  }
  else if (object == [self projectWindow]) {
    if ([[self projectWindow] isDocumentEdited]) {
      if (NSRunAlertPanel(@"Project changed!",@"The project %@ has unsaved files! Should they be saved before closing it?",@"Yes",@"No",nil,[self projectName])) {
	[self save];
      }
    }
    
    // The PCProjectController is our delegate!
    [projectManager closeProject:self];
  }
}

@end
