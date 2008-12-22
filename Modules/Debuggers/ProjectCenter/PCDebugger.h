/* All Rights reserved */

#include <stdio.h>

#import <AppKit/AppKit.h>
#import <Foundation/Foundation.h>

#import <Protocols/CodeDebugger.h>

@interface PCDebugger : NSObject <CodeDebugger>
{
  id             debuggerView;
  id             debuggerWindow;
  NSString       *path;
  NSString       *debuggerPath;
  NSTask         *debuggerTask;
  NSPipe         *standardInput;
  NSPipe         *standardOutput;
  NSPipe         *standardError;
  NSFileHandle   *readHandle;
  NSFileHandle   *errorReadHandle;
  BOOL           _isLogging;
  BOOL           _isErrorLogging;  
}

- (void)putChar:(unichar)ch;

@end
