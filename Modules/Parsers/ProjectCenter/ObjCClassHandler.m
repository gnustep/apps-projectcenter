/*
**  ObjCClassHandler.m
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

#include <AppKit/AppKit.h>

#include "ObjCClassHandler.h"

@implementation ObjCClassHandler

- (id)init
{
  self = [super init];
  position = 0;
  classBeginPosition = 0;

  inSpace = NO;
  class = [[NSMutableString alloc] init];
  classes = [[NSMutableArray alloc] init];

  step = ClassNone;
  _preSymbol = 0;

  return self;
}

- (void)dealloc
{
  NSLog(@"ClassHandler: dealloc");
  RELEASE(class);
  RELEASE(classes);
  [super dealloc];
}

- (NSArray *)classes
{
  return methods;
}

#define NotClass {step = ClassNone; [class setString: @""];}

- (void)string:(NSString *)element
{
  unsigned int len = [element length];

  [super string: element];

  /* Comments */
  if (_commentType != NoComment)
    {
    }
  else if (_stringBegin/* != NoString*/)
    {
    }
  else
    {
      inSpace = NO;

      if (step == ClassStart)
        {
          NotClass;
        }
      else if (step == MethodSymbol)
        {
          if (_preSymbol == '(')
            step = MethodReturnValue;
          else if ((_preSymbol == '+') || (_preSymbol == '='))
            step = MethodName;

          [method appendString: element];
        }
      else if (step == MethodReturnValue)
        {
          if (_preSymbol == ')')
            step = MethodName;

          [method appendString: element];
        }
      else if (step == MethodName)
        {
          [method appendString: element];
        }
    }

  position += len;
  _preChar = 0;
}

- (void)number:(NSString *)element 
{
  [super number: element];

  /* Comments */
  if (_commentType != NoComment)
    {
    }
  else if (_stringBegin)
    {
    }
  else
    {
      inSpace = NO;

      if (step == ClassStart)
        {
          NotClass;
        }
      else if (step == ClassSymbol)
        {
          NotClass;
        }
      else if ((step == ClassName))
        {
          [class appendString: element];
        }
    }

  position += [element length];
  _preChar = 0;
}

- (void)spaceAndNewLine:(unichar)element 
{
  BOOL newline = NO;

  [super spaceAndNewLine: element];

  if ((element == 0x0A) || (element == 0x0D))
    {
      newline = YES;
    }

  /* Comments */
  if (_commentType != NoComment)
    {
    }
  else if (_stringBegin)
    {
    }
  else
    {
      if (step != ClassNone)
        {
          if ((!newline) && (!inSpace))
            {
              [method appendString:[NSString stringWithFormat:@"%c",element]];
            }
          if (element == ' ')
            {
              inSpace = YES;
            }
        }

      if (newline && (step == MethodNone))
        {
          step = ClassStart;
          classBeginPosition = position;
        }
    }

  position++;
  _preChar = element;
}

- (void)symbol:(unichar)element 
{
  [super symbol: element];

  /* Comments */
  if (_commentType != NoComment)
    {
    }
  else if (_stringBegin)
    {
    }
  else
    {
      inSpace = NO;
      _preSymbol = element;

      if (step == ClassStart)
        {
          if ((element == '+') || (element == '-'))
            {
              step = ClassSymbol;
              [method appendString:[NSString stringWithFormat: @"%c", element]];
            }
          else
            {
              NotClass;
            }
        }
      else if (step == ClassSymbol)
        {
          if ((element == '(') || (element == '_'))
            {
              [method appendString: [NSString stringWithFormat:@"%c", element]];
            }
        }
      else if (step == ClassReturnValue)
        {
          if (element == ')')
            {
              step = ClassName;
            }
          [method appendString:[NSString stringWithFormat:@"%c", element]];
        }
      else if (step == ClassName) 
        {
          if (element != '{')
            [method appendString:[NSString stringWithFormat: @"%c", element]];
        }

      if ((element == ';') || (element == '{') || 
          (element == '}') || (position == 0))
        {
          step = ClassStart;
          classBeginPosition = position;
          if ([class length])
            {
              NSDictionary *dict;

              dict = [NSDictionary dictionaryWithObjectsAndKeys:
	       	AUTORELEASE([class copy]), @"class",
		[NSNumber numberWithUnsignedInt:methodBeginPosition], @"position", nil];
              [methods addObject: dict];
            }
          [class setString:@""];
        }
    }

  position++;
  _preChar = element;
}

- (void)invisible:(unichar)element
{
  [super invisible:element];
  position ++;
  _preChar = element;
}

@end

