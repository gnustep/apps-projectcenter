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

- (id <PCDebuggerViewDelegateProtocol>)delegate
{
  return viewDelegate;
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
  [viewDelegate logString: str newLine: newLine withColor:[viewDelegate debuggerColor]];
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
  NSAttributedString* attr = [[NSAttributedString alloc] initWithString:string];
  [[self textStorage] appendAttributedString:attr];
  [self scrollRangeToVisible:NSMakeRange([[self string] length], 0)];
  [viewDelegate putString:string];
}

- (void) keyDown: (NSEvent*)theEvent
{
  [viewDelegate keyDown:theEvent];
}

@end
