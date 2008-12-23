/* All Rights reserved */

#include <AppKit/AppKit.h>
#include "PCDebuggerView.h"

@implementation PCDebuggerView

/** set the controlling debugger instance */
-(void)setDebugger:(PCDebugger *)theDebugger
{
  debugger = theDebugger;
}

/** respond to key events and pipe them down to the debugger */
-(BOOL)performKeyEquivalent: (NSEvent*)theEvent
{
    NSString *chars;
    
    chars = [theEvent characters];
    if ([chars length] == 1)
    {
        unichar c;
        c = [chars characterAtIndex: 0];

	NSLog(@"character: %c", c);
        [debugger putChar:c];
    }    
    return YES; // [super performKeyEquivalent:theEvent];
}

@end
