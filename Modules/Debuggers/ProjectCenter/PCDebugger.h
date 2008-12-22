/* All Rights reserved */

#include <AppKit/AppKit.h>
#include <Foundation/Foundation.h>

#include <Protocols/CodeDebugger.h>

@interface PCDebugger : NSObject <CodeDebugger>
{
  id debuggerView;
  id debuggerWindow;
  NSString *path;
  NSTask *debuggerTask;
  id standardInput;
  id standardOutput;
}
@end
