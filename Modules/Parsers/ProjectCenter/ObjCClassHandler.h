/*
**  ObjCClassHandler.h
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
**  Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
*/

#ifndef _ObjCClassHandler_H_
#define _ObjCClassHandler_H_

#include "CodeHandler.h"

#include "ObjCCommentHandler.h"

/**
 * ClassStart         ClassSymbol          ClassName    ClassEnd
 *            @interface/@implementation      Name        ;/{
 *            
 *
 * MethodStart is after each ';' or new line
 * MethodSymbol is +/- for objective-C
 * MethodReturnValue is surround by '(' and ')', and can be ignore
 * MethodName contain method name and messages
 * MethodNone is not method;
 */

typedef enum _CheckStep {
  ClassStart, 
  ClassSymbol,
  ClassReturnValue,
  ClassName, 
  ClassNone
} CheckStep;


@class NSMutableString;
@class NSMutableArray;

@interface ObjCClassHandler : ObjCCommentHandler <CodeHandler>
{
  unsigned int    position;

  BOOL            inSpace;
  NSMutableString *class;
  NSMutableArray  *classes;
  unichar         _preSymbol;
  unsigned        classBeginPosition;

  CheckStep       step;
}

// NSArray of NSDictionaries 
// (method = NSString; position = NSNumber)
- (NSArray *)classes;

@end

#endif /* _ObjCClassHandler_H_ */
