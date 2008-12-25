/*
**  PCDebugger
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

#include <AppKit/AppKit.h>
#include "PCDebugger.h"
#include "PCDebuggerView.h"

#ifndef NOTIFICATION_CENTER
#define NOTIFICATION_CENTER [NSNotificationCenter defaultCenter]
#endif

@implementation PCDebugger
- (id) init
{
  if((self = [super init]) != nil)
    {
      // initialization here...
      if([NSBundle loadNibNamed: @"PCDebugger" owner: self] == NO)
	{
	  return nil;
	}

      [(PCDebuggerView *)debuggerView setDebugger:self];
    }
  return self;
}

-(void) debugExecutableAtPath: (NSString *)filePath
		 withDebugger: (NSString *)debugger
{
  ASSIGN(path,filePath);
  ASSIGN(debuggerPath,debugger);
  [debuggerWindow setTitle: [NSString stringWithFormat: @"Debugger (%@)",filePath]];
  [self show];
}

- (void) show
{
  [debuggerWindow makeKeyAndOrderFront: self];
  [self startDebugger];
}

- (void) startDebugger
{
  [debuggerView runProgram: debuggerPath
		inCurrentDirectory: [path stringByDeletingLastPathComponent]
		withArguments: [[NSArray alloc] initWithObjects: @"--args", path, nil]
		logStandardError: YES];
}   

- (void) awakeFromNib
{
  [debuggerView setFont: [NSFont userFixedPitchFontOfSize: 0]];
  [debuggerWindow setFrameAutosaveName: @"PCDebuggerWindow"];
}

- (NSWindow *)debuggerWindow
{
  return debuggerWindow;
}

- (void)setDebuggerWindow: (NSWindow *)window
{
  debuggerWindow = window;
}

- (NSView *)debuggerView
{
  return debuggerView;
}

- (void)setDebuggerView: (id)view
{
  debuggerView = view;
}

- (NSString *)path
{
  return path;
}

- (void)setPath:(NSString *)p
{
  ASSIGN(path,p);
}
@end
