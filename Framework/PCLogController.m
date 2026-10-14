/*
   GNUstep ProjectCenter - http://www.gnustep.org/experience/ProjectCenter.html

   Copyright (C) 2001 Free Software Foundation

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
   Software Foundation, Inc., 31 Milk Street #960789 Boston, MA 02196 USA.
*/

#import <ProjectCenter/PCLogController.h>

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

  font = [NSFont userFixedPitchFontOfSize:[NSFont systemFontSize]];
  textAttributes =
    [NSMutableDictionary dictionaryWithObject:font forKey:NSFontAttributeName];
  [textAttributes retain];

  return self;
}

- (void)dealloc
{
#ifdef DEVELOPMENT
  NSLog(@"PCLogController: dealloc");
#endif
  RELEASE(textAttributes);

  [super dealloc];
}

- (void)showPanel
{
  [panel makeKeyAndOrderFront:self];
}

- (void)logMessage:(NSString *)text withTag:(int)tag sender:(id)sender;
{
  NSString           *messageText = nil;
  NSAttributedString *message = nil;
  NSColor            *background;
  NSColor            *color;

  messageText = 
    [NSString stringWithFormat:@" %@: %@\n",[sender className],text];

  switch (tag)
    {
    case STATUS:
      color = [NSColor colorWithDeviceRed:.0 green:.35 blue:.0 alpha:1.0];
      break;

    case WARNING:
      color = [NSColor colorWithDeviceRed:.56 green:.45 blue:.0 alpha:1.0];
      break;

    case ERROR:
      color = [NSColor colorWithDeviceRed:.63 green:.0 blue:.0 alpha:1.0];
      break;

    case INFO:
    default:
      background = [[textView backgroundColor]
        colorUsingColorSpaceName:NSCalibratedRGBColorSpace];
      if (background == nil)
        {
          color = [NSColor textColor];
        }
      else
        {
          color = [NSColor colorWithCalibratedRed:1.0 - [background redComponent]
                                          green:1.0 - [background greenComponent]
                                           blue:1.0 - [background blueComponent]
                                          alpha:1.0];
        }
      break;
    }
  [textAttributes setObject:color forKey:NSForegroundColorAttributeName];

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
