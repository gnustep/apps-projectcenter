/*
   GNUstep ProjectCenter - http://www.gnustep.org

   Copyright (C) 2001 Free Software Foundation

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

#include "PCLogController.h"

void
PCLog(id sender, int tag, NSString* format, va_list args)
{
  [[PCLogController sharedLogController] 
    logMessage:[NSString stringWithFormat:format arguments: args]
       withTag:tag
        sender:sender];
}

void
PCLogInfo(id sender, NSString* format, ...)
{
  va_list ap;

  va_start(ap, format);
  PCLog(sender, INFO, format, ap);
  va_end(ap);
}

void
PCLogStatus(id sender, NSString* format, ...)
{
  va_list ap;

  va_start(ap, format);
  PCLog(sender, STATUS, format, ap);
  va_end(ap);
}

void
PCLogWarning(id sender, NSString* format, ...)
{
  va_list ap;

  va_start(ap, format);
  PCLog(sender, WARNING, format, ap);
  va_end(ap);
}

void
PCLogError(id sender, NSString* format, ...)
{
  va_list ap;

  va_start(ap, format);
  PCLog(sender, ERROR, format, ap);
  va_end(ap);
}

@implementation PCLogController

// ===========================================================================
// ==== Class methods
// ===========================================================================

static PCLogController *_logCtrllr = nil;

+ (PCLogController *)sharedLogController
{
  if (!_logCtrllr)
    {
      _logCtrllr = [[PCLogController alloc] init];
    }
   
  return _logCtrllr;
}

// ===========================================================================
// ==== Init and free
// ===========================================================================

- (id)init
{
  NSFont *font = nil;

  if (!(self = [super init]))
    {
      return nil;
    }

  if ([NSBundle loadNibNamed:@"LogPanel" owner:self] == NO)
    {
      NSLog(@"PCLogController[init]: error loading NIB file!");
      return nil;
    }

  [panel setFrameAutosaveName:@"LogPanel"];
  if (![panel setFrameUsingName: @"LogPanel"])
    {
      [panel center];
    }

  font = [NSFont userFixedPitchFontOfSize: 10.0];
  textAttributes =
    [NSMutableDictionary dictionaryWithObject:font forKey:NSFontAttributeName];
  [textAttributes retain];

  return self;
}

- (void)dealloc
{
  NSLog(@"PCLogController: dealloc");
  RELEASE(textAttributes);
}

- (void)showPanel
{
  [panel orderFront:self];
}

- (void)logMessage:(NSString *)text withTag:(int)tag sender:(id)sender;
{
  NSString           *messageText = nil;
  NSAttributedString *message = nil;

  messageText = 
    [NSString stringWithFormat:@" %@: %@\n",[sender className],text];

  switch (tag) 
    {
    case INFO:
      [textAttributes 
	setObject:[NSColor colorWithDeviceRed:.0 green:.0 blue:.0 alpha:1.0]
	   forKey:NSForegroundColorAttributeName];
      break;
    case STATUS:
      [textAttributes 
	setObject:[NSColor colorWithDeviceRed:.0 green:.35 blue:.0 alpha:1.0]
	   forKey:NSForegroundColorAttributeName];
      break;
      
    case WARNING:
      [textAttributes 
	setObject:[NSColor colorWithDeviceRed:.56 green:.45 blue:.0 alpha:1.0]
	   forKey:NSForegroundColorAttributeName];
      break;

    case ERROR:
      [textAttributes 
	setObject:[NSColor colorWithDeviceRed:.63 green:.0 blue:.0 alpha:1.0]
	   forKey:NSForegroundColorAttributeName];
      break;

    default:
      break;
    }

  message = [[NSAttributedString alloc] initWithString:messageText
                                            attributes:textAttributes];
  [self putMessageOnScreen:message];
}

- (void)putMessageOnScreen:(NSAttributedString *)message
{
  [[textView textStorage] appendAttributedString:message];
  [textView scrollRangeToVisible:NSMakeRange([[textView string] length], 0)];
}

@end
