/*
   GNUstep ProjectCenter - http://www.gnustep.org

   Copyright (C) 2001 Free Software Foundation

   Author: Philippe C.D. Robert <phr@3dkit.org>

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

#define DEFAULT_RPM_PATH @"/usr/src/redhat/SOURCES/"

@interface PCProjectBuilder (CreateUI)

- (void)_createComponentView;

@end

@implementation PCProjectBuilder (CreateUI)

- (void)_createComponentView
{
  NSSplitView *split;
  NSScrollView *scrollView1; 
  NSScrollView *scrollView2; 
  NSMatrix* matrix;
  NSRect _w_frame;
  NSButtonCell* buttonCell = [[[NSButtonCell alloc] init] autorelease];
  id button;
  id textField;

  componentView = [[NSBox alloc] initWithFrame:NSMakeRect(0,0,544,248)];
  [componentView setTitlePosition:NSNoTitle];
  [componentView setBorderType:NSNoBorder];
  [componentView setAutoresizingMask:NSViewWidthSizable | NSViewHeightSizable];

  /*
   */

  scrollView1 = [[NSScrollView alloc] initWithFrame:NSMakeRect (0,0,540,46)];

  [scrollView1 setHasHorizontalScroller: NO];
  [scrollView1 setHasVerticalScroller: YES];
  [scrollView1 setBorderType: NSBezelBorder];
  [scrollView1 setAutoresizingMask:(NSViewWidthSizable | NSViewHeightSizable)];

  logOutput = [[NSTextView alloc] initWithFrame:[[scrollView1 contentView] frame]];

  [logOutput setRichText:NO];
  [logOutput setEditable:NO];
  [logOutput setSelectable:YES];
  [logOutput setAutoresizingMask: NSViewWidthSizable | NSViewHeightSizable];
  [logOutput setBackgroundColor:[NSColor lightGrayColor]];
  [[logOutput textContainer] setWidthTracksTextView:YES];
  [[logOutput textContainer] setHeightTracksTextView:YES];
  [logOutput setHorizontallyResizable: NO];
  [logOutput setVerticallyResizable: YES];
  [logOutput setMinSize: NSMakeSize (0, 0)];
  [logOutput setMaxSize: NSMakeSize (1E7, 1E7)];
  [[logOutput textContainer] setContainerSize: 
                               NSMakeSize ([logOutput frame].size.width,1e7)];
  [[logOutput textContainer] setWidthTracksTextView:YES];

  [scrollView1 setDocumentView:logOutput];

  /*
   *
   */

  scrollView2 = [[NSScrollView alloc] initWithFrame:NSMakeRect (0,0,540,92)];

  [scrollView2 setHasHorizontalScroller:NO];
  [scrollView2 setHasVerticalScroller:YES];
  [scrollView2 setBorderType: NSBezelBorder];
  [scrollView2 setAutoresizingMask:(NSViewWidthSizable | NSViewHeightSizable)];

  errorOutput = [[NSTextView alloc] initWithFrame:[[scrollView2 contentView] frame]];

  [errorOutput setRichText:NO];
  [errorOutput setEditable:NO];
  [errorOutput setSelectable:YES];
  [errorOutput setAutoresizingMask: NSViewWidthSizable | NSViewHeightSizable];
  [errorOutput setBackgroundColor:[NSColor whiteColor]];
  [errorOutput setHorizontallyResizable: NO];  
  [errorOutput setVerticallyResizable: YES];
  [errorOutput setMinSize: NSMakeSize (0, 0)];
  [errorOutput setMaxSize: NSMakeSize (1E7, 1E7)];
  [[errorOutput textContainer] setContainerSize: 
				 NSMakeSize ([errorOutput frame].size.width, 1e7)];

  [[errorOutput textContainer] setWidthTracksTextView:YES];
  //[[errorOutput textContainer] setHeightTracksTextView:YES];

  [scrollView2 setDocumentView:errorOutput];

  split = [[NSSplitView alloc] initWithFrame:NSMakeRect(0,0,540,188)];  
  [split setAutoresizingMask: (NSViewWidthSizable | NSViewHeightSizable)];
  [split addSubview: scrollView1];
  [split addSubview: scrollView2];
  [split adjustSubviews];
  
  [componentView addSubview:split];

  RELEASE(scrollView1);
  RELEASE(scrollView2);
  RELEASE(split);

  /*
   * 6 build Buttons
   */

  _w_frame = NSMakeRect(0,194,272,44);
  matrix = [[NSMatrix alloc] initWithFrame: _w_frame
			     mode: NSHighlightModeMatrix
			     prototype: buttonCell
			     numberOfRows:1
			     numberOfColumns:6];
  [matrix sizeToCells];
  [matrix setSelectionByRect:YES];
  [matrix setAutoresizingMask: (NSViewMaxXMargin | NSViewMinYMargin)];
  [matrix setTarget:self];
  [matrix setAction:@selector(build:)];
  [componentView addSubview:matrix];

  RELEASE(matrix);

  button = [matrix cellAtRow:0 column:0];
  [button setTag:0];
  [button setImagePosition:NSImageOnly];
  [button setImage:IMAGE(@"ProjectCenter_make")];
  [button setButtonType:NSMomentaryPushButton];
  [button setTitle:@"Build"];

  button = [matrix cellAtRow:0 column:1];
  [button setTag:1];
  [button setImagePosition:NSImageOnly];
  [button setImage:IMAGE(@"ProjectCenter_clean")];
  [button setButtonType:NSMomentaryPushButton];
  [button setTitle:@"Clean"];

  button = [matrix cellAtRow:0 column:2];
  [button setTag:2];
  [button setImagePosition:NSImageOnly];
  [button setImage:IMAGE(@"ProjectCenter_debug")];
  [button setButtonType:NSMomentaryPushButton];
  [button setTitle:@"Debug"];

  button = [matrix cellAtRow:0 column:3];
  [button setTag:3];
  [button setImagePosition:NSImageOnly];
  [button setImage:IMAGE(@"ProjectCenter_profile")];
  [button setButtonType:NSMomentaryPushButton];
  [button setTitle:@"Profile"];

  button = [matrix cellAtRow:0 column:4];
  [button setTag:4];
  [button setImagePosition:NSImageOnly];
  [button setImage:IMAGE(@"ProjectCenter_install")];
  [button setButtonType:NSMomentaryPushButton];
  [button setTitle:@"Install"];

  button = [matrix cellAtRow:0 column:5];
  [button setTag:5];
  [button setImagePosition:NSImageOnly];
  [button setImage:IMAGE(@"ProjectCenter_rpm")];
  [button setButtonType:NSMomentaryPushButton];
  [button setTitle:@"Packaging"];

  /*
   * Status
   */

  textField = [[NSTextField alloc] initWithFrame:NSMakeRect(288,220,48,15)];
  [textField setAlignment: NSRightTextAlignment];
  [textField setBordered: NO];
  [textField setEditable: NO];
  [textField setBezeled: NO];
  [textField setDrawsBackground: NO];
  [textField setStringValue:@"Status:"];
  [textField setAutoresizingMask: (NSViewMaxXMargin | 
				   NSViewMinYMargin)];
  [componentView addSubview:textField];

  RELEASE(textField);

  /*
   * Status message
   */

  buildStatusField = [[NSTextField alloc] initWithFrame:NSMakeRect(340,220,104,15)];
  [buildStatusField setAlignment: NSLeftTextAlignment];
  [buildStatusField setBordered: NO];
  [buildStatusField setEditable: NO];
  [buildStatusField setBezeled: NO];
  [buildStatusField setDrawsBackground: NO];
  [buildStatusField setStringValue:@"waiting..."];
  [buildStatusField setAutoresizingMask: (NSViewMaxXMargin | 
					  NSViewWidthSizable | 
					  NSViewMinYMargin)];
  [componentView addSubview:buildStatusField];

  RELEASE(buildStatusField);

  /*
   * Target
   */

  textField = [[NSTextField alloc] initWithFrame:NSMakeRect(288,196,48,15)];
  [textField setAlignment: NSRightTextAlignment];
  [textField setBordered: NO];
  [textField setBezeled: NO];
  [textField setEditable: NO];
  [textField setDrawsBackground: NO];
  [textField setStringValue:@"Target:"];
  [textField setAutoresizingMask: (NSViewMaxXMargin | 
				   NSViewMinYMargin)];
  [componentView addSubview:textField];

  RELEASE(textField);

  /*
   * Target message
   */

  targetField = [[NSTextField alloc] initWithFrame:NSMakeRect(340,196,104,15)];
  [targetField setAlignment: NSLeftTextAlignment];
  [targetField setBordered: NO];
  [targetField setEditable: NO];
  [targetField setBezeled: NO];
  [targetField setDrawsBackground: NO];
  [targetField setStringValue:@"Default..."];
  [targetField setAutoresizingMask: (NSViewMaxXMargin | 
				     NSViewWidthSizable | 
				     NSViewMinYMargin)];
  [componentView addSubview:targetField];

  RELEASE(targetField);
}

@end

@implementation PCProjectBuilder

- (id)initWithProject:(PCProject *)aProject
{
  NSAssert(aProject,@"No project specified!");

  if ((self = [super init])) {
    makePath = [[NSString stringWithString:@"/usr/bin/make"] retain];
    currentProject = aProject;
  }
  return self;
}

- (void)dealloc
{
  [componentView release];
  [makePath release];

  [super dealloc];
}

- (NSView *)componentView;
{
  if (!componentView) {
    [self _createComponentView];
  }

  return componentView;
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
  SEL postProcess = NULL;

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
    [args addObject:@"distclean"];
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
  case 5:
    status = [NSString stringWithString:@"Packaging..."];
    target = [NSString stringWithString:@"Making RPM"];
    [args addObject:@"specfile"];
    postProcess = @selector(copyPackageTo:);

    NSRunAlertPanel(@"Creating RPM SPEC",@"After creating the RPM SPEC file you have to invoke \"rpm -ba %@.spec\" in the project directory.\nThis only works if you made a \"make install\" before!",@"OK",nil,nil,[currentProject projectName]);     
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

  if (postProcess) {
    [self performSelector:postProcess];
    postProcess = NULL;
  }
  
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

  RELEASE(readHandle);
  RELEASE(errorReadHandle);  
  AUTORELEASE(makeTask);
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

- (void)copyPackageTo:(NSString *)path
{
  NSString *dest;
  NSString *source = nil;

  if (!path) {
    dest = [NSString stringWithString:DEFAULT_RPM_PATH];
  }
  else {
    dest = path;
  }

  // Create the tar.gz package

  // Copy it
  if (source) {
    [[NSFileManager defaultManager] copyPath:source toPath:dest handler:nil];
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




