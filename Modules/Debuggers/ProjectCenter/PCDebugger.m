/* All Rights reserved */

#include <AppKit/AppKit.h>
#include "PCDebugger.h"
#include "PCDebuggerView.h"

#ifndef NOTIFICATION_CENTER
#define NOTIFICATION_CENTER [NSNotificationCenter defaultCenter]
#endif

@implementation PCDebugger
- (id) init
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

-(void) debugExecutableAtPath: (NSString *)filePath
	       withDebugger: (NSString *)debugger
{
  ASSIGN(path,filePath);
  ASSIGN(debuggerPath,debugger);
  [debuggerWindow setTitle: [NSString stringWithFormat: @"Debugger (%@)",filePath]];
  [self show];
}

- (void) show
{
  [debuggerWindow makeKeyAndOrderFront: self];
  [self startDebugger];
}

- (void)logErrorString:(NSString *)string
{
  /*
  NSArray *items;

  items = [self parseErrorLine:string];
  if (items)
    {
      [errorArray addObjectsFromArray:items];
      [errorOutput reloadData];
      [errorOutput scrollRowToVisible:[errorArray count]-1];
    }
  */
}

- (void)logString:(NSString *)str
            error:(BOOL)yn
	  newLine:(BOOL)newLine
{
  NSTextView *out = debuggerView;

  [out replaceCharactersInRange:
    NSMakeRange([[out string] length],0) withString:str];

  if (newLine)
    {
      [out replaceCharactersInRange:
	NSMakeRange([[out string] length], 0) withString:@"\n"];
    }
  else
    {
      [out replaceCharactersInRange:
	NSMakeRange([[out string] length], 0) withString:@" "];
    }

  [out scrollRangeToVisible:NSMakeRange([[out string] length], 0)];
  [out setNeedsDisplay:YES];
}

- (void)logData:(NSData *)data
          error:(BOOL)yn
{
  NSString *dataString;
  // NSRange  newLineRange;
  // NSRange  lineRange;
  // NSString *lineString;

  dataString = [[NSString alloc] 
		 initWithData:data 
		 encoding:[NSString defaultCStringEncoding]];
  
  // Process new data
  /*
  lineRange.location = 0;
  [errorString appendString:dataString];
  while (newLineRange.location != NSNotFound)
    {
      newLineRange = [errorString rangeOfString:@"\n"];
      if (newLineRange.location < [errorString length])
	{
	  lineRange.length = newLineRange.location+1;
	  lineString = [errorString substringWithRange:lineRange];
	  [errorString deleteCharactersInRange:lineRange];
	  
	  // [self parseBuildLine:lineString];
	  // if (yn)
	  //  {
	  //    [self logErrorString:lineString];
	  //  }
	  
	  [self logString:lineString error:yn newLine:NO];
	}
      else
	{
	  newLineRange.location = NSNotFound;
	  continue;
	}
    }
  */
  [self logString:dataString error:yn newLine:NO];

  RELEASE(dataString);
}

- (void)logStdOut:(NSNotification *)aNotif
{
  NSData *data;

  if ((data = [readHandle availableData]) && [data length] > 0)
    {
      [self logData:data error:NO];
    }

  if (debuggerTask)
    {
      [readHandle waitForDataInBackgroundAndNotify];
    }
  else
    {
      _isLogging = NO;
      [NOTIFICATION_CENTER removeObserver:self 
			             name:NSFileHandleDataAvailableNotification
			           object:readHandle];
    }
}

- (void)logErrOut:(NSNotification *)aNotif
{
  NSData *data;
  
  if ((data = [errorReadHandle availableData]) && [data length] > 0)
    {
      [self logData:data error:YES];
    }

  if (debuggerTask)
    {
      [errorReadHandle waitForDataInBackgroundAndNotify];
    }
  else
    {
      _isErrorLogging = NO;
      [NOTIFICATION_CENTER removeObserver:self 
			             name:NSFileHandleDataAvailableNotification
			           object:errorReadHandle];
    }
}

- (void) startDebugger
{
  standardOutput = [NSPipe pipe];
  standardError = [NSPipe pipe];

  readHandle = [standardOutput fileHandleForReading];
  [readHandle waitForDataInBackgroundAndNotify];
  
  [NOTIFICATION_CENTER addObserver:self 
		       selector:@selector(logStdOut:)
		       name:NSFileHandleDataAvailableNotification
		       object:readHandle];

  _isLogging = YES;
  standardError = [NSPipe pipe];
  errorReadHandle = [standardError fileHandleForReading];
  [errorReadHandle waitForDataInBackgroundAndNotify];
  
  [NOTIFICATION_CENTER addObserver:self 
		       selector:@selector(logErrOut:) 
		       name:NSFileHandleDataAvailableNotification
		       object:errorReadHandle];
  _isErrorLogging = YES;
  
  // [statusField setStringValue:buildStatus];
  
  // Run make task
  [debuggerView setString:@""];  
  [NOTIFICATION_CENTER addObserver:self 
  		       selector:@selector(debuggerDidTerminate:) 
		       name:NSTaskDidTerminateNotification
		       object:nil];


  debuggerTask = [[NSTask alloc] init];
  [debuggerTask setArguments: [[NSArray alloc] initWithObjects: @"--args", path, nil]];
  [debuggerTask setCurrentDirectoryPath: [path stringByDeletingLastPathComponent]];
  [debuggerTask setLaunchPath: debuggerPath];
  [debuggerTask setStandardOutput: standardOutput];
  [debuggerTask setStandardError: standardError];
    
  NS_DURING
    {
      [debuggerTask launch];
    }
  NS_HANDLER
    {
      NSRunAlertPanel(@"Problem Launching Debugger",
		      [localException reason],
		      @"OK", nil, nil, nil);
      
      //Clean up after task is terminated
      [[NSNotificationCenter defaultCenter] 
        postNotificationName:NSTaskDidTerminateNotification
        object:debuggerTask];
    }
  NS_ENDHANDLER
}   

- (void) debuggerDidTerminate: (NSNotification *)notif
{
  [self logString: @"=== Debugger Terminated ===" error: NO newLine:YES];
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
  // fputc(ch, stdInStream);
}
@end
