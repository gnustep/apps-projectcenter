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

#import "PCProjectDebugger.h"
#import "PCProject.h"
#import "PCProjectManager.h"

#import <AppKit/AppKit.h>

#ifndef IMAGE
#define IMAGE(X) [[[NSImage alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForImageResource:(X)]] autorelease]
#endif

#ifndef NOTIFICATION_CENTER
#define NOTIFICATION_CENTER [NSNotificationCenter defaultCenter]
#endif

@interface PCProjectDebugger (CreateUI)

- (void)_createComponentView;

@end

@implementation PCProjectDebugger (CreateUI)

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
   *
   */

  stdOut = [[NSTextView alloc] initWithFrame:NSMakeRect(0,0,516,80)];
  [stdOut setMaxSize:NSMakeSize(1e7, 1e7)];
  // [stdOut setMinSize:NSMakeSize(516, 48)];
  [stdOut setRichText:NO];
  [stdOut setEditable:NO];
  [stdOut setSelectable:YES];
  [stdOut setAutoresizingMask: NSViewWidthSizable | NSViewHeightSizable];
  [stdOut setBackgroundColor:[NSColor colorWithDeviceRed:0.95
				      green:0.75
				      blue:0.85
				      alpha:1.0]];
  [[stdOut textContainer] setWidthTracksTextView:YES];

  scrollView1 = [[NSScrollView alloc] initWithFrame:NSMakeRect (0,0,540,92)];
  [scrollView1 setDocumentView:stdOut];
  [[stdOut textContainer] setContainerSize:NSMakeSize([scrollView1 contentSize].width,1e7)];
  [scrollView1 setHasHorizontalScroller: NO];
  [scrollView1 setHasVerticalScroller: YES];
  [scrollView1 setBorderType: NSBezelBorder];
  [scrollView1 setAutoresizingMask:(NSViewWidthSizable | NSViewHeightSizable)];

  /*
   *
   */

  stdError = [[NSTextView alloc] initWithFrame:NSMakeRect(0,0,516,32)];
  [stdError setMaxSize:NSMakeSize(1e7, 1e7)];
  //[stdError setMinSize:NSMakeSize(516, 48)];
  [stdError setRichText:NO];
  [stdError setEditable:NO];
  [stdError setSelectable:YES];
  [stdError setAutoresizingMask: NSViewWidthSizable | NSViewHeightSizable];
  [stdError setBackgroundColor:[NSColor whiteColor]];
  [[stdError textContainer] setWidthTracksTextView:YES];

  scrollView2 = [[NSScrollView alloc] initWithFrame:NSMakeRect (0,0,540,46)];
  [scrollView2 setDocumentView:stdError];
  [[stdError textContainer] setContainerSize:NSMakeSize([scrollView2 contentSize].width,1e7)];
  [scrollView2 setHasHorizontalScroller:NO];
  [scrollView2 setHasVerticalScroller:YES];
  [scrollView2 setBorderType: NSBezelBorder];
  [scrollView2 setAutoresizingMask:(NSViewWidthSizable | NSViewHeightSizable)];

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
   */

  _w_frame = NSMakeRect(0,194,88,44);
  matrix = [[NSMatrix alloc] initWithFrame: _w_frame
			     mode: NSHighlightModeMatrix
			     prototype: buttonCell
			     numberOfRows: 1
			     numberOfColumns: 2];
  [matrix sizeToCells];
  [matrix setSelectionByRect:YES];
  [matrix setAutoresizingMask: (NSViewMaxXMargin | NSViewMinYMargin)];
  [matrix setTarget:self];
  [matrix setAction:@selector(run:)];
  [componentView addSubview:matrix];

  RELEASE(matrix);

  button = [matrix cellAtRow:0 column:0];
  [button setTag:0];
  [button setImagePosition:NSImageOnly];
  [button setImage:IMAGE(@"ProjectCenter_run")];
  [button setButtonType:NSMomentaryPushButton];
  [button setTitle:@"Run"];

  button = [matrix cellAtRow:0 column:1];
  [button setTag:1];
  [button setImagePosition:NSImageOnly];
  //[button setImage:IMAGE(@"ProjectCenter_clean")];
  [button setButtonType:NSMomentaryPushButton];
  [button setTitle:@"Clean"];
}

@end

@implementation PCProjectDebugger

- (id)initWithProject:(PCProject *)aProject
{
  NSAssert(aProject,@"No project specified!");

  if ((self = [super init])) {
    currentProject = aProject;
  }
  return self;
}

- (void)dealloc
{
  [componentView release];

  RELEASE(stdOut);
  RELEASE(stdError);

  [super dealloc];
}

- (NSView *)componentView;
{
  if (!componentView) {
    [self _createComponentView];
  }

  return componentView;
}

- (void)run:(id)sender
{
  NSTask *makeTask;
  NSMutableArray *args;
  NSPipe *logPipe;
  NSPipe *errorPipe;
  NSString *openPath;

  logPipe = [NSPipe pipe];
  readHandle = [[logPipe fileHandleForReading] retain];

  errorPipe = [NSPipe pipe];
  errorReadHandle = [[errorPipe fileHandleForReading] retain];

  makeTask = [[NSTask alloc] init];
  args = [NSMutableArray array];

  /*
   * Ugly hack! We should ask the porject itself about the req. information!
   *
   */

  if ([currentProject isKindOfClass:NSClassFromString(@"PCAppProject")]) {
    NSString *tname;

    openPath = [NSString stringWithString:@"openapp"];
    tname = [[currentProject projectName] stringByAppendingPathExtension:@"app"];
    [args addObject:tname];
  }
  else if ([currentProject isKindOfClass:NSClassFromString(@"PCToolProject")]) {
    openPath = [NSString stringWithString:@"opentool"];
    [args addObject:[currentProject projectName]];
  }
  else {
    [NSException raise:@"PCInternalDevException" format:@"Unknown executable project type!"];
    return;
  }

  /*
   * Debugging, running, ...
   */

  switch ([[sender selectedCell] tag]) {
  case 0:
    break;
  }

  /*
   * Setting everything up
   */

  [NOTIFICATION_CENTER addObserver:self 
		       selector:@selector(logStdOut:) 
		       name:NSFileHandleDataAvailableNotification
		       object:readHandle];
  
  [NOTIFICATION_CENTER addObserver:self 
		       selector:@selector(logErrOut:) 
		       name:NSFileHandleDataAvailableNotification
		       object:errorReadHandle];
  
  [makeTask setArguments:args];  
  [makeTask setCurrentDirectoryPath:[currentProject projectPath]];
  [makeTask setLaunchPath:openPath];
  
  [makeTask setStandardOutput:logPipe];
  [makeTask setStandardError:errorPipe];

  [stdOut setString:@""];
  [readHandle waitForDataInBackgroundAndNotify];

  [stdError setString:@""];
  [errorReadHandle waitForDataInBackgroundAndNotify];

  /*
   * Go! Later on this will be handled much more optimised!
   *
   */
  
  [makeTask launch];
  [makeTask waitUntilExit];

  /*
   * Clean up...
   *
   */

  [NOTIFICATION_CENTER removeObserver:self 
		       name:NSFileHandleDataAvailableNotification
		       object:readHandle];
  
  [NOTIFICATION_CENTER removeObserver:self 
		       name:NSFileHandleDataAvailableNotification
		       object:errorReadHandle];
  
  RELEASE(readHandle);
  RELEASE(errorReadHandle);  
  RELEASE(makeTask);
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

@end

@implementation PCProjectDebugger (BuildLogging)

- (void)logString:(NSString *)string error:(BOOL)yn
{
  [self logString:string error:yn newLine:YES];
}

- (void)logString:(NSString *)str error:(BOOL)yn newLine:(BOOL)newLine
{
  NSTextView *out = (yn)?stdError:stdOut;

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
