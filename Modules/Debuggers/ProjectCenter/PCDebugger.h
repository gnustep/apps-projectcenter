/* All Rights reserved */

#include <AppKit/AppKit.h>
#include <Foundation/Foundation.h>

@interface PCDebugger : NSObject
{
  id consoleView;
  id consoleWindow;
  NSTask *debuggerTask;
  id standardInput;
  id standardOutput;
}
@end
