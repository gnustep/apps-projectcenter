/*
**  PCDebugger
**
**  Copyright (c) 2008-2016
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

#import <stdio.h>

#import <AppKit/AppKit.h>
#import <Foundation/Foundation.h>

#import <Protocols/CodeDebugger.h>

extern const NSString *PCBreakTypeKey;
extern NSString *PCBreakTypeByLine;
extern NSString *PCBreakTypeMethod;

extern const NSString *PCBreakMethod;
extern const NSString *PCBreakFilename;
extern const NSString *PCBreakLineNumber;
extern NSString *PCDBDebuggerStartedNotification;

@interface PCDebugger : NSObject <CodeDebugger>
{
  id             debuggerView;
  id             debuggerWindow;
  id             statusField;
  NSString       *executablePath;
  NSString       *debuggerPath;
  int            subProcessId;
  float          gdbVersion;
  NSMutableArray *breakpoints;
}

- (void) setStatus: (NSString *) status;
- (NSString *) status;
- (NSString *)executablePath;
- (void)setExecutablePath:(NSString *)p;
- (void) interrupt;
- (int) subProcessId;
- (void) setSubProcessId:(int)pid;
- (float) gdbVersion;
- (void) setGdbVersion:(float)ver;

@end
