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

#include "PCProjectManager+UInterface.h"
#include "PCDefines.h"

@implementation PCProjectManager (UInterface)

- (void)_initUI
{
  NSView *_c_view;
  unsigned int style = NSTitledWindowMask | NSClosableWindowMask;
  NSRect _w_frame;
  NSBox *line;

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
