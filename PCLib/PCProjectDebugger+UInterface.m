/*
   GNUstep ProjectCenter - http://www.gnustep.org

   Copyright (C) 2003 Free Software Foundation

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

#include "PCProjectDebugger.h"
#include "PCProjectDebugger+UInterface.h"
#include "PCProject.h"
#include "PCButton.h"

#include <AppKit/AppKit.h>

#ifndef IMAGE
#define IMAGE(X) [[[NSImage alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForImageResource:(X)]] autorelease]
#endif

@implementation PCProjectDebugger (UInterface)

- (void) _createLaunchPanel
{
  launchPanel = [[NSPanel alloc]
    initWithContentRect: NSMakeRect (0, 300, 480, 322)
    styleMask: (NSTitledWindowMask 
		| NSClosableWindowMask
		| NSResizableWindowMask)
    backing: NSBackingStoreRetained
    defer: YES];
  [launchPanel setMinSize: NSMakeSize(400, 160)];
  [launchPanel setFrameAutosaveName: @"ProjectLauncher"];
  [launchPanel setReleasedWhenClosed: NO];
  [launchPanel setHidesOnDeactivate: NO];
  [launchPanel setTitle: [NSString 
    stringWithFormat: @"%@ - Launch", [currentProject projectName]]];

  if (![launchPanel setFrameUsingName: @"ProjectLauncher"])
    {
      [launchPanel center];
    }
}

- (void)_createComponentView
{
  NSScrollView       *scrollView; 
  NSString           *string;
  NSAttributedString *attributedString;

  componentView = [[NSBox alloc] initWithFrame:NSMakeRect(8,-1,464,322)];
  [componentView setTitlePosition:NSNoTitle];
  [componentView setBorderType:NSNoBorder];
  [componentView setAutoresizingMask:NSViewWidthSizable | NSViewHeightSizable];
  [componentView setContentViewMargins: NSMakeSize(0.0,0.0)];

  /*
   * Top buttons
   */
//  _w_frame = NSMakeRect(0, 270, 88, 44);

  runButton = [[PCButton alloc] initWithFrame: NSMakeRect(0,264,50,50)];
  [runButton setTitle: @"Run"];
  [runButton setImage: IMAGE(@"ProjectCenter_run")];
  [runButton setAlternateImage: IMAGE(@"Stop")];
  [runButton setTarget: self];
  [runButton setAction: @selector(run:)];
  [runButton setAutoresizingMask: (NSViewMaxXMargin | NSViewMinYMargin)];
  [runButton setButtonType: NSToggleButton];
  [componentView addSubview: runButton];
  RELEASE (runButton);

  debugButton = [[PCButton alloc] initWithFrame: NSMakeRect(50,264,50,50)];
  [debugButton setTitle: @"Debug"];
  [debugButton setImage: IMAGE(@"ProjectCenter_debug")];
  [debugButton setAlternateImage: IMAGE(@"Stop")];
  [debugButton setTarget: self];
  [debugButton setAction: @selector(debug:)];
  [debugButton setAutoresizingMask: (NSViewMaxXMargin | NSViewMinYMargin)];
  [debugButton setButtonType: NSToggleButton];
  [componentView addSubview: debugButton];
  RELEASE (debugButton);

  /*
   *
   */
  scrollView = [[NSScrollView alloc] initWithFrame:NSMakeRect (0,-1,464,253)];

  [scrollView setHasHorizontalScroller:NO];
  [scrollView setHasVerticalScroller:YES];
  [scrollView setBorderType: NSBezelBorder];
  [scrollView setAutoresizingMask:(NSViewWidthSizable | NSViewHeightSizable)];

  stdOut=[[NSTextView alloc] initWithFrame:[[scrollView contentView] frame]];

  [stdOut setMinSize: NSMakeSize(0, 0)];
  [stdOut setMaxSize: NSMakeSize(1e7, 1e7)];
  [stdOut setRichText:YES];
  [stdOut setEditable:NO];
  [stdOut setSelectable:YES];
  [stdOut setVerticallyResizable: YES];
  [stdOut setHorizontallyResizable: NO];
  [stdOut setAutoresizingMask: NSViewWidthSizable | NSViewHeightSizable];
  [[stdOut textContainer] setWidthTracksTextView:YES];
  [[stdOut textContainer] setContainerSize:
    NSMakeSize([stdOut frame].size.width, 1e7)];

  // Font
  string  = [NSString stringWithString:@"=== Launcher ready ==="];
  attributedString = 
    [[NSAttributedString alloc] initWithString:string 
                                    attributes:textAttributes];
  [[stdOut textStorage] setAttributedString:attributedString];

  [scrollView setDocumentView:stdOut];
  RELEASE (stdOut);

  [componentView addSubview: scrollView];
  RELEASE(scrollView);
}

@end

