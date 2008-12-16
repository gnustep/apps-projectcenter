/* All Rights reserved */

#include <AppKit/AppKit.h>
#include "PCDebugger.h"

@implementation PCDebugger
- (id) init
{
  if((self == [super init]) != nil)
    {
      // initialization here...
    }
  return self;
}

- (void) startDebugger
{
  debuggerTask = [NSTask launchedTaskWithLaunchPath: @"/usr/bin/gdb" 
			 arguments: @""];
  standardInput = [debuggerTask standardInput];
  standardOutput = [debuggerTask standardOutput];
}

- (void) awakeFromNib
{
  [consoleView setFont: [NSFont userFixedPitchFontOfSize: 0]];
  [self startDebugger];
}
@end
