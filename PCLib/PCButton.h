/**/

#ifndef _PCBUTTON_H_
#define _PCBUTTON_H_

#include <AppKit/AppKit.h>

/*
 * Button
 */
@interface PCButton : NSButton
{
  NSTrackingRectTag tRectTag;
  NSTimer           *ttTimer;
  NSWindow          *ttWindow;
  NSPoint           mouseLocation;

  BOOL _hasTooltip;
}

- (void)setShowTooltip:(BOOL)yn;

- (void)updateTrackingRect;

@end

/*
 * Button Cell
 */
@interface PCButtonCell : NSButtonCell
{
  NSImage *tile;
}

@end

#endif
