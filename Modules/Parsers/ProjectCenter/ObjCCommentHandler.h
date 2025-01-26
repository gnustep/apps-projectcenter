/*
**  ObjCCommentHandler.h
**
**  Copyright (c) 2003
**
**  Author: Yen-Ju  <yjchenx@hotmail.com>
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

#ifndef _ObjCCommentHandler_H_
#define _ObjCCommentHandler_H_

#define EQUAL(str) ([element isEqualToString: str])

#import <CodeHandler.h>
#import <Foundation/NSString.h>

@class NSString;

/* Require subclass to assign _preChar to work */

@interface ObjCCommentHandler: NSObject <CodeHandler>
{
  CommentType _commentType;
  BOOL _stringBegin;
  unichar _preChar;
  unichar _stringSymbol;
}

@end

#endif /* _ObjCCommentHandler_H_ */
