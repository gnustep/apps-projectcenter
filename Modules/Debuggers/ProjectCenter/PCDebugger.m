/* All Rights reserved */

#include <AppKit/AppKit.h>
#include "PCDebugger.h"
#import "PCDebuggerView.h"

@implementation PCDebugger
- (id) initWithPath: (NSString *)filePath
{
  if((self = [super init]) != nil)
    {
      // initialization here...
      if([NSBundle loadNibNamed: @"PCDebugger" owner: self] == NO)
	{
	  return nil;
	}
	[(PCDebuggerView *)debuggerView setDebugger:self];
    }
  return self;
}

+(id) debugExecutableAtPath: (NSString *)filePath
{
  return [[self alloc] initWithPath: filePath];
}

- (void) show
{
  [debuggerWindow makeKeyAndOrderFront: self];
  [self startDebugger];
}

- (void) startDebugger
{
  debuggerTask = [NSTask launchedTaskWithLaunchPath: @"/usr/bin/gdb" 
			 arguments: NULL];
  standardInput = [debuggerTask standardInput];
  standardOutput = [debuggerTask standardOutput];
  
  stdInStream = fdopen([standardInput fileDescriptor], "r");
  if (stdInStream == NULL)
    {
      NSLog(@"Error creating file stream input to debugger");
      return;
    }
}

- (void) awakeFromNib
{
  [debuggerView setFont: [NSFont userFixedPitchFontOfSize: 0]];
}

- (NSWindow *)debuggerWindow
{
  return debuggerWindow;
}

- (void)setDebuggerWindow: (NSWindow *)window
{
  ASSIGN(debuggerWindow,window);
}

- (NSView *)debuggerView
{
  return debuggerView;
}

- (void)setDebuggerView: (id)view
{
  ASSIGN(debuggerView,view);
}

- (NSString *)path
{
  return path;
}

- (void)setPath:(NSString *)p
{
  ASSIGN(path,p);
}

- (void)putChar:(unichar)ch
{
  fputc(ch, stdInStream);
}
@end
