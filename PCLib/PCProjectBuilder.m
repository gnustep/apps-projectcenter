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

#import "PCProjectBuilder.h"
#import "PCProject.h"
#import "PCProjectManager.h"

#import <AppKit/AppKit.h>

#ifndef IMAGE
#define IMAGE(X) [[[NSImage alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForImageResource:(X)]] autorelease]
#endif

#ifndef NOTIFICATION_CENTER
#define NOTIFICATION_CENTER [NSNotificationCenter defaultCenter]
#endif

@interface PCProjectBuilder (CreateUI)

- (void)_initUI;

@end

@implementation PCProjectBuilder (CreateUI)

- (void)_initUI
{
  NSView *_c_view;
  unsigned int style = NSTitledWindowMask | NSClosableWindowMask | 
                       NSMiniaturizableWindowMask | NSResizableWindowMask;
  NSSplitView *split;
  NSScrollView *scrollView1; 
  NSScrollView *scrollView2; 
  NSMatrix* matrix;
  NSRect _w_frame;
  NSButtonCell* buttonCell = [[[NSButtonCell alloc] init] autorelease];
  id button;
  id textField;

  /*
   * Build Window
   *
   */

  _w_frame = NSMakeRect(100,100,512,320);
  buildWindow = [[NSWindow alloc] initWithContentRect:_w_frame
				  styleMask:style
				  backing:NSBackingStoreBuffered
				  defer:NO];
  [buildWindow setDelegate:self];
  [buildWindow setReleasedWhenClosed:NO];
  [buildWindow setMinSize:NSMakeSize(512,320)];
  [buildWindow setFrameAutosaveName:@"Builder"];

  logOutput = [[NSTextView alloc] initWithFrame:NSMakeRect(0,0,472,80)];
  [logOutput setMaxSize:NSMakeSize(1e7, 1e7)];
  [logOutput setRichText:NO];
  [logOutput setEditable:NO];
  [logOutput setSelectable:YES];
  [logOutput setVerticallyResizable:YES];
  [logOutput setHorizontallyResizable:NO];
  [logOutput setAutoresizingMask: NSViewWidthSizable | NSViewHeightSizable];
  [logOutput setBackgroundColor:[NSColor lightGrayColor]];
  [[logOutput textContainer] setWidthTracksTextView:YES];

  scrollView1 = [[NSScrollView alloc] initWithFrame:NSMakeRect (0,0,496,92)];
  [scrollView1 setDocumentView:logOutput];
  [logOutput setMinSize:NSMakeSize(0.0,[scrollView1 contentSize].height)];
  [[logOutput textContainer] setContainerSize:NSMakeSize([scrollView1 contentSize].width,1e7)];
  [scrollView1 setHasHorizontalScroller: NO];
  [scrollView1 setHasVerticalScroller: YES];
  [scrollView1 setBorderType: NSBezelBorder];
  [scrollView1 setAutoresizingMask:(NSViewWidthSizable | NSViewHeightSizable)];
  [scrollView1 autorelease];

  /*
   *
   */

  errorOutput = [[NSTextView alloc] initWithFrame:NSMakeRect(0,0,472,80)];
  [errorOutput setMaxSize:NSMakeSize(1e7, 1e7)];
  [errorOutput setRichText:NO];
  [errorOutput setEditable:NO];
  [errorOutput setSelectable:YES];
  [errorOutput setVerticallyResizable:YES];
  [errorOutput setHorizontallyResizable:NO];
  [errorOutput setAutoresizingMask: NSViewWidthSizable | NSViewHeightSizable];
  [errorOutput setBackgroundColor:[NSColor whiteColor]];
  [[errorOutput textContainer] setWidthTracksTextView:YES];

  scrollView2 = [[NSScrollView alloc] initWithFrame:NSMakeRect (0,0,496,92)];
  [scrollView2 setDocumentView:errorOutput];
  [errorOutput setMinSize:NSMakeSize(0.0,[scrollView2 contentSize].height)];
  [[errorOutput textContainer] setContainerSize:NSMakeSize([scrollView2 contentSize].width,1e7)];
  [scrollView2 setHasHorizontalScroller:NO];
  [scrollView2 setHasVerticalScroller:YES];
  [scrollView2 setBorderType: NSBezelBorder];
  [scrollView2 setAutoresizingMask:(NSViewWidthSizable | NSViewHeightSizable)];
  [scrollView2 autorelease];

  split = [[[NSSplitView alloc] initWithFrame:NSMakeRect(8,0,496,264)] autorelease];  
  [split setAutoresizingMask: (NSViewWidthSizable | NSViewHeightSizable)];
  [split addSubview: scrollView1];
  [split addSubview: scrollView2];

  _c_view = [buildWindow contentView];
  [_c_view addSubview:split];

  /*
   * 5 build Buttons
   */

  _w_frame = NSMakeRect(8,272,244,44);
  matrix = [[[NSMatrix alloc] initWithFrame: _w_frame
                                       mode: NSHighlightModeMatrix
                                  prototype: buttonCell
                               numberOfRows: 1
                            numberOfColumns: 5] autorelease];
  [matrix sizeToCells];
  [matrix setSelectionByRect:YES];
  [matrix setAutoresizingMask: (NSViewMaxXMargin | NSViewMinYMargin)];
  [matrix setTarget:self];
  [matrix setAction:@selector(build:)];
  [_c_view addSubview:matrix];

  button = [matrix cellAtRow:0 column:0];
  [button setTag:0];
  //[button setImagePosition:NSNoImage];
  [button setImagePosition:NSImageOnly];
  [button setImage:IMAGE(@"ProjectCenter_make")];
  [button setButtonType:NSMomentaryPushButton];
  [button setTitle:@"Build"];

  button = [matrix cellAtRow:0 column:1];
  [button setTag:1];
  //[button setImagePosition:NSNoImage];
  [button setImagePosition:NSImageOnly];
  [button setImage:IMAGE(@"ProjectCenter_clean")];
  [button setButtonType:NSMomentaryPushButton];
  [button setTitle:@"Clean"];

  button = [matrix cellAtRow:0 column:2];
  [button setTag:2];
  //[button setImagePosition:NSNoImage];
  [button setImagePosition:NSImageOnly];
  [button setImage:IMAGE(@"ProjectCenter_debug")];
  [button setButtonType:NSMomentaryPushButton];
  [button setTitle:@"Debug"];

  button = [matrix cellAtRow:0 column:3];
  [button setTag:3];
  //[button setImagePosition:NSNoImage];
  [button setImagePosition:NSImageOnly];
  [button setImage:IMAGE(@"ProjectCenter_profile")];
  [button setButtonType:NSMomentaryPushButton];
  [button setTitle:@"Profile"];

  button = [matrix cellAtRow:0 column:4];
  [button setTag:4];
  //[button setImagePosition:NSNoImage];
  [button setImagePosition:NSImageOnly];
  [button setImage:IMAGE(@"ProjectCenter_install")];
  [button setButtonType:NSMomentaryPushButton];
  [button setTitle:@"Install"];

  /*
   * Status
   */

  textField = [[NSTextField alloc] initWithFrame:NSMakeRect(256,296,48,15)];
  [textField setAlignment: NSRightTextAlignment];
  [textField setBordered: NO];
  [textField setEditable: NO];
  [textField setBezeled: NO];
  [textField setDrawsBackground: NO];
  [textField setStringValue:@"Status:"];
  [textField setAutoresizingMask: (NSViewMaxXMargin | 
				   NSViewMinYMargin)];
  [_c_view addSubview:[textField autorelease]];

  /*
   * Status message
   */

  buildStatusField = [[NSTextField alloc] initWithFrame:NSMakeRect(308,296,104,15)];
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

  /*
   * Target
   */

  textField = [[NSTextField alloc] initWithFrame:NSMakeRect(256,272,48,15)];
  [textField setAlignment: NSRightTextAlignment];
  [textField setBordered: NO];
  [textField setBezeled: NO];
  [textField setEditable: NO];
  [textField setDrawsBackground: NO];
  [textField setStringValue:@"Target:"];
  [textField setAutoresizingMask: (NSViewMaxXMargin | 
				   NSViewMinYMargin)];
  [_c_view addSubview:[textField autorelease]];

  /*
   * Target message
   */

  targetField = [[NSTextField alloc] initWithFrame:NSMakeRect(308,272,104,15)];
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
}

@end

@implementation PCProjectBuilder

static PCProjectBuilder *_builder;

+ (id)sharedBuilder
{
  if (!_builder) {
    _builder = [[PCProjectBuilder alloc] init];
  }
  return _builder;
}

- (id)init
{
  if ((self = [super init])) {
    [self _initUI];
    makePath = [[NSString stringWithString:@"/usr/bin/make"] retain];
    buildTasks = [[NSMutableDictionary dictionary] retain];

    [NOTIFICATION_CENTER addObserver:self selector:@selector(projectDidChange:) name:ActiveProjectDidChangeNotification object:nil];
  }
  return self;
}

- (void)dealloc
{
  [NOTIFICATION_CENTER removeObserver:self];

  [buildWindow release];
  [makePath release];
  [buildTasks release];

  [super dealloc];
}

- (void)showPanelWithProject:(PCProject *)proj options:(NSDictionary *)options;
{
  if (![buildWindow isVisible]) {
    [buildWindow setFrameUsingName:@"Builder"];
  }
  [buildWindow makeKeyAndOrderFront:self];

  currentProject = proj;
  currentOptions = options;

  [buildWindow setTitle:[proj projectName]];
}

- (void)build:(id)sender
{
  NSString *tg = nil;
  NSTask *makeTask;
  NSMutableArray *args;
  NSPipe *logPipe;
  NSPipe *errorPipe;
  NSDictionary *optionDict;
  NSString *status;
  NSString *target;

  if (!currentProject) {
    return;
  }

  logPipe = [NSPipe pipe];
  readHandle = [[logPipe fileHandleForReading] retain];

  errorPipe = [NSPipe pipe];
  errorReadHandle = [[errorPipe fileHandleForReading] retain];

  makeTask = [[NSTask alloc] init];

  optionDict = [currentProject buildOptions];
  args = [NSMutableArray array];

  switch ([[sender selectedCell] tag]) {
  case 0:
    status = [NSString stringWithString:@"Building..."];
    target = [NSString stringWithString:@"Default"];
    break;
  case 1:
    if (NSRunAlertPanel(@"Clean Project?",@"Really clean %@?",@"Yes",@"No",nil,[currentProject projectName]) == NSAlertAlternateReturn) {
      return;
    }
    status = [NSString stringWithString:@"Cleaning..."];
    target = [NSString stringWithString:@"Clean"];
    [args addObject:@"clean"];
    break;
  case 2:
    status = [NSString stringWithString:@"Building..."];
    target = [NSString stringWithString:@"Debug"];
    [args addObject:@"debug=yes"];
    break;
  case 3:
    status = [NSString stringWithString:@"Building..."];
    target = [NSString stringWithString:@"Profile"];
    [args addObject:@"profile=yes"];
    [args addObject:@"static=yes"];
    break;
  case 4:
    status = [NSString stringWithString:@"Installing..."];
    target = [NSString stringWithString:@"Install"];
    [args addObject:@"install"];
    break;
  }

  [buildStatusField setStringValue:status];  
  [targetField setStringValue:target];  

  [NOTIFICATION_CENTER addObserver:self 
		       selector:@selector(logStdOut:) 
		       name:NSFileHandleDataAvailableNotification
		       object:readHandle];
  
  [NOTIFICATION_CENTER addObserver:self 
		       selector:@selector(logErrOut:) 
		       name:NSFileHandleDataAvailableNotification
		       object:errorReadHandle];
  
  [NOTIFICATION_CENTER addObserver: self
		       selector: @selector(buildDidTerminate:)
		       name: NSTaskDidTerminateNotification
		       object: makeTask];  
  
  [makeTask setArguments:args];  
  [makeTask setCurrentDirectoryPath:[currentProject projectPath]];
  [makeTask setLaunchPath:makePath];
  
  [makeTask setStandardOutput:logPipe];
  [makeTask setStandardError:errorPipe];

  [logOutput setString:@""];
  [readHandle waitForDataInBackgroundAndNotify];

  [errorOutput setString:@""];
  [errorReadHandle waitForDataInBackgroundAndNotify];
  
  [makeTask launch];
  [makeTask waitUntilExit];

  [buildStatusField setStringValue:@"Waiting..."];  
  [targetField setStringValue:@""];  

  [NOTIFICATION_CENTER removeObserver:self 
		       name:NSFileHandleDataAvailableNotification
		       object:readHandle];
  
  [NOTIFICATION_CENTER removeObserver:self 
		       name:NSFileHandleDataAvailableNotification
		       object:errorReadHandle];
  
  [NOTIFICATION_CENTER removeObserver:self 
		       name:NSTaskDidTerminateNotification 
		       object:makeTask];

  [readHandle release];
  [errorReadHandle release];  
  [makeTask autorelease];
}

- (void)logStdOut:(NSNotification *)aNotif
{
  NSData *data;

  if ((data = [readHandle availableData])) {
    [self logData:data error:NO];
  }

  [readHandle waitForDataInBackgroundAndNotifyForModes:nil];
}

- (void)logErrOut:(NSNotification *)aNotif
{
  NSData *data;

  if ((data = [errorReadHandle availableData])) {
    [self logData:data error:YES];
  }

  [errorReadHandle waitForDataInBackgroundAndNotifyForModes:nil];
}

- (void)buildDidTerminate:(NSNotification *)aNotif
{
  int status = [[aNotif object] terminationStatus];

  if (status == 0) {
    [self logString:@"*** Build Succeeded!\n" error:NO newLine:YES];
  } 
  else {
    [self logString:@"*** Build Failed!" error:YES newLine:YES];
    [[logOutput window] orderFront:self];
  }
}

- (void)projectDidChange:(NSNotification *)aNotif
{
  PCProject *project = [aNotif object];

  if (project) {
    currentProject = project;
    [buildWindow setTitle:[project projectName]];
  }
  else {
    currentProject = nil;
    [buildWindow orderOut:self];
  }
}

@end

@implementation PCProjectBuilder (BuildLogging)

- (void)logString:(NSString *)string error:(BOOL)yn
{
  [self logString:string error:yn newLine:YES];
}

- (void)logString:(NSString *)str error:(BOOL)yn newLine:(BOOL)newLine
{
  NSTextView *out = (yn)?errorOutput:logOutput;

  [out replaceCharactersInRange:NSMakeRange([[out string] length],0) withString:str];

  if (newLine) {
    [out replaceCharactersInRange:NSMakeRange([[out string] length], 0) withString:@"\n"];
  }
  else {
    [out replaceCharactersInRange:NSMakeRange([[out string] length], 0) withString:@" "];
  }
  
  [out scrollRangeToVisible:NSMakeRange([[out string] length], 0)];
}

- (void)logData:(NSData *)data error:(BOOL)yn
{
  NSString *s = [[NSString alloc] initWithData:data 
				  encoding:[NSString defaultCStringEncoding]];

  [self logString:s error:yn newLine:YES];
  [s autorelease];
}

@end



