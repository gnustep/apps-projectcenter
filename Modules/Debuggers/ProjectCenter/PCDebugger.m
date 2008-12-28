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

static NSImage	*goImage = nil;
static NSImage	*pauseImage = nil;
static NSImage	*restartImage = nil;
static NSImage	*nextImage = nil;
static NSImage  *stepInImage = nil;
static NSImage  *stepOutImage = nil;

@implementation PCDebugger
+ (void) initialize
{
  if (self == [PCDebugger class])
    {
      NSBundle	*bundle;
      NSString	*path;

      bundle = [NSBundle bundleForClass: self];
      path = [bundle pathForImageResource: @"go_button"];
      if (path != nil)
	{
	  goImage = [[NSImage alloc] initWithContentsOfFile: path];
	}
      path = [bundle pathForImageResource: @"pause_button"];
      if (path != nil)
	{
	  pauseImage = [[NSImage alloc] initWithContentsOfFile: path];
	}
      path = [bundle pathForImageResource: @"restart_button"];
      if (path != nil)
	{
	  restartImage = [[NSImage alloc] initWithContentsOfFile: path];
	}
      path = [bundle pathForImageResource: @"next_button"];
      if (path != nil)
	{
	  nextImage = [[NSImage alloc] initWithContentsOfFile: path];
	}
      path = [bundle pathForImageResource: @"stepin_button"];
      if (path != nil)
	{
	  stepInImage = [[NSImage alloc] initWithContentsOfFile: path];
	}
      path = [bundle pathForImageResource: @"stepout_button"];
      if (path != nil)
	{
	  stepOutImage = [[NSImage alloc] initWithContentsOfFile: path];
	}
    }
}

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
		withArguments: [[NSArray alloc] initWithObjects: @"-f", @"--args", path, nil]
		logStandardError: YES];
}   

- (void) awakeFromNib
{
  NSToolbar *toolbar = [(NSToolbar *)[NSToolbar alloc] initWithIdentifier: @"PCDebuggerToolbar"];
  [toolbar setAllowsUserCustomization: NO];
  [toolbar setDelegate: self];
  [debuggerWindow setToolbar: toolbar];
  RELEASE(toolbar);

  [toolbar setUsesStandardBackgroundColor: YES];
  [debuggerView setFont: [NSFont userFixedPitchFontOfSize: 0]];
  [debuggerWindow setFrameAutosaveName: @"PCDebuggerWindow"];
  [self setStatus: @"Idle."];
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

// action methods for toolbar...
- (void) go: (id) sender
{
  [self setStatus: @"Running..."];
  [debuggerView putString: @"run\n"];
}

- (void) pause: (id) sender
{
  [self setStatus: @"Stopped."];
  [debuggerView interrupt];
}

- (void) restart: (id) sender
{
  [self setStatus: @"Restarting..."];
  [debuggerView interrupt];
  [debuggerView putString: @"run\n"];
  [self setStatus: @"Running..."];
}

- (void) next: (id) sender
{
  [self setStatus: @"Going to next line."];
  [debuggerView putString: @"next\n"];
}

- (void) stepInto: (id) sender
{
  [self setStatus: @"Stepping into method."];
  [debuggerView putString: @"step\n"];  
}

- (void) stepOut: (id) sender
{
  [self setStatus: @"Finishing method."];
  [debuggerView putString: @"finish\n"];  
}

// Status..
- (void) setStatus: (NSString *) status
{
  [statusField setStringValue: status];
}

- (NSString *) status
{
  return [statusField stringValue];
}
@end

@implementation PCDebugger (NSToolbarDelegate)

- (NSToolbarItem*)toolbar: (NSToolbar*)toolbar
    itemForItemIdentifier: (NSString*)itemIdentifier
willBeInsertedIntoToolbar: (BOOL)flag
{
  NSToolbarItem *toolbarItem = AUTORELEASE([[NSToolbarItem alloc]
					     initWithItemIdentifier: itemIdentifier]);

  if([itemIdentifier isEqual: @"GoItem"])
    {
      [toolbarItem setLabel: @"Go"];
      [toolbarItem setImage: goImage];
      [toolbarItem setTarget: self];
      [toolbarItem setAction: @selector(go:)];     
      [toolbarItem setTag: 0];
    }
  else if([itemIdentifier isEqual: @"PauseItem"])
    {
      [toolbarItem setLabel: @"Pause"];
      [toolbarItem setImage: pauseImage];
      [toolbarItem setTarget: self];
      [toolbarItem setAction: @selector(pause:)];     
      [toolbarItem setTag: 1];
    }
  else if([itemIdentifier isEqual: @"RestartItem"])
    {
      [toolbarItem setLabel: @"Restart"];
      [toolbarItem setImage: restartImage];
      [toolbarItem setTarget: self];
      [toolbarItem setAction: @selector(restart:)];     
      [toolbarItem setTag: 1];
    }
  else if([itemIdentifier isEqual: @"NextItem"])
    {
      [toolbarItem setLabel: @"Next"];
      [toolbarItem setImage: nextImage];
      [toolbarItem setTarget: self];
      [toolbarItem setAction: @selector(next:)];     
      [toolbarItem setTag: 2];
    }
  else if([itemIdentifier isEqual: @"StepIntoItem"])
    {
      [toolbarItem setLabel: @"Step Into"];
      [toolbarItem setImage: stepInImage];
      [toolbarItem setTarget: self];
      [toolbarItem setAction: @selector(stepInto:)];     
      [toolbarItem setTag: 3];
    }
  else if([itemIdentifier isEqual: @"StepOutItem"])
    {
      [toolbarItem setLabel: @"Step Out"];
      [toolbarItem setImage: stepOutImage];
      [toolbarItem setTarget: self];
      [toolbarItem setAction: @selector(stepOut:)];     
      [toolbarItem setTag: 4];
    }

  return toolbarItem;
}

- (NSArray*) toolbarAllowedItemIdentifiers: (NSToolbar*)toolbar
{
  return [NSArray arrayWithObjects: @"GoItem", 
		  @"PauseItem", 
		  @"RestartItem", 
		  @"NextItem", 
		  @"StepIntoItem", 
		  @"StepOutItem", 
		  nil];
}

- (NSArray*) toolbarDefaultItemIdentifiers: (NSToolbar*)toolbar
{ 
  return [NSArray arrayWithObjects: @"GoItem", 
		  @"PauseItem", 
		  @"RestartItem", 
		  @"NextItem", 
		  @"StepIntoItem", 
		  @"StepOutItem", 
		  nil];
}

- (NSArray*) toolbarSelectableItemIdentifiers: (NSToolbar*)toolbar
{ 
  return [NSArray arrayWithObjects: @"GoItem", 
		  @"PauseItem", 
		  @"RestartItem", 
		  @"NextItem", 
		  @"StepIntoItem", 
		  @"StepOutItem", 
		  nil];
}
@end
