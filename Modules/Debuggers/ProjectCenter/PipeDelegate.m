/*
**  PipeDelegate.m
**
**  Copyright (c) 2008-2016 Free Software Foundation
**
**  Author: Gregory Casamento <greg.casamento@gmail.com>
**          Riccardo Mottola <rm@gnu.org>
**
**  This program is free software; you can redistribute it and/or modify
**  it under the terms of the GNU General Public License as published by
**  the Free Software Foundation; either version 2 of the License, or
**  (at your option) any later version.
**
**  This program is distributed in the hope that it will be useful,
**  but WITHOUT ANY WARRANTY; without even the implied warranty of
**  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
**  GNU General Public License for more details.
**
**  You should have received a copy of the GNU General Public License
**  along with this program; if not, write to the Free Software
**  Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
*/



#include <sys/stat.h>
#include <signal.h>

#include <stdio.h> /* for stderr and perror*/
#include <errno.h> /* for int errno */
#include <fcntl.h>
#include <sys/types.h>

#include <unistd.h>
#include <stdlib.h>
#include <string.h>

#import "PipeDelegate.h"
#import "PCDebugger.h"

#ifndef NOTIFICATION_CENTER
#define NOTIFICATION_CENTER [NSNotificationCenter defaultCenter]
#endif

@implementation PipeDelegate


- (id)init
{
  if ((self = [super init]))
    {
      userInputColor = [[NSColor blueColor] retain];
      debuggerColor = [[NSColor blackColor] retain];
      messageColor = [[NSColor brownColor] retain];
      errorColor = [[NSColor redColor] retain];
      promptColor = [[NSColor purpleColor] retain];
    }
  return self;
}

- (NSTextView *)textView
{
  return tView;
}

- (void)setTextView: (NSTextView *)tv
{
  if (tView != tv)
    {
      [tView release];
      tView = tv;
      [tView retain];
    }
}

- (PCDebugger *)debugger
{
  return debugger;
}
  
- (void)setDebugger:(PCDebugger *)dbg
{
  if (debugger != dbg)
    {
      [debugger release];
      debugger = dbg;
      [debugger retain];
    }
}

- (NSColor *)userInputColor
{
  return userInputColor;
}

- (NSColor *)debuggerColor
{
  return debuggerColor;
}

- (NSColor *)messageColor
{
  return messageColor;
}

- (NSColor *)errorColor
{
  return errorColor;
}

/**
 * Log string to the view.
 */
- (void) logString:(NSString *)str
	   newLine:(BOOL)newLine
         withColor:(NSColor *)color
{
  NSMutableDictionary *textAttributes;
  NSAttributedString *attrStr;


  if (newLine)
    {
      str = [str stringByAppendingString:@"\n"];
    }

  textAttributes = [NSMutableDictionary dictionary];
  [textAttributes setObject:[NSFont userFixedPitchFontOfSize:0] forKey:NSFontAttributeName];
  if (color)
    {

      [textAttributes  setObject:color forKey:NSForegroundColorAttributeName];
    }

  attrStr = [[NSAttributedString alloc] initWithString: str
                                            attributes: textAttributes];
  
  [[tView textStorage] appendAttributedString: attrStr];
  [attrStr release];


  [tView scrollRangeToVisible:NSMakeRange([[tView string] length], 0)];
  [tView setNeedsDisplay:YES];
}

- (PCDebuggerOutputTypes) parseStringLine: (NSString *)stringInput
{
  BOOL found = NO;
  NSScanner *stringScanner = [NSScanner scannerWithString: stringInput];
  NSString *prefix = NULL;

  [stringScanner scanString: @"(gdb)" intoString: &prefix];
  if(prefix != nil)
    {
      return PCDBPromptRecord;
    }

  [stringScanner scanString: @"=" intoString: &prefix];
  if(prefix != nil)
    {
      NSString *dictionaryName = NULL;
      found = YES;
      
      [stringScanner scanUpToString: @"," intoString: &dictionaryName];

      if([dictionaryName isEqualToString: @"thread-group-started"])
	{	  
	  NSLog(@"%@",dictionaryName);
	}

      if(dictionaryName != nil)
	{	  
	  NSString *key = NULL;
	  NSString *value = NULL;
	  
	  while([stringScanner isAtEnd] == NO)
	    {
	      [stringScanner scanString: @"," intoString: NULL];
	      [stringScanner scanUpToString: @"=" intoString: &key];
	      [stringScanner scanString: @"=" intoString: NULL];
	      [stringScanner scanString: @"\"" intoString: NULL];
	      [stringScanner scanUpToString: @"\"" intoString: &value];
	      [stringScanner scanString: @"\"" intoString: NULL];

	      if([key isEqualToString:@"pid"] && 
		 [dictionaryName isEqualToString: @"thread-group-started"])
		{
		  [debugger setSubProcessId: [value intValue]];
		}
	    }
	}
      return PCDBAsyncInfoRecord;
    }

  [stringScanner scanString: @"*" intoString: &prefix];
  if(prefix != nil)
    {
      return PCDBAsyncStatusRecord;
    }

  [stringScanner scanString: @"<-" intoString: &prefix];
  if(prefix != nil)
    {
      return PCDBBreakpointRecord;
    }
  
  [stringScanner scanString: @"->" intoString: &prefix];
  if(prefix != nil)
    {
      return PCDBBreakpointRecord;
    }

  [stringScanner scanString: @"~" intoString: &prefix];
  if(prefix != nil)
    {
      return PCDBConsoleStreamRecord;
    }

  [stringScanner scanString: @"@" intoString: &prefix];
  if(prefix != nil)
    {
      return PCDBTargetStreamRecord;
    }

  [stringScanner scanString: @"&" intoString: &prefix];
  if(prefix != nil)
    {
      return PCDBDebugStreamRecord;
    }

  [stringScanner scanString: @"^" intoString: &prefix];
  if(prefix != nil)
    {
      NSString *result = nil;
      
      [stringScanner scanString: @"done" intoString: &result];
      if(result != nil)
	{
	  [debugger setStatus: @"Done"];
	  return PCDBResultRecord;
	}
      [stringScanner scanString: @"running" intoString: &result];
      if(result != nil)
	{
	  [debugger setStatus: @"Running"];
	  return PCDBResultRecord;
	}
      [stringScanner scanString: @"connected" intoString: &result];
      if(result != nil)
	{
	  [debugger setStatus: @"Connected"];
	  return PCDBResultRecord;
	}
      [stringScanner scanString: @"error" intoString: &result];
      if(result != nil)
	{
	  [debugger setStatus: @"Error"];
	  return PCDBResultRecord;
	}
      [stringScanner scanString: @"exit" intoString: &result];
      if(result != nil)
	{
	  [debugger setStatus: @"Exit"];
	  return PCDBResultRecord;
	}
      return PCDBResultRecord;
    }

  return PCDBNotFoundRecord;
}

- (NSString *)unescapeOutputRecord: (NSString *)recordString
{
  NSString *unescapedString = [recordString copy];

  unescapedString = [unescapedString stringByReplacingOccurrencesOfString: @"~\"" withString: @""];
  unescapedString = [unescapedString substringToIndex: [unescapedString length] - 1];
  unescapedString = [unescapedString stringByReplacingOccurrencesOfString: @"\"" withString: @"\""];
  unescapedString = [unescapedString stringByReplacingOccurrencesOfString: @"\\n" withString: @"\n"];
  unescapedString = [unescapedString stringByReplacingOccurrencesOfString: @"\\t" withString: @"\t"];
  unescapedString = [unescapedString stringByReplacingOccurrencesOfString: @"\\032" withString: @" "];
  
  return unescapedString;
}

- (void) parseString: (NSString *)inputString
{
  NSArray *components = [inputString componentsSeparatedByString:@"\n"];
  NSEnumerator *en = [components objectEnumerator];
  NSString *item = nil;
  
  while((item = [en nextObject]) != nil) 
    {
      PCDebuggerOutputTypes outtype = [self parseStringLine: item];
      if(outtype == PCDBConsoleStreamRecord || 
	 outtype == PCDBTargetStreamRecord) 
	{
	  NSString *unescapedString = [self unescapeOutputRecord: item]; 
	  [self logString: unescapedString newLine: NO withColor:debuggerColor];
	}
      else if(outtype == PCDBPromptRecord)
	{
	  [self logString: item newLine: NO withColor:promptColor];
	}
      /*
      else if(outtype == PCDBNotFoundRecord)
	{
	  [self logString: item newLine: NO withColor:promptColor];
	}
      */
    }

  /*
  stringRange = [inputString rangeOfString: "(gdb)" options: NULL];
  if(stringRange.location == NSNotFound) 
    {
      [self logString: inputString newLine: NO withColor:debuggerColor];
    }
  else
    {
    }
  */
}

/**
 * Log standard out.
 */ 
- (void) logStdOut:(NSNotification *)aNotif
{
  NSData *data;
  NSFileHandle *handle = stdoutHandle;

  if ((data = [handle availableData]) && [data length] > 0)
    {
      NSString *dataString;
      dataString = [[NSString alloc] 
                     initWithData:data 
                         encoding:[NSString defaultCStringEncoding]];
      
      // if( !
      [self parseString: dataString]; // )
    // {
    //	  [self logString: dataString newLine: NO withColor:debuggerColor];
    //	}
      RELEASE(dataString);
    }
  
  if (task)
    {
      [handle waitForDataInBackgroundAndNotify];
    }
  else
    {
      [NOTIFICATION_CENTER removeObserver: self 
			   name: NSFileHandleDataAvailableNotification
			   object: handle];
    }
}

/**
 * Log error out.
 */ 
- (void) logErrOut:(NSNotification *)aNotif
{
  NSData *data;
  NSFileHandle *handle = error_handle;

  if ((data = [handle availableData]) && [data length] > 0)
    {
      NSString *dataString;
  
      dataString = [[NSString alloc] 
                     initWithData:data
                         encoding:[NSString defaultCStringEncoding]];

      // if(![self parseString: dataString])
	{
	  [self logString: dataString newLine: NO withColor:errorColor];
	}
      RELEASE(dataString);
    }

  if (task)
    {
      [handle waitForDataInBackgroundAndNotify];
    }
  else
    {
      [NOTIFICATION_CENTER removeObserver:self 
			   name: NSFileHandleDataAvailableNotification
			   object: handle];
    }
}

/**
 * Notified when the task is completed.
 */
- (void) taskDidTerminate: (NSNotification *)notif
{
  NSLog(@"Task Terminated...");
  [self logString: [self stopMessage]
	newLine:YES
        withColor:messageColor];
}

/**
 * Message to print when the task starts
 */
- (NSString *) startMessage
{
  return @"=== Task Started ===";
}

/**
 * Message to print when the task stops
 */
- (NSString *) stopMessage
{
  return @"\n=== Task Stopped ===";
}

/**
 * Start the program.
 */
- (void) runProgram: (NSString *)path
 inCurrentDirectory: (NSString *)directory
      withArguments: (NSArray *)array
   logStandardError: (BOOL)logError
{
  NSPipe *inPipe;
  NSPipe *outPipe;
  
  task = [[NSTask alloc] init];
  [task setArguments: array];
  [task setCurrentDirectoryPath: directory];
  [task setLaunchPath: path];

  inPipe = [NSPipe pipe];
  outPipe = [NSPipe pipe];
  stdinHandle = [[inPipe fileHandleForWriting] retain];
  stdoutHandle = [[outPipe fileHandleForReading] retain];
  [task setStandardOutput: outPipe];
  [task setStandardInput: inPipe];

  [stdoutHandle waitForDataInBackgroundAndNotify];

  // Log standard error, if requested.
  if(logError)
    {
      [task setStandardError: [NSPipe pipe]];
      error_handle = [[task standardError] fileHandleForReading];
      [error_handle waitForDataInBackgroundAndNotify];

      [NOTIFICATION_CENTER addObserver:self 
			      selector:@selector(logErrOut:)
				  name:NSFileHandleDataAvailableNotification
				object:error_handle];
    }

  // set up notifications to get data.
  [NOTIFICATION_CENTER addObserver:self 
			  selector:@selector(logStdOut:)
			      name:NSFileHandleDataAvailableNotification
			    object:stdoutHandle];


  [NOTIFICATION_CENTER addObserver:self 
			  selector:@selector(taskDidTerminate:) 
			      name:NSTaskDidTerminateNotification
			    object:task];

  // run the task...
  NS_DURING
    {
      [self logString: [self startMessage]
	      newLine:YES
            withColor:messageColor];
      [task launch];
    }
  NS_HANDLER
    {
      NSRunAlertPanel(@"Problem Launching Debugger",
		      [localException reason],
		      @"OK", nil, nil, nil);
	      
	      
      NSLog(@"Task Terminated Unexpectedly...");
      [self logString: @"\n=== Task Terminated Unexpectedly ===\n" 
	      newLine:NO
            withColor:messageColor];      
	      
      //Clean up after task is terminated
      [[NSNotificationCenter defaultCenter] 
		postNotificationName: NSTaskDidTerminateNotification
			      object: task];
    }
  NS_ENDHANDLER

}

- (void) terminate
{
  if(task)
    {
      [task terminate];
    }
}

- (void) dealloc
{
  [NOTIFICATION_CENTER removeObserver: self]; 
  [self terminate];
  [userInputColor release];
  [debuggerColor release];
  [messageColor release];
  [errorColor release];
  [tView release];
  [super dealloc];
}

- (void) putString: (NSString *)string;
{
  unichar *str = (unichar *)[string cStringUsingEncoding: [NSString defaultCStringEncoding]];
  int len = strlen((char *)str);
  NSData *data = [NSData dataWithBytes: str length: len];
  [stdinHandle writeData: data];
  [stdinHandle synchronizeFile];
}

/* for input as typed from the user */
- (void) typeString: (NSString *)string
{
  NSUInteger strLen;

  strLen = [string length];
  [self putString:string];

  // if we have a single backspace or delete character
  if (strLen == 1 && [string characterAtIndex:strLen-1] == '\177')
    {
      NSUInteger textLen;

      textLen = [[tView string] length];
      [tView setSelectedRange:NSMakeRange(textLen-1, 1)];
      [tView delete:nil];
      return;
    }
  
  [self logString:string newLine:NO withColor:userInputColor];
}

/**
 * Put a single character into the stream.
 */
- (void) putChar:(unichar)ch
{
  NSData *data = [NSData dataWithBytes: &ch length: 1];
  [stdinHandle writeData: data];
} 

- (void) interrupt
{
  [task interrupt];
}

/** 
 * Respond to key events and pipe them down to the debugger 
 */ 
- (void) keyDown: (NSEvent*)theEvent
{
    NSString *chars;

    chars = [theEvent characters];
    if ([chars length] == 0)
      {
      }
    else if ([chars length] == 1)
      {
        unichar c;
        c = [chars characterAtIndex: 0];
        //NSLog(@"char: %d", c);

	if (c == 3) // ETX, Control-C
	  {
	    [self interrupt];  // send the interrupt signal to the subtask
	  }
        else if (c == 13) // CR
          {
            [self typeString: @"\n"];
          }
	else if (c == 127) // del (usually backspace)
          {
	    NSString *tss = [[tView textStorage] string];
	    if (![tss hasSuffix:@"\n"] && ![tss hasSuffix:@"(gdb) "])
	      {
		[self typeString: chars];
	      }
          }
	else
	  {
	    [self typeString: chars];
	  }
      }
    else
      NSLog(@"characters: |%@|", chars);
}
@end
