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

#include "PCEditor+UInterface.h"
#include "PCEditorView.h"
#include "PCDefines.h"

@implementation PCEditor (UInterface)

- (void)_initUI
{
  NSScrollView *scrollView;
  unsigned int style;
  NSRect       rect;

  /*
   * Creating shared text storage
   */

  _storage = [[NSTextStorage alloc] init];

  /*
   * Creating external view's window
   */

  style = NSTitledWindowMask
        | NSClosableWindowMask
        | NSMiniaturizableWindowMask
        | NSResizableWindowMask;
  rect = NSMakeRect(100,100,512,320);

  _window = [[NSWindow alloc] initWithContentRect:rect
                                        styleMask:style
                                        backing:NSBackingStoreBuffered
                                        defer:YES];
  [_window setReleasedWhenClosed:NO];
  [_window setMinSize:NSMakeSize(512,320)];
  rect = [[_window contentView] frame];

  /*
   * Creating external view's scroll view
   */

  scrollView = [[NSScrollView alloc] initWithFrame:rect];
  [scrollView setHasHorizontalScroller:  NO];
  [scrollView setHasVerticalScroller:   YES];
  [scrollView setBorderType:  NSBezelBorder];
  [scrollView setAutoresizingMask: (NSViewWidthSizable|NSViewHeightSizable)];
  rect = [[scrollView contentView] frame];

  /*
   * Creating external view
   */

  _eView = [self _createEditorViewWithFrame:rect];

  /*
   * Setting up external view / scroll view / window
   */

  [scrollView setDocumentView:_eView];
  [_window setContentView:scrollView];
  [_window setDelegate:self];
  [_window makeFirstResponder:_eView];
  RELEASE(scrollView);

  /*
   * Creating internal view
   *
   * The width is actually irrelavent here as the the PCProjectEditor
   * will reset it to the width of the content view if its scroll view.
   * The height should be large as this will be the height it will be
   * will be visible.
   */

  rect = NSMakeRect( 0, 0, 1e7, 1e7);
  _iView = [self _createEditorViewWithFrame:rect];
  RETAIN(_iView);
}

- (PCEditorView *)_createEditorViewWithFrame:(NSRect)fr
{
  PCEditorView    *ev;
  NSTextContainer *tc;
  NSLayoutManager *lm;

  /*
   * setting up the objects needed to manage the view but using the
   * shared textStorage.
   */

  lm = [[NSLayoutManager alloc] init];
  tc = [[NSTextContainer alloc] initWithContainerSize:fr.size];
  [lm addTextContainer:tc];
  RELEASE(tc);

  [_storage addLayoutManager:lm];
  RELEASE(lm);

  ev = [[PCEditorView alloc] initWithFrame:fr
                             textContainer:tc];
  [ev setEditor:self];

  [ev setMinSize: NSMakeSize(  0,   0)];
  [ev setMaxSize: NSMakeSize(1e7, 1e7)];
  [ev setRichText:                 YES];
  [ev setAutoresizingMask: NSViewWidthSizable|NSViewHeightSizable];
  [ev setVerticallyResizable:      YES];
  [ev setHorizontallyResizable:     NO];
  [ev setTextContainerInset:   NSMakeSize( 5, 5)];
  [[ev textContainer] setWidthTracksTextView:YES];

  return AUTORELEASE(ev);
}

@end
