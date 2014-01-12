/*
  GNUstep ProjectCenter - http://www.gnustep.org/experience/ProjectCenter.html
 
  Copyright (C) 2003-2014 Free Software Foundation
 
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

#import <ProjectCenter/PCButton.h>
#import <ProjectCenter/PCDefines.h>

#import <AppKit/NSBezierPath.h>
#import <GNUstepGUI/GSTrackingRect.h>

@implementation PCButton

// ============================================================================
// ==== Main
// ============================================================================

- (id)initWithCoder:(NSCoder *)coder
{
  self = [super initWithCoder:coder];
  [_cell setGradientType:NSGradientConcaveWeak];
  [_cell setImageDimsWhenDisabled:YES];
  [self setImagePosition:NSImageOnly];
  [self setFont:[NSFont systemFontOfSize:[NSFont smallSystemFontSize]]];
  [self setRefusesFirstResponder:YES];

  _hasTooltips = NO;
  ttTimer = nil;
  ttWindow = nil;
  ttTitleAttrs = [[NSMutableDictionary alloc] init];
  [ttTitleAttrs setObject:[NSFont systemFontOfSize:10.0]
 	           forKey:NSFontAttributeName];
  ttBackground = [NSColor colorWithDeviceRed:1.0 green:1.0 blue:0.90 alpha:1.0];
  RETAIN(ttBackground);

  [[NSNotificationCenter defaultCenter] 
    addObserver:self
       selector:@selector(_updateTrackingRects:)
           name:NSViewFrameDidChangeNotification
         object:[[self window] contentView]];

  return self;
}

- (void)dealloc
{ 
  [[NSNotificationCenter defaultCenter] removeObserver:self];

  if (_hasTooltips)
    {
      [self removeAllToolTips];
      RELEASE(ttTitleAttrs);
      RELEASE(ttBackground);
      RELEASE(ttWindow);
    }

  [super dealloc];
}

- (oneway void)release
{
  // If retain count is number of tracking rects + superview retain,
  // remove tracking rects. It seems that tracking rects retain this object.
  if (_hasTooltips && [self retainCount] == [_tracking_rects count] + 1)
    {
      [self removeAllToolTips];
    }

  [super release];
}

// ============================================================================
// ==== Private methods
// ============================================================================

- (void)_updateTrackingRects:(NSNotification *)aNotif
{
  NSTrackingRectTag tag;
  NSRect            rect;
  NSString          *string = nil;
  int               i, j;
  GSTrackingRect    *tr = nil;

  if (_hasTooltips == NO)
    {
      return;
    }
    
  j = [_tracking_rects count];
  for (i = 0; i < j; i++)
    {
      tr = [_tracking_rects objectAtIndex:i];
      
      // Save tooltip string for next addTrackingRect::::
      string = [(NSString *)tr->user_data copy];

      [self removeTrackingRect:tr->tag];

//      NSLog(@"PCButton: tr: %i data: %@", tr->tag, tr->user_data);

      rect = [self frame];
      rect.origin.x = 0;
      rect.origin.y = 0;
      tag = [self addTrackingRect:rect
	                    owner:self
	                 userData:string
	             assumeInside:NO];

      if (tr->tag == mainToolTip)
	{
	  mainToolTip = tag;
	}

      RELEASE(string);
    }
}

- (void)_invalidateTimer
{
  if (ttTimer == nil)
    {
      return;
    }

//  NSLog(@"_invalidateTimer");
  if ([ttTimer isValid])
    {
      [ttTimer invalidate];
    }
  ttTimer = nil;
}

- (void)_closeToolTipWindow
{
  if (ttWindow)
    {
      [ttWindow close];
      ttWindow = nil;
    }
}

- (void)_drawToolTip:(NSAttributedString *)title
{
  NSRectEdge sides[] = {NSMinXEdge, NSMaxYEdge, NSMaxXEdge, NSMinYEdge};
  NSColor    *black = [NSColor blackColor];
  NSColor    *colors[] = {black, black, black, black};
  NSRect     bounds = [[ttWindow contentView] bounds];
  NSRect     titleRect;

  titleRect = [ttWindow frame];
  titleRect.origin.x = 2;
  titleRect.origin.y = -2;

  [[ttWindow contentView] lockFocus];

  [title drawInRect:titleRect];
  NSDrawColorTiledRects(bounds, bounds, sides, colors, 4);

  [[ttWindow contentView] unlockFocus];
}

- (void)_showTooltip:(NSTimer *)timer
{
  NSString *ttText = [timer userInfo];
  
  [self _invalidateTimer];

//  NSLog(@"showTooltip: %@", ttText);
//  NSLog(@"toolTips: %@", toolTips);

  if (ttWindow == nil)
    {
      NSAttributedString *attributedTitle = nil;
      NSSize             titleSize;
      NSPoint            mouseLocation = [NSEvent mouseLocation];
      NSRect             windowRect;

      attributedTitle = 
	[[NSAttributedString alloc] initWithString:ttText
	                                attributes:ttTitleAttrs];
      titleSize = [attributedTitle size];

      // Window
      windowRect = NSMakeRect(mouseLocation.x + 8,
			      mouseLocation.y - 16 - (titleSize.height+3),
			      titleSize.width + 4, titleSize.height + 4);

      ttWindow = [[NSWindow alloc] initWithContentRect:windowRect
	                                     styleMask:NSBorderlessWindowMask
					       backing:NSBackingStoreRetained
					         defer:YES];
      [ttWindow setBackgroundColor:ttBackground];
      [ttWindow setReleasedWhenClosed:YES];
      [ttWindow setExcludedFromWindowsMenu:YES];
      [ttWindow setLevel:NSStatusWindowLevel];

      [ttWindow orderFront:nil];

      [self _drawToolTip:attributedTitle];
      RELEASE(attributedTitle);
    }
}

// ============================================================================
// ==== Tool Tips
// ============================================================================

/*- (void)mouseEntered:(NSEvent *)theEvent
{
  NSLog (@"mouseEntered");

  if (ttTimer == nil)
    {
      ttTimer = [NSTimer scheduledTimerWithTimeInterval:0.5
	                                         target:self
			                       selector:@selector(_showTooltip:)
			                       userInfo:[theEvent userData]
                                                repeats:YES];
      [[self window] setAcceptsMouseMovedEvents:YES];
    }
}

- (void)mouseExited:(NSEvent *)theEvent
{
//  NSLog (@"mouseExited");
  [self _invalidateTimer];
  [self _closeToolTipWindow];
  [[self window] setAcceptsMouseMovedEvents:NO];
}

- (void)mouseDown:(NSEvent *)theEvent
{
//  NSLog (@"mouseDown");
  [self _invalidateTimer];
  [self _closeToolTipWindow];

  [super mouseDown:theEvent];
}

- (void)mouseMoved:(NSEvent *)theEvent
{
  NSPoint mouseLocation;
  NSPoint origin;

//  NSLog(@"mouseMoved");
  if (ttWindow == nil)
    {
      return;
    }
  mouseLocation = [NSEvent mouseLocation];
  
  origin = NSMakePoint(mouseLocation.x + 8, 
		       mouseLocation.y - 16 - [ttWindow frame].size.height);

  [ttWindow setFrameOrigin:origin];
}

// NSView methods
- (NSToolTipTag)addToolTipRect:(NSRect)aRect
                         owner:(id)anObject
                      userData:(void *)data
{
  SEL               ownerSelector;
  NSTrackingRectTag tag;
  
  if (NSEqualRects(aRect,NSZeroRect) || ttTimer != nil)
    {
      return -1;
    }

  ownerSelector = @selector(view:stringForToolTip:point:userData:);
  if (![anObject respondsToSelector:ownerSelector] 
      && ![anObject isKindOfClass:[NSString class]])
    {
      return -1;
    }

  // Set rect tracking
  tag = [self addTrackingRect:aRect
                        owner:self
                     userData:data
                 assumeInside:NO];

  return tag;
}
   
- (void)removeAllToolTips
{
  int               i, j;
  GSTrackingRect    *tr = nil;

  if (_hasTooltips == NO)
    {
      return;
    }

  [self _invalidateTimer];
  [self _closeToolTipWindow];

  j = [_tracking_rects count];
  for (i = 0; i < j; i++)
    {
      tr = [_tracking_rects objectAtIndex:i];
      [self removeTrackingRect:tr->tag];
    }

  mainToolTip = -1;
  _hasTooltips = NO;
}
   
- (void)removeToolTip:(NSToolTipTag)tag
{
  [self removeTrackingRect:tag];
}
                              
- (void)setToolTip:(NSString *)string
{
  NSTrackingRectTag tag;
  NSRect            rect;

  if (string == nil) // Remove old tooltip
    {
      if (_hasTooltips)
	{
	  [self _invalidateTimer];
	  [self _closeToolTipWindow];
	  [self removeToolTip:mainToolTip];
	  mainToolTip = -1;
	  _hasTooltips = NO;
	}
    }
  else
    {
//      NSLog(@"setToolTip");
      rect = [self frame];
      rect.origin.x = 0;
      rect.origin.y = 0;
      tag = [self addTrackingRect:rect
                            owner:self
                         userData:string
                     assumeInside:NO];
      _hasTooltips = YES;
    }
}
   
- (NSString *)toolTip
{
  NSEnumerator   *enumerator = [_tracking_rects objectEnumerator];
  GSTrackingRect *tr = nil;
  
  while ((tr = [enumerator nextObject]))
    {
      if (tr->tag == mainToolTip)
	{
	  return tr->user_data;
	}
    }
  
  return nil;
}*/

@end

