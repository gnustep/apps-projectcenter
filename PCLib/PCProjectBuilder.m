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
  NSTextView *textView2;
  NSMatrix* matrix;
  NSRect _w_frame;
  NSButtonCell* buttonCell = [[[NSButtonCell alloc] init] autorelease];
  id button;

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

  logOutput = [[NSTextView alloc] initWithFrame:NSMakeRect(0,0,472,88)];
  [logOutput setMaxSize:NSMakeSize(1e7, 1e7)];
  [logOutput setVerticallyResizable:YES];
  [logOutput setHorizontallyResizable:YES];
  [logOutput setAutoresizingMask: NSViewWidthSizable | NSViewHeightSizable];
  //[logOutput setBackgroundColor:[NSColor whiteColor]];
  [[logOutput textContainer] setWidthTracksTextView:YES];

  scrollView1 = [[NSScrollView alloc] initWithFrame:NSMakeRect (0,0,496,92)];
  [scrollView1 setDocumentView:logOutput];
  [logOutput setMinSize:NSMakeSize(0.0,[scrollView1 contentSize].height)];
  [[logOutput textContainer] setContainerSize:NSMakeSize([scrollView1 contentSize].width,1e7)];
  [scrollView1 setHasHorizontalScroller: YES];
  [scrollView1 setHasVerticalScroller: YES];
  [scrollView1 setBorderType: NSBezelBorder];
  [scrollView1 setAutoresizingMask:(NSViewWidthSizable | NSViewHeightSizable)];
  [scrollView1 autorelease];

  /*
   *
   */

  textView2 = [[NSTextView alloc] initWithFrame:NSMakeRect(0,0,472,88)];
  [textView2 setMaxSize:NSMakeSize(1e7, 1e7)];
  [textView2 setVerticallyResizable:YES];
  [textView2 setHorizontallyResizable:YES];
  [textView2 setAutoresizingMask: NSViewWidthSizable | NSViewHeightSizable];
  [textView2 setBackgroundColor:[NSColor whiteColor]];
  [[textView2 textContainer] setWidthTracksTextView:YES];

  scrollView2 = [[NSScrollView alloc] initWithFrame:NSMakeRect (0,0,496,92)];
  [scrollView2 setDocumentView:textView2];
  [textView2 setMinSize:NSMakeSize(0.0,[scrollView2 contentSize].height)];
  [[textView2 textContainer] setContainerSize:NSMakeSize([scrollView2 contentSize].width,1e7)];
  [scrollView2 setHasHorizontalScroller: YES];
  [scrollView2 setHasVerticalScroller: YES];
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
   * Buttons
   */

  _w_frame = NSMakeRect(8,268,144,48);
  matrix = [[[NSMatrix alloc] initWithFrame: _w_frame
                                       mode: NSHighlightModeMatrix
                                  prototype: buttonCell
                               numberOfRows: 1
                            numberOfColumns: 3] autorelease];
  [matrix setSelectionByRect:YES];
  [matrix setAutoresizingMask: (NSViewMaxXMargin | NSViewMinYMargin)];
  [_c_view addSubview:matrix];

  button = [matrix cellAtRow:0 column:0];
  [button setImagePosition:NSImageOnly];
  [button setImage:IMAGE(@"ProjectCentre_build.tiff")];
  [button setButtonType:NSMomentaryPushButton];
  [button setTarget:self];
  [button setAction:@selector(build:)];

  button = [matrix cellAtRow:0 column:1];
  [button setImagePosition:NSImageOnly];
  [button setImage:IMAGE(@"ProjectCentre_clean.tiff")];
  [button setButtonType:NSMomentaryPushButton];
  [button setTarget:self];
  [button setAction:@selector(clean:)];

  button = [matrix cellAtRow:0 column:2];
  [button setImagePosition:NSImageOnly];
  [button setImage:IMAGE(@"ProjectCentre_prefs.tiff")];
  [button setTarget:self];
  [button setAction:@selector(showBuildTarget:)];
  [button setButtonType:NSMomentaryPushButton];
  [button setTarget:self];
  [button setAction:@selector(install:)];
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

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(projectDidChange:) name:ActiveProjectDidChangeNotification object:nil];
  }
  return self;
}

- (void)dealloc
{
  [[NSNotificationCenter defaultCenter] removeObserver:self];

  [buildWindow release];
  [makePath release];
  [buildTasks release];

  [super dealloc];
}

- (void)showPanelWithProject:(PCProject *)proj options:(NSDictionary *)options;
{
  if (![buildWindow isVisible]) {
    [buildWindow center];
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
  NSString *output = nil;
  NSPipe *logPipe;
  NSFileHandle *readHandle;
  NSData  *inData = nil;
  NSDictionary *optionDict;

  if (!currentProject) {
    return;
  }

  logPipe = [NSPipe pipe];
  readHandle = [logPipe fileHandleForReading];
  makeTask = [[NSTask alloc] init];

  optionDict = [currentProject buildOptions];

  if ((tg = [optionDict objectForKey:BUILD_KEY])) {
    if ([tg isEqualToString:TARGET_MAKE_DEBUG]) {
      args = [NSMutableArray array];
      [args addObject:@"debug=yes"];
      [makeTask setArguments:args];
    }
    else if ([tg isEqualToString:TARGET_MAKE_PROFILE]) {
      args = [NSMutableArray array];
      [args addObject:@"profile=YES"];
      [args addObject:@"static=YES"];
      [makeTask setArguments:args];
    }

    [makeTask setCurrentDirectoryPath:[currentProject projectPath]];
    [makeTask setLaunchPath:makePath];

    [makeTask setStandardOutput:logPipe];
    [makeTask setStandardError:logPipe];

    [makeTask launch];

    /*
     * This is just a quick hack for now...
     */

    while ((inData = [readHandle availableData]) && [inData length]) {
      output = [[NSString alloc] initWithData:inData encoding:NSASCIIStringEncoding];      
      [logOutput setString:[NSString stringWithFormat:@"%@%@\n", [logOutput string], output]];
      [logOutput scrollRangeToVisible:NSMakeRange([[logOutput textStorage] length], 0)];
      [output release];
    }
    
    [makeTask waitUntilExit];
    [makeTask autorelease];
  }
}

- (void)clean:(id)sender
{
}

- (void)install:(id)sender
{
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
