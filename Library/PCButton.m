/*
  GNUstep ProjectCenter - http://www.gnustep.org
 
  Copyright (C) 2003 Free Software Foundation
 
  Author: Serg Stoyan
 
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
  [self setCell:[[PCButtonCell alloc] init]];
  [self setImagePosition: NSImageOnly];
  [self setFont: [NSFont systemFontOfSize: 10.0]];

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

@end

@implementation PCButtonCell

- (id)init
{
  self = [super init];
  tile = [[NSImage alloc] initWithContentsOfFile:[[NSBundle mainBundle]
    pathForImageResource:@"ButtonTile"]];

  return self;
}

- (void)dealloc 
{
  RELEASE(tile);

  [super dealloc];
}

- (void) drawInteriorWithFrame: (NSRect)cellFrame inView: (NSView*)controlView
{
  [super drawInteriorWithFrame: cellFrame inView: controlView];

  if (!_cell.is_highlighted)
    {
      NSPoint  position;
      NSImage  *imageToDisplay;
      unsigned mask = 0;

      if ([controlView isFlipped])
	{
	  position = NSMakePoint(cellFrame.origin.x+1, 
				 cellFrame.size.height-2);
	}
      else
	{
	  position = NSMakePoint(1, 2);
	}

      // Tile
      [tile compositeToPoint:position
  	           operation:NSCompositeSourceOver];

      if (_cell.state)
	mask = _showAltStateMask;

      // Image
      [_cell_image setBackgroundColor:[NSColor clearColor]];
      [_altImage setBackgroundColor:[NSColor clearColor]];
      if (mask & NSContentsCellMask)
	{
	  imageToDisplay = _altImage;
	}
      else
	{
	  imageToDisplay = _cell_image;
	}
	
      position.x = (cellFrame.size.width - [_cell_image size].width)/2;
      position.y = (cellFrame.size.height - [_cell_image size].height)/2;
      if (_cell.is_disabled)
	{
	  [_cell_image dissolveToPoint:position fraction:0.5];
	}
      else
	{
	  [imageToDisplay compositeToPoint:position
	                         operation:NSCompositeSourceOver];
	}
    }
}

@end

