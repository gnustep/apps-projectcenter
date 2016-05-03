/*
**  PCDebuggerView
**
**  Copyright (c) 2008-2016
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

#import "PCDebuggerView.h"
#import "PCDebugger.h"

#import <ProjectCenter/PCProject.h>
#import <Foundation/NSScanner.h>

#import <unistd.h>
#import <signal.h>

#ifndef NOTIFICATION_CENTER
#define NOTIFICATION_CENTER [NSNotificationCenter defaultCenter]
#endif

@implementation PCDebuggerView

-(void)setDebugger:(PCDebugger *)theDebugger
{
  debugger = theDebugger;
}

- (void) setDelegate:(id <PCDebuggerViewDelegateProtocol>) vd
{
  if (viewDelegate != vd)
    {
      [viewDelegate release];
      viewDelegate = vd;
      [viewDelegate retain];
    }
}


/**
 * Log string to the view.
 */
- (void) logString:(NSString *)str
	   newLine:(BOOL)newLine
{
  NSRange range;
  BOOL printLine = YES;

  range = [str rangeOfString: @"\032\032"]; // Breakpoint"];
  if (range.location != NSNotFound)
    {
      NSScanner *scanner = [NSScanner scannerWithString: str];      
      NSCharacterSet *empty = [NSCharacterSet characterSetWithCharactersInString: @""];
      NSString *file = nil;
      NSString *line = nil;
      NSString *bytes = nil;
      int l = 0, b = 0;
      
      [scanner setCharactersToBeSkipped: empty];
      [scanner scanUpToString: @"\032\032" intoString: NULL];
      [scanner scanString: @"\032\032" intoString: NULL];
      [scanner scanUpToString: @":" intoString: &file];
      [scanner scanString: @":" intoString: NULL];
      [scanner scanUpToString: @":" intoString: &line];
      if (line != nil)
	{
	  l = [line intValue];
	  [scanner scanString: @":" intoString: NULL];
	  [scanner scanUpToString: @":" intoString: &bytes];

	  if (bytes != nil)
	    {
	      b = [bytes intValue];     
	      if (l != 0 && b != 0) // if the line & bytes are parsable, then send the notification.
		{
		  NSDictionary *dict = [NSDictionary 
					 dictionaryWithObjectsAndKeys:
					   file, @"file", line, @"line", nil];
		  NSString *statusString = [NSString stringWithFormat: @"Stopped, %@:%@",file,line];

		  [debugger setStatus: statusString];
		  [NOTIFICATION_CENTER 
		    postNotificationName: PCProjectBreakpointNotification
		    object: dict];
		  [[self window] makeKeyAndOrderFront: self];
		  printLine = NO;
		}
	    }
	}
    }

  // Check certain status messages from GDB and set the state correctly.
  range = [str rangeOfString: @"Starting program:"];
  if (range.location != NSNotFound)
    {
      [debugger setStatus: @"Running..."];
    }

  // Check certain status messages from GDB and set the state correctly.
  range = [str rangeOfString: @"Program received signal"];
  if (range.location != NSNotFound)
    {
      [debugger setStatus: @"Stopped"];
    }

  // Check certain status messages from GDB and set the state correctly.
  range = [str rangeOfString: @"Terminated"];
  if (range.location != NSNotFound)
    {
      [debugger setStatus: @"Terminated"];
    }

  // Check certain status messages from GDB and set the state correctly.
  range = [str rangeOfString: @"Program exited"];
  if (range.location != NSNotFound)
    {
      [debugger setStatus: @"Terminated"];
    }

  // FIXME: Filter this error, until we find a better way to deal with it.
  range = [str rangeOfString: @"[tcsetpgrp failed in terminal_inferior:"];
  if (range.location != NSNotFound)
    {
      printLine = NO;
    }

  // if the line is not filtered, print it...
  if(printLine)
    {
      [viewDelegate logString: str newLine: newLine withColor:[viewDelegate debuggerColor]];
    }
}

- (void) setCurrentFile: (NSString *)fileName
{
  ASSIGN(currentFile,fileName);
}

- (NSString *) currentFile
{
  return currentFile;
}


- (void) terminate
{
  [viewDelegate terminate];
}

- (void) mouseDown: (NSEvent *)event
{
  // do nothing...
}

/**
 * Start the program.
 */
- (void) runProgram: (NSString *)path
 inCurrentDirectory: (NSString *)directory
      withArguments: (NSArray *)array
   logStandardError: (BOOL)logError
{
  [viewDelegate runProgram: path
        inCurrentDirectory: directory
             withArguments: array
          logStandardError: logError];
}

- (void) putString: (NSString *)string
{
  [viewDelegate putString:string];
}

- (void) keyDown: (NSEvent*)theEvent
{
  [viewDelegate keyDown:theEvent];
}

@end
