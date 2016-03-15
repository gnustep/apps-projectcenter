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

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>

@interface PTYView : NSTextView
{
  NSTask *task;
  NSFileHandle *master_handle;
  NSFileHandle *slave_handle;
  NSFileHandle *error_handle;
  int master_fd, slave_fd;
}

- (int)openpty;

- (void)logString:(NSString *)str
          newLine:(BOOL)newLine;

- (void)logData:(NSData *)data;

- (void)logStdOut:(NSNotification *)aNotif;

- (void)logErrOut:(NSNotification *)aNotif;

- (void) taskDidTerminate: (NSNotification *)notif;

- (NSString *) startMessage;

- (NSString *) stopMessage;

- (void) runProgram: (NSString *)path
 inCurrentDirectory: (NSString *)directory
      withArguments: (NSArray *)array
   logStandardError: (BOOL)logError;

- (void) terminate;

- (void) interrupt;

- (void) putString: (NSString *)string;

- (void) putChar:(unichar)ch;
@end
