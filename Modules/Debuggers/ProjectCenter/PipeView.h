/*
**  PipeDelegate
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

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>

#import "PCDebuggerViewDelegateProtocol.h"

@interface PipeDelegate : NSObject <PCDebuggerViewDelegateProtocol>
{
  NSTextView *tView;
  NSTask *task;
  NSFileHandle *stdinHandle;
  NSFileHandle *stdoutHandle;
  NSFileHandle *error_handle;

  NSColor *userInputColor;
  NSColor *debuggerColor;
  NSColor *messageColor;
  NSColor *errorColor;
}

- (void)logStdOut:(NSNotification *)aNotif;

- (void)logErrOut:(NSNotification *)aNotif;

- (void) taskDidTerminate: (NSNotification *)notif;

- (NSString *) startMessage;

- (NSString *) stopMessage;

- (void) putChar:(unichar)ch;

@end
