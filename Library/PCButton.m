/*
  GNUstep ProjectCenter - http://www.gnustep.org
 
  Copyright (C) 2003-2004 Free Software Foundation
 
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

#include "PCButton.h"
#include "PCDefines.h"

@implementation PCButton

- (id)initWithFrame:(NSRect)frameRect
{
  self = [super initWithFrame:frameRect];
  [_cell setGradientType:NSGradientConvexWeak];
  [self setImagePosition:NSImageOnly];
  [self setFont:[NSFont systemFontOfSize: 10.0]];

  ttTimer = nil;
  ttWindow = nil;

  return self;
}

- (void)dealloc
{
  if (_hasTooltip)
    {
      [[self superview] removeTrackingRect:tRectTag];
      [ttTimer invalidate];
      ttTimer = nil;
      RELEASE(ttTimer);
    }

  if (ttWindow != nil)
    {
      RELEASE(ttWindow);
    }

  [super dealloc];
}

- (void)setFrame:(NSRect)frameRect
{
//  NSLog (@"setFrame");
  [super setFrame:frameRect];

  if (_hasTooltip)
    {
      [self updateTrackingRect];
    }
}

- (void)setShowTooltip:(BOOL)yn
{
  _hasTooltip = yn;
  if (_hasTooltip)
    {
      tRectTag = [[self superview] addTrackingRect:[self frame]
	                                     owner:self
                                          userData:nil
                                      assumeInside:NO];
      [[self window] setAcceptsMouseMovedEvents:YES];
    }
}

- (void)updateTrackingRect
{
  [[self superview] removeTrackingRect:tRectTag];
  tRectTag = [[self superview] addTrackingRect:[self frame]
                                         owner:self
                                      userData:nil
                                  assumeInside:NO];
}

- (void)showTooltip:(NSTimer *)timer
{
  NSAttributedString *attributedTitle = [self attributedTitle];
  NSSize             titleSize = [attributedTitle size];

//  NSLog (@"showTooltip");
  if (ttWindow == nil)
    {
      NSTextField *ttText;
      NSRect      windowRect;
      NSRect      titleRect;
      NSRect      contentRect;

      windowRect = NSMakeRect(mouseLocation.x,
			      mouseLocation.y-16-(titleSize.height+3),
	     		      titleSize.width+10, titleSize.height+3);

      titleRect = NSMakeRect(0,0, titleSize.width+10,titleSize.height+3);
/*      windowRect = NSMakeRect(mouseLocation.x, 
			      mouseLocation.y-16-(titleSize.height+3),
	     		      titleSize.width, titleSize.height);
      titleRect = NSMakeRect(0,0, titleSize.width,titleSize.height);*/
      contentRect = [NSWindow frameRectForContentRect:titleRect 
	                                    styleMask:NSBorderlessWindowMask];

      ttWindow = [[NSWindow alloc] initWithContentRect:windowRect
	                                     styleMask:NSBorderlessWindowMask
					       backing:NSBackingStoreRetained
					         defer:YES];
      [ttWindow setExcludedFromWindowsMenu:YES];

      ttText = [[NSTextField alloc] initWithFrame:contentRect];
      [ttText setEditable:NO];
      [ttText setSelectable:NO];
      [ttText setBezeled:NO];
      [ttText setBordered:YES];
      [ttText setBackgroundColor:[NSColor colorWithDeviceRed:1.0
                                                       green:1.0
						        blue:0.80
						       alpha:1.0]];
      [ttText setFont:[self font]];
      [ttText setStringValue:[self title]];
      [[ttWindow contentView] addSubview:ttText];
    }
  else if (![ttWindow isVisible])
    {
      [ttWindow setFrameOrigin:
	NSMakePoint(mouseLocation.x,
		    mouseLocation.y-16-(titleSize.height+3))];
      [ttWindow orderFront:self];
    }
}

- (void)mouseEntered:(NSEvent *)theEvent
{
 // NSLog (@"mouseEntered");

  if (ttTimer == nil)
    {
      ttTimer = [NSTimer
	scheduledTimerWithTimeInterval:0.5
	                        target:self
			      selector:@selector(showTooltip:)
			      userInfo:nil
                               repeats:YES];
    }
}

- (void)mouseExited:(NSEvent *)theEvent
{
//  NSLog (@"mouseExited");

  if (ttTimer != nil)
    {
//      NSLog (@"-- invalidate");
      [ttTimer invalidate];
      ttTimer = nil;

      if (ttWindow && [ttWindow isVisible])
	{
	  [ttWindow orderOut:self];
	}
    }
}

- (void)mouseDown:(NSEvent *)theEvent
{
//  NSLog (@"mouseDown");

  if (ttTimer != nil)
    {
//      NSLog (@"-- invalidate");
      [ttTimer invalidate];
      ttTimer = nil;
    }

  [super mouseDown:theEvent];
}

- (void)mouseMoved:(NSEvent *)theEvent
{
  mouseLocation = [NSEvent mouseLocation];
//  NSLog (@"mouseMoved %f %f", mouseLocation.x, mouseLocation.y);
  if (ttWindow && [ttWindow isVisible])
    {
      [ttWindow orderOut:self];
    }
}

//
// Tool Tips
//

- (void)_invalidateToolTip:(NSTimer *)timer
{
  [timer invalidate];
  timer = nil;

  if (ttWindow && [ttWindow isVisible])
    {
      [ttWindow orderOut:self];
    }
}

- (NSToolTipTag) addToolTipRect: (NSRect)aRect
                          owner: (id)anObject
                       userData: (void *)data
{
  SEL ownerSelector = @selector(view:stringForToolTip:point:userData:);
  
/*  if (aRect == NSZeroRect)
    {
      return;
    }*/

  if (![anObject respondsToSelector:ownerSelector] 
      && ![anObject isKindOfClass:[NSString class]])
    {
      return;
    }

  tRectTag = [[self superview] addTrackingRect:aRect
                                         owner:self
                                      userData:data
                                  assumeInside:NO];
  [[self window] setAcceptsMouseMovedEvents:YES];
  
  if (ttTimer == nil)
    {
      ttTimer = [NSTimer
	scheduledTimerWithTimeInterval:0.5
	                        target:self
			      selector:@selector(showTooltip:)
			      userInfo:nil
                               repeats:YES];
    }

  return 0;
}
   
- (void) removeAllToolTips
{
}
   
- (void) removeToolTip: (NSToolTipTag)tag
{
}
                              
- (void) setToolTip: (NSString *)string
{
  ASSIGN(_toolTipText, string);

  if (string == nil)
    {
      _hasTooltip = NO;
      if (ttTimer != nil)
	{
	}
    }
    
  if (_hasTooltip)
    {
      tRectTag = [[self superview] addTrackingRect:[self frame]
	                                     owner:self
                                          userData:nil
                                      assumeInside:NO];
      [[self window] setAcceptsMouseMovedEvents:YES];
    }
}
   
- (NSString *) toolTip
{
  return _toolTipText;
}

@end

