/*
**  PTYView
**
**  Copyright (c) 2008-2012 Free Software Foundation
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


#ifndef NOTIFICATION_CENTER
#define NOTIFICATION_CENTER [NSNotificationCenter defaultCenter]
#endif

/* check for solaris */
#if defined (__SVR4) && defined (__sun)
#define __SOLARIS__ 1
#define USE_FORKPTY_REPLACEMENT 1
#endif

#if defined(__SOLARIS__)
#include <stropts.h>
#endif


#if !(defined (__NetBSD__)) && !(defined (__SOLARIS__)) && !(defined (__OpenBSD__)) && !(defined(__FreeBSD__))
#  include <pty.h>
#endif

#import "PTYView.h"

#ifdef USE_FORKPTY_REPLACEMENT
int openpty(int *amaster, int *aslave, char *name, const struct termios *termp, const struct winsize *winp)
{
    int fdm, fds;
    char *slaveName;
    
    fdm = open("/dev/ptmx", O_RDWR); /* open master */
    if (fdm == -1)
    {
    	perror("openpty:open(master)");
	return -1;
    }
    if(grantpt(fdm))                    /* grant access to the slave */
    {
    	perror("openpty:grantpt(master)");
	close(fdm);
	return -1;
    }
    if(unlockpt(fdm))                /* unlock the slave terminal */
    {
    	perror("openpty:unlockpt(master)");
	close(fdm);
	return -1;
    }
    
    slaveName = ptsname(fdm);        /* get name of the slave */
    if (slaveName == NULL)
    {
    	perror("openpty:ptsname(master)");
	close(fdm);
	return -1;
    }
    if (name)                        /* of name ptr not null, copy it name back */
        strcpy(name, slaveName);
    
    fds = open(slaveName, O_RDWR | O_NOCTTY); /* open slave */
    if (fds == -1)
    {
    	perror("openpty:open(slave)");
	close (fdm);
	return -1;
    }
    
    /* ldterm and ttcompat are automatically pushed on the stack on some systems*/
#ifdef __SOLARIS__
    if (ioctl(fds, I_PUSH, "ptem") == -1) /* pseudo terminal module */
    {
    	perror("openpty:ioctl(I_PUSH, ptem");
	close(fdm);
	close(fds);
	return -1;
    }
    if (ioctl(fds, I_PUSH, "ldterm") == -1)  /* ldterm must stay atop ptem */
    {
	perror("forkpty:ioctl(I_PUSH, ldterm");
	close(fdm);
	close(fds);
	return -1;
    }
#endif
    
    /* set terminal parameters if present */
    // if (termp)
    //	ioctl(fds, TCSETS, termp);
    //if (winp)
    //    ioctl(fds, TIOCSWINSZ, winp);
    
    *amaster = fdm;
    *aslave = fds;
    return 0;
}
#endif

@implementation PTYView
/**
 * Creates master device. 
 */
- (int) openpty
{
  if (openpty(&master_fd, &slave_fd, NULL, NULL, NULL) == -1)
    {
      NSLog(@"Call to openpty(...) failed.");
    }
  return master_fd;
}

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
  NSFileHandle *handle = master_handle;

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
  task = [[NSTask alloc] init];
  [task setArguments: array];
  [task setCurrentDirectoryPath: directory];
  [task setLaunchPath: path];

  master_fd = [self openpty];
  if(master_fd > 0)
    {
      if(slave_fd > 0)
	{
	  slave_handle = [[NSFileHandle alloc] initWithFileDescriptor: slave_fd]; 
	  master_handle = [[NSFileHandle alloc] initWithFileDescriptor: master_fd];
	  [task setStandardOutput: slave_handle];
	  [task setStandardInput: slave_handle];

	  [master_handle waitForDataInBackgroundAndNotify];

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
			       object:master_handle];


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
    }
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
  [master_handle writeData: data];  
}

/**
 * Put a single character into the stream.
 */
- (void) putChar:(unichar)ch
{
  NSData *data = [NSData dataWithBytes: &ch length: 1];
  [master_handle writeData: data];
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
