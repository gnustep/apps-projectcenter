/*
**  PCDebuggerView
**
**  Copyright (c) 2008-2021
**
**  Author: Gregory Casamento <greg.casamento@gmail.com>
**          Riccardo Mottola <rm@gnu.org>
**
**  This program is free software; you can redistribute it and/or modify
**  it under the terms of the GNU General Public License as published by
**  the Free Software Foundation; either version 2 of the License, or
**  (at your option) any later version.
**
**  This program is distributed in the hope that it will be useful,
**  but WITHOUT ANY WARRANTY; without even the implied warranty of
**  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
**  GNU General Public License for more details.
**
**  You should have received a copy of the GNU General Public License
**  along with this program; if not, write to the Free Software
**  Foundation, Inc., 31 Milk Street #960789 Boston, MA 02196 USA
*/

#import <Foundation/NSString.h>
#import <AppKit/NSTextView.h>


@class PCDebugger;

@interface PCDebuggerView : NSTextView
{
  PCDebugger *debugger;
}

- (void) setDebugger:(PCDebugger *)theDebugger;
- (void)setFont:(NSFont *)font;



- (void) runProgram: (NSString *)path
 inCurrentDirectory: (NSString *)directory
   logStandardError: (BOOL)logError;

- (void) putString: (NSString *)string;

@end
