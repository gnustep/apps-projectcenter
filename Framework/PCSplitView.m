/*
   GNUstep ProjectCenter - http://www.gnustep.org/experience/ProjectCenter.html

   Copyright (C) 2002-2004 Free Software Foundation

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

#import <AppKit/AppKit.h>

#import <ProjectCenter/PCSplitView.h>

static NSNotificationCenter *nc = nil;

@implementation PCSplitView

- (float)dividerThickness
{
  return 8.0f;
}

- (void)drawDividerInRect:(NSRect)aRect
{
  [super drawDividerInRect:aRect];
}

/*- (void)mouseDown:(NSEvent*)theEvent
{
  [super mouseDown:theEvent];
  [self adjustSubviews];
}*/

- (void)mouseDown:(NSEvent*)theEvent
{
  NSApplication	*app = [NSApplication sharedApplication];
  static NSRect	oldRect; //only one can be dragged at a time
  static BOOL	lit = NO;
  NSPoint	p, op;
  NSEvent	*e;
  NSRect	r, r1, bigRect, vis;
  id		v = nil, prev = nil;
  float		minCoord, maxCoord;
  NSArray	*subs = [self subviews];
  int		offset = 0, i, count = [subs count];
  float		divVertical, divHorizontal;
  NSDate	*farAway = [NSDate distantFuture];
  NSDate	*longTimeAgo = [NSDate distantPast];
  unsigned	int eventMask = NSLeftMouseUpMask | NSLeftMouseDraggedMask;
  /* YES if delegate implements splitView:constrainSplitPosition:ofSubviewAt:*/
  BOOL          delegateConstrains = NO;
  SEL constrainSel = @selector(splitView:constrainSplitPosition:ofSubviewAt:);
  typedef float (*floatIMP)(id, SEL, id, float, int);
  floatIMP constrainImp = NULL;

  /*  if there are less the two subviews, there is nothing to do */
  if (count < 2)
    {
      return;
    }

  /* Silence compiler warnings.  */
  r1 = NSZeroRect;
  bigRect = NSZeroRect;

  vis = [self visibleRect];

  /* find out which divider it is */
  p = [theEvent locationInWindow];
  p = [self convertPoint: p fromView: nil];
  for (i = 0; i < count; i++)
    {
      v = [subs objectAtIndex: i];
      r = [v frame];
      /* if the click is inside of a subview, return.  this should
	 happen only if a subview has leaked a mouse down to next
	 responder
       */
      if (NSPointInRect(p, r))
	{
	  NSDebugLLog(@"NSSplitView",
		      @"NSSplitView got mouseDown in subview area");
	  return;
	}
      if (_isVertical == NO)
	{
	  if (NSMinY(r) >= p.y)
	    {
	      offset = i - 1;

	      /* get the enclosing rect for the two views */
	      if (prev != nil)
		{
		  r = [prev frame];
		}
	      else
		{
		  /*
		   * This happens if user pressed exactly on the
		   * top of the top subview
		   */
		  return;
		}
	      if (v != nil)
		{
		  r1 = [v frame];
		}
	      bigRect = r;
	      bigRect = NSUnionRect(r1 , bigRect);
	      break;
	    }
	  prev = v;
	}
      else
	{
	  if (NSMinX(r) >= p.x)
	    {
	      offset = i - 1;

	      /* get the enclosing rect for the two views */
	      if (prev != nil)
		{
		  r = [prev frame];
		}
	      else
		{
		  /*
		   * This happens if user pressed exactly on the
		   * left of the left subview
		   */
		  return;
		}
	      if (v != nil)
		{
		  r1 = [v frame];
		}
	      bigRect = r;
	      bigRect = NSUnionRect(r1 , bigRect);
	      break;
	    }
	  prev = v;
	}
    }

  /* Check if the delegate wants to constrain the spliview divider to
     certain positions */
  if (_delegate 
      && [_delegate respondsToSelector:
		   @selector(splitView:constrainSplitPosition:ofSubviewAt:)])
    {
      delegateConstrains = YES;
    }

  if (_isVertical == NO)
    {
      divVertical = _dividerWidth;
      divHorizontal = NSWidth(_frame);
      /* set the default limits on the dragging */
      minCoord = NSMinY(bigRect) + divVertical;
      maxCoord = NSHeight(bigRect) + NSMinY(bigRect) - divVertical;
    }
  else
    {
      divHorizontal = _dividerWidth;
      divVertical = NSHeight(_frame);
      /* set the default limits on the dragging */
      minCoord = NSMinX(bigRect) + divHorizontal;
      maxCoord = NSWidth(bigRect) + NSMinX(bigRect) - divHorizontal;
    }

  /* find out what the dragging limit is */
  if (_delegate)
    {
      float delMin = minCoord, delMax = maxCoord;

      if ([_delegate respondsToSelector:
		    @selector(splitView:
		 constrainMinCoordinate:
			  maxCoordinate:
			    ofSubviewAt:)])
	{
	  [_delegate splitView:self
	constrainMinCoordinate:&delMin
		 maxCoordinate:&delMax
		   ofSubviewAt:offset];
	}
      else 
	{
	  if ([_delegate respondsToSelector:
			@selector(splitView:
		     constrainMinCoordinate:
				ofSubviewAt:)])
	    {
	      delMin = [_delegate splitView:self
		     constrainMinCoordinate:minCoord
				ofSubviewAt:offset];
	    }
	  if ([_delegate respondsToSelector:
			@selector(splitView:constrainMaxCoordinate:ofSubviewAt:)])
	    {
	      delMax = [_delegate splitView: self
		     constrainMaxCoordinate: maxCoord
				ofSubviewAt: offset];
	    }
	}

      /* we are still constrained by the original bounds */
      if (delMin > minCoord)
	{
	  minCoord = delMin;
	}
      if (delMax < maxCoord)
	{
	  maxCoord = delMax;
	}
    }

  oldRect = NSZeroRect;
  [self lockFocus];

  [[NSRunLoop currentRunLoop] limitDateForMode: NSEventTrackingRunLoopMode];

  [_dividerColor set];
  r.size.width = divHorizontal;
  r.size.height = divVertical;
  e = [app nextEventMatchingMask: eventMask
		       untilDate: farAway
			  inMode: NSEventTrackingRunLoopMode
			 dequeue: YES];

  if (delegateConstrains)
    {
      constrainImp = (floatIMP)[_delegate methodForSelector: constrainSel];
    }

  // Save the old position
  op = p;
//  NSLog(@"SplitView: entering knob loop");
//--- Dragging start ----------------------------------------------------------
  // user is moving the knob loop until left mouse up
  while ([e type] != NSLeftMouseUp)
    {
      p = [self convertPoint: [e locationInWindow] fromView: nil];
      if (delegateConstrains)
	{
	  if (_isVertical)
	    {
	      p.x = (*constrainImp)(_delegate, constrainSel, self,
				    p.x, offset);
	    }
	  else
	    {
	      p.y = (*constrainImp)(_delegate, constrainSel, self,
				    p.y, offset);
	    }
	}

      if (_isVertical == NO)
	{
	  if (p.y < minCoord)
	    {
	      p.y = minCoord;
	    }
	  if (p.y > maxCoord)
	    {
	      p.y = maxCoord;
	    }
	  r.origin.y = p.y - (divVertical/2.);
	  r.origin.x = NSMinX(vis);
	}
      else
	{
	  if (p.x < minCoord)
	    {
	      p.x = minCoord;
	    }
	  if (p.x > maxCoord)
	    {
	      p.x = maxCoord;
	    }
	  r.origin.x = p.x - (divHorizontal/2.);
	  r.origin.y = NSMinY(vis);
	}
      if (NSEqualRects(r, oldRect) == NO)
	{
	  NSDebugLLog(@"NSSplitView", @"drawing divider at %@\n",
		      NSStringFromRect(r));
	  [_dividerColor set];


	  if (lit == YES)
	    {
	      if (_isVertical == NO)
		{
		  if ((NSMinY(r) > NSMaxY(oldRect)) 
		      || (NSMaxY(r) < NSMinY(oldRect)))
		    // the two rects don't intersect
		    {
		      NSHighlightRect(oldRect);
		      NSHighlightRect(r);
		    }
		  else
		    // the two rects intersect
		    {
		      if (NSMinY(r) > NSMinY(oldRect))
			{
			  NSRect onRect, offRect;
			  onRect.size.width = r.size.width;
			  onRect.origin.x = r.origin.x;
			  offRect.size.width = r.size.width;
			  offRect.origin.x = r.origin.x;

			  offRect.origin.y = NSMinY(oldRect);
			  offRect.size.height = 
			    NSMinY(r) - NSMinY(oldRect);

			  onRect.origin.y = NSMaxY(oldRect);
			  onRect.size.height = 
			    NSMaxY(r) - NSMaxY(oldRect);

			  NSHighlightRect(onRect);
			  NSHighlightRect(offRect);

			  //NSLog(@"on : %@", NSStringFromRect(onRect));
			  //NSLog(@"off : %@", NSStringFromRect(offRect));
			  //NSLog(@"old : %@", NSStringFromRect(oldRect));
			  //NSLog(@"r : %@", NSStringFromRect(r));
			}
		      else
			{
			  NSRect onRect, offRect;
			  onRect.size.width = r.size.width;
			  onRect.origin.x = r.origin.x;
			  offRect.size.width = r.size.width;
			  offRect.origin.x = r.origin.x;

			  offRect.origin.y = NSMaxY(r);
			  offRect.size.height = 
			    NSMaxY(oldRect) - NSMaxY(r);

			  onRect.origin.y = NSMinY(r);
			  onRect.size.height = 
			    NSMinY(oldRect) - NSMinY(r);

			  NSHighlightRect(onRect);
			  NSHighlightRect(offRect);

			  //NSLog(@"on : %@", NSStringFromRect(onRect));
			  //NSLog(@"off : %@", NSStringFromRect(offRect));
			  //NSLog(@"old : %@", NSStringFromRect(oldRect));
			  //NSLog(@"r : %@", NSStringFromRect(r));
			}
		    }
		}
	      else
		{
		  if ((NSMinX(r) > NSMaxX(oldRect)) 
		      || (NSMaxX(r) < NSMinX(oldRect)))
		    // the two rects don't intersect
		    {
		      NSHighlightRect (oldRect);
		      NSHighlightRect(r);
		    }
		  else
		    // the two rects intersect
		    {
		      if (NSMinX(r) > NSMinX(oldRect))
			{
			  NSRect onRect, offRect;
			  onRect.size.height = r.size.height;
			  onRect.origin.y = r.origin.y;
			  offRect.size.height = r.size.height;
			  offRect.origin.y = r.origin.y;

			  offRect.origin.x = NSMinX(oldRect);
			  offRect.size.width = 
			    NSMinX(r) - NSMinX(oldRect);

			  onRect.origin.x = NSMaxX(oldRect);
			  onRect.size.width = 
			    NSMaxX(r) - NSMaxX(oldRect);

			  NSHighlightRect(onRect);
			  NSHighlightRect(offRect);
			}
		      else
			{
			  NSRect onRect, offRect;
			  onRect.size.height = r.size.height;
			  onRect.origin.y = r.origin.y;
			  offRect.size.height = r.size.height;
			  offRect.origin.y = r.origin.y;

			  offRect.origin.x = NSMaxX(r);
			  offRect.size.width = 
			    NSMaxX(oldRect) - NSMaxX(r);

			  onRect.origin.x = NSMinX(r);
			  onRect.size.width = 
			    NSMinX(oldRect) - NSMinX(r);

			  NSHighlightRect(onRect);
			  NSHighlightRect(offRect);
			}
		    }

		}
	    }
	  else
	    {
	      NSHighlightRect(r);
	    }
	  [_window flushWindow];
	  /*
	     if (lit == YES)
	     {
	     NSHighlightRect(oldRect);
	     lit = NO;
	     }
	     NSHighlightRect(r);
	   */
	  lit = YES;
	  oldRect = r;
	}

	{
	  NSEvent *ee;

	  e = [app nextEventMatchingMask: eventMask
			       untilDate: farAway
				  inMode: NSEventTrackingRunLoopMode
				 dequeue: YES];

	  if ((ee = [app nextEventMatchingMask: NSLeftMouseUpMask
				     untilDate: longTimeAgo
					inMode: NSEventTrackingRunLoopMode
				       dequeue: YES]) != nil)
	    {
	      [app discardEventsMatchingMask:NSLeftMouseDraggedMask
				 beforeEvent:ee];
	      e = ee;
	    }
	  else
	    {
	      ee = e;
	      do
		{
		  e = ee;
		  ee = [app nextEventMatchingMask: NSLeftMouseDraggedMask
					untilDate: longTimeAgo
					   inMode: NSEventTrackingRunLoopMode
					  dequeue: YES];
		}
	      while (ee != nil);
	    }
	}

    }
//--- Draggind end ------------------------------------------------------------
  NSLog(@"SplitView: exiting knob loop: %f -- %f", op.x, p.x);

  if (lit == YES)
    {
      [_dividerColor set];
      NSHighlightRect(oldRect);
      lit = NO;
    }

  [self unlockFocus];

  // Divider position hasn't changed don't try to resize subviews  
  if (_isVertical == YES) // This
    {                     // was
      if (p.x == op.x)    // fixed
	{
	  NSLog(@"Divider position hasn't changed: %f == %f", p.x, op.x);
	  [self setNeedsDisplay: YES];
	  return;
	}
    }
  else if (p.y == op.y)   
    {
      NSLog(@"Divider position hasn't changed: %f == %f", p.y, op.y);
      [self setNeedsDisplay: YES];
      return;
    }

  [nc postNotificationName: NSSplitViewWillResizeSubviewsNotification
		    object: self];

  /* resize the subviews accordingly */
  r = [prev frame];
  if (_isVertical == NO)
    {
      r.size.height = p.y - NSMinY(bigRect) - (divVertical/2.);
      if (NSHeight(r) < 1.)
	{
	  r.size.height = 1.;
	}
    }
  else
    {
      r.size.width = p.x - NSMinX(bigRect) - (divHorizontal/2.);
      if (NSWidth(r) < 1.)
	{
	  r.size.width = 1.;
	}
    }
  [prev setFrame: r];
  NSDebugLLog(@"NSSplitView", @"drawing PREV at x: %d, y: %d, w: %d, h: %d\n",
	      (int)NSMinX(r),(int)NSMinY(r),(int)NSWidth(r),(int)NSHeight(r));

  r1 = [v frame];
  if (_isVertical == NO)
    {
      r1.origin.y = p.y + (divVertical/2.);
      if (NSMinY(r1) < 0.)
	{
	  r1.origin.y = 0.;
	}
      r1.size.height = NSHeight(bigRect) - NSHeight(r) - divVertical;
      if (NSHeight(r) < 1.)
	{
	  r.size.height = 1.;
	}
    }
  else
    {
      r1.origin.x = p.x + (divHorizontal/2.);
      if (NSMinX(r1) < 0.)
	{
	  r1.origin.x = 0.;
	}
      r1.size.width = NSWidth(bigRect) - NSWidth(r) - divHorizontal;
      if (NSWidth(r1) < 1.)
	{
	  r1.size.width = 1.;
	}
    }
  [v setFrame: r1];
  NSLog(@"NSSplitView drawing LAST at x: %d, y: %d, w: %d, h: %d\n",
  	(int)NSMinX(r1),(int)NSMinY(r1),(int)NSWidth(r1),(int)NSHeight(r1));

  [_window invalidateCursorRectsForView: self];

  [nc postNotificationName: NSSplitViewDidResizeSubviewsNotification
		    object: self];

//  [self _autosaveSubviewProportions];

  [self setNeedsDisplay: YES];

  //[self display];
}

@end
