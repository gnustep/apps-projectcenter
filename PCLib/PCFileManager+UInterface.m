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

#import "PCFileManager+UInterface.h"
#import "PCDefines.h"

#import <AppKit/AppKit.h>

@implementation PCFileManager (UInterface)

- (void)_initUI
{
    NSView *_c_view;
    unsigned int style = NSTitledWindowMask 
		       | NSClosableWindowMask 
		       | NSMiniaturizableWindowMask;
    NSBox *box;
    NSRect _w_frame;
    NSMatrix* matrix;
    id button;
    NSButtonCell* buttonCell = [[[NSButtonCell alloc] init] autorelease];
    id textField;
    NSScrollView *scrollView;

    /*
     * the file creation window
     *
     */

    _w_frame = NSMakeRect(100,100,320,240);
    newFileWindow = [[NSWindow alloc] initWithContentRect:_w_frame
						styleMask:style
						backing:NSBackingStoreBuffered
						    defer:NO];
    [newFileWindow setMinSize:NSMakeSize(320,160)];
    [newFileWindow setTitle:@"New File..."];

    box = [[NSBox alloc] init];
    [box setFrame:NSMakeRect(16,172,288,56)];
    fileTypePopup = [[NSPopUpButton alloc] initWithFrame:NSMakeRect(32,2,216,20)
					       pullsDown:NO];
    [fileTypePopup setAutoresizingMask: (NSViewWidthSizable)];
    [fileTypePopup setTarget:self];
    [fileTypePopup setAction:@selector(popupChanged:)];
    [box setTitle:@"File Type"];
    [box setTitlePosition:NSAtTop];
    [box setBorderType:NSGrooveBorder];
    [box setAutoresizingMask: (NSViewWidthSizable | NSViewMinYMargin)];

    [box addSubview:fileTypePopup];
    RELEASE(fileTypePopup);

    _c_view = [newFileWindow contentView];

    _w_frame = NSMakeRect (16,96,288,68);
    scrollView = [[NSScrollView alloc] initWithFrame:_w_frame];
    [scrollView setHasHorizontalScroller:NO];
    [scrollView setHasVerticalScroller: YES];
    [scrollView setBorderType: NSBezelBorder];
    [scrollView setAutoresizingMask:(NSViewWidthSizable | NSViewHeightSizable)];
  
    // This is a placeholder!
    _w_frame = [[scrollView contentView] frame];
    descrView = [[NSTextView alloc] initWithFrame:_w_frame];
    [descrView setMinSize: NSMakeSize (0, 0)];
    [descrView setMaxSize:NSMakeSize(1e7, 1e7)];
    [descrView setRichText:NO];
#ifdef GNUSTEP_BASE_VERSION
    [descrView setEditable:NO];
#endif
    [descrView setSelectable:YES];
    [descrView setVerticallyResizable:YES];
    [descrView setHorizontallyResizable:NO];
    [descrView setAutoresizingMask: NSViewWidthSizable | NSViewHeightSizable];
    [[descrView textContainer] setWidthTracksTextView:YES];
    [scrollView setDocumentView:descrView];
    RELEASE(descrView);

    _w_frame.size = NSMakeSize([scrollView contentSize].width,1e7);
    [[descrView textContainer] setContainerSize:_w_frame.size];

    [_c_view addSubview:scrollView];
    RELEASE(scrollView);

    [_c_view addSubview:box];
    RELEASE(box);

    /*
     * Button matrix
     */

    _w_frame = NSMakeRect(188,16,116,24);
    matrix = [[NSMatrix alloc] initWithFrame: _w_frame
				        mode: NSHighlightModeMatrix
                                   prototype: buttonCell
                                numberOfRows: 1
                             numberOfColumns: 2];
    [matrix setSelectionByRect:YES];
    [matrix setAutoresizingMask: (NSViewMinXMargin | NSViewMaxYMargin)];
    [matrix setTarget:self];
    [matrix setAction:@selector(buttonsPressed:)];
    [matrix setIntercellSpacing: NSMakeSize(2,2)];
    [_c_view addSubview:matrix];
    RELEASE(matrix);

    button = [matrix cellAtRow:0 column:0];
    [button setTag:0];
    [button setStringValue:@"Cancel"];
    [button setBordered:YES];
    [button setButtonType:NSMomentaryPushButton];

    button = [matrix cellAtRow:0 column:1];
    [button setTag:1];
    [button setStringValue:@"OK"];
    [button setBordered:YES];
    [button setButtonType:NSMomentaryPushButton];

    /*
     * The name of the new file...
     */

    // Status message
    textField = [[NSTextField alloc] initWithFrame:NSMakeRect(16,56,48,21)];
    [textField setAlignment: NSLeftTextAlignment];
    [textField setBordered: NO];
    [textField setEditable: NO];
    [textField setBezeled: NO];
    [textField setDrawsBackground: NO];
    [textField setStringValue:@"Name:"];
    [textField setAutoresizingMask: (NSViewMaxXMargin | 
				   NSViewWidthSizable | 
				   NSViewMinYMargin)];
    [_c_view addSubview:textField];
    RELEASE(textField);

    // Target
    newFileName = [[NSTextField alloc] initWithFrame:NSMakeRect(56,56,248,21)];
    [newFileName setAlignment: NSLeftTextAlignment];
    [newFileName setBordered: YES];
    [newFileName setBezeled: YES];
    [newFileName setEditable: YES];
    [newFileName setDrawsBackground: YES];
    [newFileName setStringValue:@"NewFile"];
    [newFileName setAutoresizingMask: (NSViewWidthSizable | NSViewMinYMargin)];
    [_c_view addSubview:newFileName];
    RELEASE(newFileName);
}

@end

