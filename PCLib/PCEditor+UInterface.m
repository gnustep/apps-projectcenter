//
//  PCEditor+UInterface.m
//  ProjectCenter
//
//  Created by Philippe C.D. Robert on Wed Nov 27 2002.
//  Copyright (c) 2002 __MyCompanyName__. All rights reserved.
//

#import "PCEditor+UInterface.h"
#import "PCEditorView.h"
#import "PCDefines.h"

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
   *
   * FIXME: this still is untested as I <d.ayers@inode.at>
   * haven't found the way to display the external window yet. :-(
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
