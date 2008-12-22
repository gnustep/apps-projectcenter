/* All Rights reserved */

#include <AppKit/AppKit.h>
#include "PCDebuggerView.h"

@implementation PCDebuggerView

/** set the controlling debugger instance */
-(void)setDebugger:(PCDebugger *)theDebugger
{
  debugger = theDebugger;
}

/** respond to key equivalents which are not bound do menu items */
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
    return [super performKeyEquivalent:theEvent];
}

@end
