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
   */

  _w_frame = NSMakeRect(0,194,244,44);
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
  [componentView addSubview:matrix];

  button = [matrix cellAtRow:0 column:0];
  [button setTag:0];
  [button setImagePosition:NSImageOnly];
  //[button setImage:IMAGE(@"ProjectCenter_make")];
  [button setButtonType:NSMomentaryPushButton];
  [button setTitle:@"Build"];

  button = [matrix cellAtRow:0 column:1];
  [button setTag:1];
  [button setImagePosition:NSImageOnly];
  //[button setImage:IMAGE(@"ProjectCenter_clean")];
  [button setButtonType:NSMomentaryPushButton];
  [button setTitle:@"Clean"];

  button = [matrix cellAtRow:0 column:2];
  [button setTag:2];
  [button setImagePosition:NSImageOnly];
  //[button setImage:IMAGE(@"ProjectCenter_debug")];
  [button setButtonType:NSMomentaryPushButton];
  [button setTitle:@"Debug"];

  button = [matrix cellAtRow:0 column:3];
  [button setTag:3];
  [button setImagePosition:NSImageOnly];
  //[button setImage:IMAGE(@"ProjectCenter_profile")];
  [button setButtonType:NSMomentaryPushButton];
  [button setTitle:@"Profile"];

  button = [matrix cellAtRow:0 column:4];
  [button setTag:4];
  [button setImagePosition:NSImageOnly];
  //[button setImage:IMAGE(@"ProjectCenter_install")];
  [button setButtonType:NSMomentaryPushButton];
  [button setTitle:@"Install"];
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

  [super dealloc];
}

- (NSView *)componentView;
{
  if (!componentView) {
    [self _createComponentView];
  }

  return componentView;
}

@end
