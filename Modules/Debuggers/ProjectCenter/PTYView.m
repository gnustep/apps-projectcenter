/*
**  PTYView
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

#if defined (__FreeBSD__)
#include <sys/ioctl.h>
#include <termios.h>
#include <libutil.h>
#elif defined (__OpenBSD__)
#include <termios.h>
#include <util.h>
#else
#include <sys/termios.h>
#endif

#include <unistd.h>
#include <stdlib.h>
#include <string.h>

#import "PTYView.h"

#ifndef NOTIFICATION_CENTER
#define NOTIFICATION_CENTER [NSNotificationCenter defaultCenter]
#endif


@implementation PTYView

/**
 * Log string to the view.
 */
- (void) logString:(NSString *)str
	   newLine:(BOOL)newLine
{
  NSRange range;

  [self replaceCharactersInRange:
    NSMakeRange([[self string] length],0) withString:str];

  if (newLine)
    {
      [self replaceCharactersInRange:
	NSMakeRange([[self string] length], 0) withString:@"\n"];
    }
  
  //
  // Is it backspace?  If so, remove one character from the terminal to reflect
  // the deletion.   For some reason backspace sends multiple characters, so I have to remove
  // one more character than what is sent in order to appropriately delete from the buffer.
  //
  range = [str rangeOfString: @"\b"];
  if (range.location != NSNotFound)
    {
      NSString *newString = [[self string] substringToIndex: [[self string] length] - 4];
      [self setString: newString];
    }

  [self scrollRangeToVisible:NSMakeRange([[self string] length], 0)];
  [self setNeedsDisplay:YES];
}

/**
 * Log data.
 */
- (void) logData:(NSData *)data
{
  NSString *dataString;
  dataString = [[NSString alloc] 
		 initWithData:data 
		 encoding:[NSString defaultCStringEncoding]];
  [self logString: dataString newLine: NO];
  RELEASE(dataString);
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
      [self logData: data];
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
      // [self logString: @"\n" newLine: NO];
      [self logData: data];
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
	newLine:YES];
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
	      newLine:YES];
      [task launch];
    }
  NS_HANDLER
    {
      NSRunAlertPanel(@"Problem Launching Debugger",
		      [localException reason],
		      @"OK", nil, nil, nil);
	      
	      
      NSLog(@"Task Terminated Unexpectedly...");
      [self logString: @"\n=== Task Terminated Unexpectedly ===\n" 
	      newLine:YES];      
	      
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
    if ([chars length] == 1)
    {
        unichar c;
        c = [chars characterAtIndex: 0];

	if (c == 3) // ETX, Control-C
	  {
	    [self interrupt];  // send the interrupt signal to the subtask
	  }
	else
	  {
	    [self putChar: c];
	  }
    }    
}
@end
