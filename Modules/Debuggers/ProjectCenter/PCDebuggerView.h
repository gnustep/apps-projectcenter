/* All Rights reserved */

#include <AppKit/AppKit.h>

#import "PCDebugger.h"

@interface PCDebuggerView : NSTextView
{
  PCDebugger *debugger;
}

-(void)setDebugger:(PCDebugger *)theDebugger;

@end
