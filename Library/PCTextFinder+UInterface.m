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
*/

#include "PCTextFinder+UInterface.h"
#include "PCDefines.h"

@implementation PCTextFinder (UInterface)

- (void)_initUI
{
    int mask = (NSTitledWindowMask | NSClosableWindowMask);
    NSRect rect = NSMakeRect( 100, 100, 440, 184 );
    NSTextField *textField;
    NSBox *box;
    NSButtonCell *cell;
    NSMatrix *borderMatrix;

    panel = [[NSPanel alloc] initWithContentRect:rect
                                       styleMask:mask
                                         backing:NSBackingStoreBuffered
                                           defer:YES];
    [panel setTitle: @"Find Panel"];
    [panel setReleasedWhenClosed: NO]; 

    // Find textfield
    textField = [[NSTextField alloc] initWithFrame:NSMakeRect(16,148,88,21)];
    [textField setAlignment: NSRightTextAlignment];
    [textField setBordered: NO];
    [textField setEditable: NO];
    [textField setBezeled: NO];
    [textField setDrawsBackground: NO];
    [textField setStringValue:@"Find:"];
    [[panel contentView] addSubview:textField];
    RELEASE(textField);

    rect = NSMakeRect(104,148,328 ,21);
    findTextField = [[NSTextField alloc] initWithFrame:rect];
    [findTextField setAlignment: NSLeftTextAlignment];
    [findTextField setBordered: NO];
    [findTextField setEditable: YES];
    [findTextField setBezeled: YES];
    [findTextField setDrawsBackground: YES];
    [findTextField setStringValue:@""];
    [findTextField setDelegate:self];
    [findTextField setTarget:self];
    [findTextField setAction:@selector(setHost:)];
    [[panel contentView] addSubview:findTextField];
    RELEASE(findTextField);

    [panel makeFirstResponder:findTextField]; 

    // Replace field
    textField = [[NSTextField alloc] initWithFrame:NSMakeRect(16,120,88,21)];
    [textField setAlignment: NSRightTextAlignment];
    [textField setBordered: NO];
    [textField setEditable: NO];
    [textField setBezeled: NO];
    [textField setDrawsBackground: NO];
    [textField setStringValue:@"Replace with:"];
    [[panel contentView] addSubview:textField];
    RELEASE(textField);

    rect = NSMakeRect(104,120,328 ,21);
    replaceTextField = [[NSTextField alloc] initWithFrame:rect];
    [replaceTextField setAlignment: NSLeftTextAlignment];
    [replaceTextField setBordered: NO];
    [replaceTextField setEditable: YES];
    [replaceTextField setBezeled: YES];
    [replaceTextField setDrawsBackground: YES];
    [replaceTextField setStringValue:@""];
    [replaceTextField setDelegate:self];
    [replaceTextField setTarget:self];
    [replaceTextField setAction:@selector(setHost:)];
    [[panel contentView] addSubview:replaceTextField];
    RELEASE(replaceTextField);

    [findTextField setNextResponder:replaceTextField];

    // Options
    rect = NSMakeRect(104,40,144 ,80);
    box = [[NSBox alloc] initWithFrame:rect];
    [box setTitle:@"Replace All Scope"];
    [[panel contentView] addSubview:box];
    RELEASE(box);

    cell = [[NSButtonCell alloc] init];
    [cell setButtonType: NSRadioButton];
    [cell setBordered: NO];
    [cell setImagePosition: NSImageLeft]; 

    rect = NSMakeRect(16,8,112 ,48);
    borderMatrix = [[NSMatrix alloc] initWithFrame: rect
                                              mode: NSRadioModeMatrix
                                         prototype: cell
                                      numberOfRows: 2
                                   numberOfColumns: 1];   

    [borderMatrix setIntercellSpacing: NSMakeSize (0, 4) ];
    [borderMatrix setTarget: self];
    [borderMatrix setAutosizesCells: NO];

    cell = [borderMatrix cellAtRow: 0 column: 0];
    [cell setTitle: @"Entire File"];
    [cell setTag:0];
    [cell setAction: @selector(setReplaceAllScope:)];

    cell = [borderMatrix cellAtRow: 1 column: 0];
    [cell setTitle: @"Selection"];
    [cell setTag:1];
    [cell setAction: @selector(setReplaceAllScope:)];

    [borderMatrix sizeToFit];
    [box addSubview:borderMatrix];
    RELEASE(borderMatrix);

    rect = NSMakeRect(252,40,180 ,80);
    box = [[NSBox alloc] initWithFrame:rect];
    [box setTitle:@"Find Options"];
    [[panel contentView] addSubview:box];
    RELEASE(box);

    cell = [[NSButtonCell alloc] init];
    [cell setButtonType: NSSwitchButton];
    [cell setBordered: NO];
    [cell setImagePosition: NSImageLeft]; 

    rect = NSMakeRect(16,8,140 ,48);
    borderMatrix = [[NSMatrix alloc] initWithFrame: rect
                                              mode: NSHighlightModeMatrix
                                         prototype: cell
                                      numberOfRows: 2
                                   numberOfColumns: 1];   

    [borderMatrix setIntercellSpacing: NSMakeSize (0, 4) ];
    [borderMatrix setTarget: self];
    [borderMatrix setAutosizesCells: NO];

    ignoreCaseButton = [borderMatrix cellAtRow: 0 column: 0];
    [ignoreCaseButton setTitle: @"Ignore Case"];
    [ignoreCaseButton setState: YES];
    [ignoreCaseButton setAction: @selector(setIgnoreCase:)];

    regexpButton = [borderMatrix cellAtRow: 1 column: 0];
    [regexpButton setTitle: @"Regular Expression"];
    [regexpButton setState: NO];
    //[regexpButton setAction: @selector(setIsRegExp:)];

    [borderMatrix sizeToFit];
    [box addSubview:borderMatrix];
    RELEASE(borderMatrix);

    cell = [[NSButtonCell alloc] init];
    [cell setImagePosition: NSNoImage]; 

    rect = NSMakeRect(8,8,412,24);
    borderMatrix = [[NSMatrix alloc] initWithFrame: rect
                                              mode: NSHighlightModeMatrix
                                         prototype: cell
                                      numberOfRows: 1
                                   numberOfColumns: 4];   

    [borderMatrix setIntercellSpacing: NSMakeSize (4, 0) ];
    [borderMatrix setTarget: self];
    [borderMatrix setAction: @selector(buttonPressed:)];
    [borderMatrix setAutosizesCells: NO];
    [replaceTextField setNextResponder:borderMatrix];

    cell = [borderMatrix cellAtRow:0 column:0];
    [cell setTitle: @"Replace All"];
    [cell setTag:0];

    cell = [borderMatrix cellAtRow:0 column:1];
    [cell setTitle: @"Replace"];
    [cell setTag:1];

    cell = [borderMatrix cellAtRow:0 column:2];
    [cell setTitle: @"Previous"];
    [cell setTag:2];

    cell = [borderMatrix cellAtRow:0 column:3];
    [cell setTitle: @"Next"];
    [cell setTag:3];

    [[panel contentView] addSubview:borderMatrix];
    RELEASE(borderMatrix);

    rect = NSMakeRect(16,64,80,24);
    statusField = [[NSTextField alloc] initWithFrame:rect];
    [statusField setAlignment: NSLeftTextAlignment];
    [statusField setBordered: NO];
    [statusField setEditable: NO];
    [statusField setBezeled: NO];
    [statusField setDrawsBackground: NO];
    [statusField setStringValue:@""];
    [statusField setDelegate:self];
    [[panel contentView] addSubview:statusField];
    RELEASE(statusField);

    [panel setDelegate: self];
    [panel center];
}

@end

