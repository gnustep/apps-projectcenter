/*
   GNUstep ProjectCenter - http://www.gnustep.org/experience/ProjectCenter.html

   Copyright (C) 2005 Free Software Foundation

   Authors: Serg Stoyan

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

#ifndef _PCObjCParser_h_
#define _PCObjCParser_h_

#include <AppKit/AppKit.h>
#include "CodeParser.h"

#define CALIBRATED_COL(r, g, b, a) RETAIN([NSColor colorWithCalibratedRed:r green:g blue:b alpha:a])

@class PCProjectEditor;

@interface PCObjCParser : NSObject <CodeParser>
{
  PCProjectEditor *clientObject;

  NSFont       *defaultFont;

  NSDictionary *normalAttrs;
  NSDictionary *commentAttrs;
  NSDictionary *keywordAttrs;
  NSDictionary *stringAttrs;
  NSDictionary *errorAttrs;
  
  NSCharacterSet *charset;
  NSCharacterSet *whiteCharset;
  NSCharacterSet *newLineCS;
  NSCharacterSet *methodDefCS;

  NSArray        *keywords;

  NSString                  *fileText;
  NSScanner                 *scanner;
  NSString                  **chars;
  NSMutableAttributedString *as;

  unsigned classStartIndex;
  NSString *classDefinition;
  unsigned methodStartIndex;
  NSString *methodDefinition;
  unsigned lastPastedIndex;
}

- (id)initWithConnection:(NSConnection *)conn;

- (NSString *)classNameFromString:(NSString *)string;
- (NSString *)methodNameFromString:(NSString *)string;

@end

#endif
