//
//  PCProjectManager+UInterface.m
//  ProjectCenter
//
//  Created by Philippe C.D. Robert on Wed Nov 27 2002.
//  Copyright (c) 2002 __MyCompanyName__. All rights reserved.
//

#import "PCProjectManager+UInterface.h"
#import "PCDefines.h"

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
