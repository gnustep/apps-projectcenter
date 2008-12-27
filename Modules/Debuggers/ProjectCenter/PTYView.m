/*
**  PTYView
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

#include <PTYView.h>

#include <fcntl.h>
#include <sys/stat.h>
#include <unistd.h>

#ifndef NOTIFICATION_CENTER
#define NOTIFICATION_CENTER [NSNotificationCenter defaultCenter]
#endif

@implementation PTYView
/**
 * Instantiate this view.
 */
- (id) initWithCoder: (NSCoder *)coder
{
  self = [super initWithCoder: coder];
  if(self != nil)
    {
      // initialize the pty name field.
      strcpy(pty_name, "/dev/ptyXY");    
    }
  return self;
}

/**
 * Creates master device. 
 */
- (int) master
{
  struct stat buff;
  static char hex[] = "0123456789abcdef"; 
  static char pty[] = "pqrs";
  int i, fd;
  char *p;

  for (p = pty; *p != 0; p++) 
    {
      pty_name[8] = *p; 
      pty_name[9] = '0'; 
      
      if (stat(pty_name, &buff) < 0)
	{
	  break;
	}

      for (i = 0; i < 16; i++) 
	{
	  pty_name[9] = hex[i]; 
	  if ((fd = open(pty_name, O_RDWR)) >= 0) 
	    {
	      return(fd); 
	    }
	}
    }

  return(-1); 
}

/**
 * Open the slave half of a pseudo-terminal.
 */
- (int) slave:(int)master_fd
{
  int fd;
  
  // change to t, for slave tty.
  pty_name[5] = 't'; 
  if ((fd = open(pty_name, O_RDWR)) < 0) 
    {
      close(master_fd);
      return(-1);
    }
  return(fd);
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
  // the deletion.   For some reason backspace sends "\b \b", so I have to remove
  // four characters in order to appropriately delete from the buffer.
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
  int master_fd, slave_fd;

  task = [[NSTask alloc] init];
  [task setArguments: array];
  [task setCurrentDirectoryPath: directory];
  [task setLaunchPath: path];

  master_fd = [self master];
  if(master_fd > 0)
    {
      slave_fd = [self slave: master_fd];
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
	    [task interrupt];  // send the interrupt signal to the subtask
	  }
	else
	  {
	    [self putChar: c];
	  }
    }    
}
@end
