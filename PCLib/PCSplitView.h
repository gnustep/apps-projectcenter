/* 
 * PCSplitView.h created by probert on 2002-01-27 13:36:09 +0000
 *
 * Project ProjectCenter
 *
 * Created with ProjectCenter - http://www.gnustep.org
 *
 * $Id$
 */

#ifndef _PCSPLITVIEW_H_
#define _PCSPLITVIEW_H_

#import <AppKit/AppKit.h>

@interface PCSplitView : NSSplitView
{

}

- (float)dividerThickness;

- (void)drawDividerInRect:(NSRect)aRect;

@end

#endif // _PCSPLITVIEW_H_

