/*
   GNUstep ProjectCenter - http://www.gnustep.org

   Copyright (C) 2000-2002 Free Software Foundation

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

#ifndef _PCEDITORVIEW_H
#define _PCEDITORVIEW_H

#include <AppKit/AppKit.h>

@class PCEditor;

typedef enum _PCTabFlags {
    PCTabTab = 1,
    PCTab2Sp,
    PCTab4Sp,
    PCTab8Sp
} PCTabFlags;

@interface PCEditorView : NSTextView
{
  PCEditor  *editor;
  NSScanner *scanner;
  NSRange   range;
  NSArray   *_keywords;
  
#ifndef GNUSTEP_BASE_VERSION
  id _textStorage;
#endif
}

//=============================================================================
// ==== Class methods
//=============================================================================

+ (void)setTabBehaviour:(int)tabFlags;
+ (int)tabBehaviour;

+ (void)setShouldHighlight:(BOOL)yn;
+ (BOOL)shouldHighlight;

//=============================================================================
// ==== Init
//=============================================================================

- (id)initWithFrame:(NSRect)frameRect textContainer:(NSTextContainer*)tc;
- (void)dealloc;

//=============================================================================
// ==== Accessor methods
//=============================================================================

- (void)setEditor:(PCEditor *)anEditor;
- (void)setString:(NSString *)aString;

//=============================================================================
// ==== Text handling
//=============================================================================

- (BOOL)acceptsFirstMouse:(NSEvent *)theEvent;

- (void)insertText:(id)aString;

- (void)highlightText;
- (void)highlightTextInRange:(NSRange)range;

- (void)keyDown: (NSEvent *)anEvent;

@end

#endif
