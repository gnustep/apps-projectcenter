/*
   GNUstep ProjectCenter - http://www.gnustep.org

   Copyright (C) 2002-2004 Free Software Foundation

   Authors: Philippe C.D. Robert
            Serg Stoyan

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

#ifndef _PCTEXTFINDER_H_
#define _PCTEXTFINDER_H_

#include <AppKit/AppKit.h>

@interface PCTextFinder : NSObject
{
    NSPanel *panel;
    NSString *findString;
    id findTextField;
    id replaceTextField;
    id statusField;
    id ignoreCaseButton;
    id regexpButton;

    BOOL findStringChangedSinceLastPasteboardUpdate;
    BOOL lastFindWasSuccessful;
    BOOL shouldReplaceAll;
    BOOL shouldIgnoreCase;
}

+ (PCTextFinder*)sharedFinder;

- (id)init;
- (void)dealloc;

- (NSPanel *)findPanel;

- (void)showFindPanel:(id)sender;
- (void)buttonPressed:(id)sender;
- (void)setReplaceAllScope:(id)sender;
- (void)setIgnoreCase:(id)sender;

- (BOOL)find:(BOOL)direction;
- (NSTextView *)textObjectToSearchIn;
- (NSString *)findString;
- (void)setFindString:(NSString *)string;

- (void)loadFindStringFromPasteboard;
- (void)loadFindStringToPasteboard;

- (void)findNext:(id)sender;
- (void)findPrevious:(id)sender;
- (void)findNextAndOrderFindPanelOut:(id)sender;
- (void)replace:(id)sender;
- (void)replaceAll:(id)sender;

@end

#endif // _PCTEXTFINDER_H_

