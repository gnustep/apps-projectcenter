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
  NSSplitView *split;
  NSScrollView * scrollView; 
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

  _w_frame = NSMakeRect(100,100,512,320);
  projectWindow = [[NSWindow alloc] initWithContentRect:_w_frame
                                              styleMask:style
                                                backing:NSBackingStoreBuffered
                                                  defer:NO];
  [projectWindow setDelegate:self];
  [projectWindow setMinSize:NSMakeSize(512,320)];

  browser = [[[NSBrowser alloc] initWithFrame:NSMakeRect(30,30,280,400)] autorelease];
  [browser setDelegate:browserController];
  [browser setMaxVisibleColumns:3];
  [browser setAllowsMultipleSelection:NO];

  [browserController setBrowser:browser];
  [browserController setProject:self];

  textView = [[NSTextView alloc] initWithFrame:NSMakeRect(0,0,472,88)];
  [textView setMaxSize:NSMakeSize(1e7, 1e7)];
  [textView setRichText:NO];
  [textView setVerticallyResizable:YES];
  [textView setHorizontallyResizable:YES];
  [textView setAutoresizingMask: NSViewWidthSizable | NSViewHeightSizable];
  [textView setBackgroundColor:[NSColor whiteColor]];
  [[textView textContainer] setWidthTracksTextView:YES];

  scrollView = [[NSScrollView alloc] initWithFrame:NSMakeRect (0,0,496,92)];
  [scrollView setDocumentView:textView];
  [textView setMinSize:NSMakeSize(0.0,[scrollView contentSize].height)];
  [[textView textContainer] setContainerSize:NSMakeSize([scrollView contentSize].width,1e7)];
  [scrollView setHasHorizontalScroller: YES];
  [scrollView setHasVerticalScroller: YES];
  [scrollView setBorderType: NSBezelBorder];
  [scrollView setAutoresizingMask: (NSViewWidthSizable | NSViewHeightSizable)];
  [scrollView autorelease];

  split = [[[NSSplitView alloc] initWithFrame:NSMakeRect(8,0,496,264)] autorelease];  
  [split setAutoresizingMask: (NSViewWidthSizable | NSViewHeightSizable)];
  [split addSubview: browser];
  [split addSubview: scrollView];

  _c_view = [projectWindow contentView];
  [_c_view addSubview:split];

  // Left button matrix
  _w_frame = NSMakeRect(8,268,144,48);
  matrix = [[[NSMatrix alloc] initWithFrame: _w_frame
                                       mode: NSHighlightModeMatrix
                                  prototype: buttonCell
                               numberOfRows: 1
                            numberOfColumns: 3] autorelease];
  [matrix setIntercellSpacing:NSMakeSize(1,1)];
  [matrix setSelectionByRect:YES];
  [matrix setAutoresizingMask: (NSViewMaxXMargin | NSViewMinYMargin)];
  [_c_view addSubview:matrix];

  button = [matrix cellAtRow:0 column:0];
  [button setImagePosition:NSImageOnly];
  [button setImage:IMAGE(@"ProjectCentre_build")];
  [button setButtonType:NSMomentaryPushButton];
  [button setTarget:self];
  [button setAction:@selector(build:)];

  button = [matrix cellAtRow:0 column:1];
  [button setImagePosition:NSImageOnly];
  [button setImage:IMAGE(@"ProjectCentre_settings.tiff")];
  [button setButtonType:NSMomentaryPushButton];
  [button setTarget:self];
  [button setAction:@selector(showInspector:)];

  button = [matrix cellAtRow:0 column:2];
  [button setImagePosition:NSImageOnly];
  [button setImage:IMAGE(@"ProjectCentre_prefs.tiff")];
  [button setTarget:self];
  [button setAction:@selector(showBuildTarget:)];
  [button setButtonType:NSMomentaryPushButton];
  [button setTarget:self];
  [button setAction:@selector(showBuildTargetPanel:)];

  // Right button matrix
  _w_frame = NSMakeRect(304,268,192,48);
  matrix = [[[NSMatrix alloc] initWithFrame: _w_frame
                                       mode: NSHighlightModeMatrix
                                  prototype: buttonCell
                               numberOfRows: 1
                            numberOfColumns: 4] autorelease];
  [matrix setIntercellSpacing:NSMakeSize(1,1)];
  [matrix setSelectionByRect:YES];
  [matrix setAutoresizingMask: (NSViewMinXMargin | NSViewMinYMargin)];
  [_c_view addSubview:matrix];

  button = [matrix cellAtRow:0 column:0];
  [button setImagePosition:NSImageOnly];
  [button setImage:IMAGE(@"ProjectCentre_run.tiff")];
  [button setButtonType:NSMomentaryPushButton];

  button = [matrix cellAtRow:0 column:1];
  [button setImagePosition:NSImageOnly];
  [button setImage:IMAGE(@"ProjectCentre_uml.tiff")];
  [button setButtonType:NSMomentaryPushButton];

  button = [matrix cellAtRow:0 column:2];
  [button setImagePosition:NSImageOnly];
  [button setImage:IMAGE(@"ProjectCentre_documentation.tiff")];
  [button setButtonType:NSMomentaryPushButton];

  button = [matrix cellAtRow:0 column:3];
  [button setImagePosition:NSImageOnly];
  [button setImage:IMAGE(@"ProjectCentre_find.tiff")];
  [button setButtonType:NSMomentaryPushButton];

  // Status
  textField = [[NSTextField alloc] initWithFrame:NSMakeRect(152,296,48,15)];
  [textField setAlignment: NSRightTextAlignment];
  [textField setBordered: NO];
  [textField setEditable: NO];
  [textField setBezeled: NO];
  [textField setDrawsBackground: NO];
  [textField setStringValue:@"Status:"];
  [textField setAutoresizingMask: (NSViewMaxXMargin | 
				   NSViewMinYMargin)];
  [_c_view addSubview:[textField autorelease]];

  // Status message
  buildStatusField = [[NSTextField alloc] initWithFrame:NSMakeRect(204,296,104,15)];
  [buildStatusField setAlignment: NSLeftTextAlignment];
  [buildStatusField setBordered: NO];
  [buildStatusField setEditable: NO];
  [buildStatusField setBezeled: NO];
  [buildStatusField setDrawsBackground: NO];
  [buildStatusField setStringValue:@"waiting..."];
  [buildStatusField setAutoresizingMask: (NSViewMaxXMargin | 
					  NSViewWidthSizable | 
					  NSViewMinYMargin)];
  [_c_view addSubview:[buildStatusField autorelease]];

  // Target
  textField = [[NSTextField alloc] initWithFrame:NSMakeRect(152,272,48,15)];
  [textField setAlignment: NSRightTextAlignment];
  [textField setBordered: NO];
  [textField setBezeled: NO];
  [textField setEditable: NO];
  [textField setDrawsBackground: NO];
  [textField setStringValue:@"Target:"];
  [textField setAutoresizingMask: (NSViewMaxXMargin | 
				   NSViewMinYMargin)];
  [_c_view addSubview:[textField autorelease]];

  // Target message
  targetField = [[NSTextField alloc] initWithFrame:NSMakeRect(204,272,104,15)];
  [targetField setAlignment: NSLeftTextAlignment];
  [targetField setBordered: NO];
  [targetField setEditable: NO];
  [targetField setBezeled: NO];
  [targetField setDrawsBackground: NO];
  [targetField setStringValue:@"Default..."];
  [targetField setAutoresizingMask: (NSViewMaxXMargin | 
				     NSViewWidthSizable | 
				     NSViewMinYMargin)];
  [_c_view addSubview:[targetField autorelease]];

  /*
   * Build Panel
   *
   */

  _w_frame = NSMakeRect(100,100,272,104);
  buildTargetPanel = [[NSWindow alloc] initWithContentRect:_w_frame styleMask:style backing:NSBackingStoreBuffered defer:NO];
  [buildTargetPanel setDelegate:self];
  [buildTargetPanel setReleasedWhenClosed:NO];
  [buildTargetPanel setTitle:@"Build Options"];
  _c_view = [buildTargetPanel contentView];

  buildTargetPopup = [[NSPopUpButton alloc] initWithFrame:NSMakeRect(72,24,184,20)];
  [buildTargetPopup addItemWithTitle:@"Default"];
  [buildTargetPopup addItemWithTitle:@"Debug"];
  [buildTargetPopup addItemWithTitle:@"Profile"];
  [buildTargetPopup addItemWithTitle:@"Install"];
  [buildTargetPopup autorelease];
  [buildTargetPopup setTarget:self];
  [buildTargetPopup setAction:@selector(setTarget:)];
  [_c_view addSubview:buildTargetPopup];

  // Target (popup)
  textField = [[NSTextField alloc] initWithFrame:NSMakeRect(16,24,56,21)];
  [textField setAlignment: NSRightTextAlignment];
  [textField setBordered: NO];
  [textField setEditable: NO];
  [textField setBezeled: NO];
  [textField setDrawsBackground: NO];
  [textField setStringValue:@"Target:"];
  [_c_view addSubview:[textField autorelease]];

  // Host
  textField = [[NSTextField alloc] initWithFrame:NSMakeRect(16,48,56,21)];
  [textField setAlignment: NSRightTextAlignment];
  [textField setBordered: NO];
  [textField setEditable: NO];
  [textField setBezeled: NO];
  [textField setDrawsBackground: NO];
  [textField setStringValue:@"Host:"];
  [_c_view addSubview:[textField autorelease]];

  // Host message
  buildTargetHostField = [[NSTextField alloc] initWithFrame:NSMakeRect(72,48,184,21)];
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
  textField = [[NSTextField alloc] initWithFrame:NSMakeRect(12,68,60,21)];
  [textField setAlignment: NSRightTextAlignment];
  [textField setBordered: NO];
  [textField setEditable: NO];
  [textField setBezeled: NO];
  [textField setDrawsBackground: NO];
  [textField setStringValue:@"Arguments:"];
  [_c_view addSubview:[textField autorelease]];

  // Args message
  buildTargetArgsField = [[NSTextField alloc] initWithFrame:NSMakeRect(72,68,184,21)];
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
        _target = defaultTarget;

	buildOptions = [[NSMutableDictionary alloc] init];
	[buildOptions setObject:TARGET_MAKE forKey:BUILD_KEY];

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
    return [NSArray arrayWithObjects:@"tiff",@"TIFF",@"jpg",@"JPG",@"jpeg",@"JPEG",@"bmp",@"BMP",nil];
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

- (id)textView
{
  return textView;
}

//===========================================================================================
// ==== Miscellaneous
//===========================================================================================

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

- (void)setTarget:(id)sender
{
  _target = [buildTargetPopup indexOfSelectedItem];

  [buildOptions setObject:[NSNumber numberWithInt:_target] forKey:BUILD_KEY];
}

- (void)setHost:(id)sender
{
  NSString *host = [buildTargetHostField stringValue];
  [buildOptions setObject:host forKey:BUILD_HOST_KEY];

  NSLog(@"New host %@",host);
}

- (void)setArguments:(id)sender
{
  NSString *args = [buildTargetArgsField stringValue];
  [buildOptions setObject:args forKey:BUILD_ARGS_KEY];
}

- (void)build:(id)sender
{
  [[PCProjectBuilder sharedBuilder] showPanelWithProject:self options:buildOptions];
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

    NSLog(@"<%@ %x>: content at path %@",[self class],self,keyPath);

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

@implementation PCProject (TextDelegate)

- (void)textDidEndEditing:(NSNotification *)aNotification
{
}

@end

