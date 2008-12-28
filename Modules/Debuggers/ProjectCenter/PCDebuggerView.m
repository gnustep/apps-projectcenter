/*
**  PCDebuggerView
**
**  Copyright (c) 2008
**
**  Author: Gregory Casamento <greg_casamento@yahoo.com>
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

#include "PCDebuggerView.h"
#include "PCDebugger.h"

#include <ProjectCenter/PCProject.h>
#include <Foundation/NSScanner.h>

#include <unistd.h>
#include <signal.h>

#ifndef NOTIFICATION_CENTER
#define NOTIFICATION_CENTER [NSNotificationCenter defaultCenter]
#endif

@implementation PCDebuggerView

-(void)setDebugger:(PCDebugger *)theDebugger
{
  debugger = theDebugger;
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

  // FIXME: Filter this error, until we find a better way to deal with it.
  range = [str rangeOfString: @"[tcsetpgrp failed in terminal_inferior:"];
  if (range.location != NSNotFound)
    {
      printLine = NO;
    }

  // if the line is not filtered, print it...
  if(printLine)
    {
      [super logString: str newLine: newLine];
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

/**
 * lookup the process id.
 */
/*
- (int) lookupProcessId
{
  int task_pid = [task processIdentifier];
  int child_pid = 0;
  NSArray *entries = [[NSFileManager defaultManager] directoryContentsAtPath: @"/proc"];
  NSEnumerator *en = [entries objectEnumerator];
  NSString *entry = nil;
  
  // FIXME: I'm looking for a generic way to do this, what we have here is very /proc specific.
  // which I don't like since it ties this functionality to systems which have /proc.
  while((entry = [en nextObject]) != nil)
    {
      int pid = [entry intValue];
      if (pid != 0)
	{
	  int ppid = getppid(pid);
	  if (ppid == task_pid)
	    {
	      child_pid = pid;
	      break;
	    }
	}
    }
  
  return child_pid;
}

- (void) interrupt
{
  int pid = [self lookupProcessId];
  kill(pid,SIGINT);
}
*/

- (void) terminate
{
  [super terminate];
  [debugger setStatus: @"Process ended."];
}
@end