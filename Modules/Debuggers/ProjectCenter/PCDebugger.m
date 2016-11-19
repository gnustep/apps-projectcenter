/*
**  PCDebugger.m
**
**  Copyright (c) 2008-2016
**
**  Author: Gregory Casamento <greg.casamento@gmail.com>
**          Riccardo Mottola <rm@gnu.org>>
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

#ifdef	__MINGW32__
#undef _WIN32_WINNT
#define _WIN32_WINNT 0x0501 // Minimal target is Windows XP

#include <windows.h>

#endif

#import <AppKit/AppKit.h>
#import "PCDebugger.h"
#import "PCDebuggerView.h"

#import "Modules/Preferences/EditorFSC/PCEditorFSCPrefs.h"
#import "PCDebuggerViewDelegateProtocol.h"
#import "PipeDelegate.h"



#ifndef NOTIFICATION_CENTER
#define NOTIFICATION_CENTER [NSNotificationCenter defaultCenter]
#endif

static NSImage	*goImage = nil;
static NSImage	*pauseImage = nil;
static NSImage	*continueImage = nil;
static NSImage	*restartImage = nil;
static NSImage	*nextImage = nil;
static NSImage  *stepInImage = nil;
static NSImage  *stepOutImage = nil;
static NSImage  *upImage = nil;
static NSImage  *downImage = nil;

const NSString *PCBreakTypeKey = @"BreakType";
NSString *PCBreakTypeByLine = @"BreakTypeLine";
NSString *PCBreakTypeMethod = @"BreakTypeMethod";
const NSString *PCBreakMethod = @"BreakMethod";
const NSString *PCBreakFilename = @"BreakFilename";
const NSString *PCBreakLineNumber = @"BreakLineNumber";
NSString *PCDBDebuggerStartedNotification = @"PCDBDebuggerStartedNotification";

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
      path = [bundle pathForImageResource: @"continue_button"];
      if (path != nil)
	{
	  continueImage = [[NSImage alloc] initWithContentsOfFile: path];
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
      path = [bundle pathForImageResource: @"up_button"];
      if (path != nil)
	{
	  upImage = [[NSImage alloc] initWithContentsOfFile: path];
	}
      path = [bundle pathForImageResource: @"down_button"];
      if (path != nil)
	{
	  downImage = [[NSImage alloc] initWithContentsOfFile: path];
	}
    }
}

+ (NSFont *)defaultConsoleFont
{
  NSUserDefaults *df = [NSUserDefaults standardUserDefaults];
  NSString       *fontName;
  float          fontSize;
  NSFont         *font = nil;

  fontName = [df objectForKey:ConsoleFixedFont];
  fontSize = [df floatForKey:ConsoleFixedFontSize];

  if (fontName != nil && fontSize > 0)
    {
      font = [NSFont fontWithName:fontName size:fontSize];
    }
  if (font == nil)
    {
      font = [NSFont userFixedPitchFontOfSize:0];
    }

  return font;
}

- (id) init
{
  if((self = [super init]) != nil)
    {
      id <PCDebuggerViewDelegateProtocol> viewDelegate;
      // initialization here...
      if([NSBundle loadNibNamed: @"PCDebugger" owner: self] == NO)
	{
	  return nil;
	}

      [(PCDebuggerView *)debuggerView setDebugger:self];
      viewDelegate = [[PipeDelegate alloc] init];
      [debuggerView setDelegate:viewDelegate];
      [viewDelegate setTextView:debuggerView];
      [viewDelegate setDebugger:self];
      [viewDelegate release];

      subProcessId = 0;
      gdbVersion = 0.0;

      breakpoints = nil;

      [[NSNotificationCenter defaultCenter] addObserver: self
       selector: @selector(handleNotification:)
       name: PCDBDebuggerStartedNotification
       object: nil];
    }
  return self;
}

-(void) debugExecutableAtPath: (NSString *)filePath
		 withDebugger: (NSString *)debugger
{
  ASSIGN(executablePath,filePath);
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
		inCurrentDirectory: [executablePath stringByDeletingLastPathComponent]
                withArguments: [[NSArray alloc] initWithObjects: @"--interpreter=mi", @"-f", executablePath, nil]
		logStandardError: YES];
  
}

- (void) initBreakpoints
{
  id <PCDebuggerViewDelegateProtocol> viewDelegate;

  breakpoints = [[NSMutableArray alloc] init];
  NSDictionary *dP;
  NSLog(@"initing breakpoints");

  /* CRUDE EXAMPLES * TODO FIXME *
  dP = [NSDictionary dictionaryWithObjectsAndKeys: PCBreakTypeMethod, PCBreakTypeKey, @"[NSException raise]", PCBreakMethod, nil];
  //  [breakpoints addObject:dP];
  dP = [NSDictionary dictionaryWithObjectsAndKeys: PCBreakTypeByLine, PCBreakTypeKey, @"AppController.m", PCBreakFilename, [NSNumber numberWithInt:100], PCBreakLineNumber, nil];
  [breakpoints addObject:dP];
  */ 

  viewDelegate = [debuggerView delegate];
  [viewDelegate setBreakpoints:breakpoints];
}

- (void) debuggerSetup
{
  id <PCDebuggerViewDelegateProtocol> viewDelegate;
  viewDelegate = [debuggerView delegate];
  [viewDelegate debuggerSetup];
}

- (void) handleNotification: (NSNotification *)notification
{
  [self initBreakpoints];
  [self debuggerSetup];
}


- (void) awakeFromNib
{
  NSToolbar *toolbar = [(NSToolbar *)[NSToolbar alloc] initWithIdentifier: @"PCDebuggerToolbar"];
  [toolbar setAllowsUserCustomization: NO];
  [toolbar setDelegate: self];
  [debuggerWindow setToolbar: toolbar];
  RELEASE(toolbar);

  [debuggerView setFont: [PCDebugger defaultConsoleFont]];
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

- (NSString *)executablePath
{
  return executablePath;
}

- (void)setExecutablePath:(NSString *)p
{
  ASSIGN(executablePath,p);
}

- (int) subProcessId
{
  return subProcessId;
}

- (void) setSubProcessId: (int)pid
{
  subProcessId = pid;
}

- (float) gdbVersion
{
  return gdbVersion;
}

- (void) setGdbVersion:(float)ver
{
  gdbVersion = ver;
}

// kill process
- (void) interrupt
{
  if(subProcessId != 0)
    {
#ifndef	__MINGW32__
      kill(subProcessId,SIGINT);
#else
      HANDLE proc;

      proc = OpenProcess(PROCESS_ALL_ACCESS, FALSE, (DWORD)subProcessId);
      if (proc == NULL)
        {
          DWORD lastError = GetLastError();
          NSLog(@"error opening process %lu", (unsigned long)lastError);
          return;
        }
      if (DebugBreakProcess(proc))
        {
          DWORD lastError = GetLastError();
          NSLog(@"error sending break %lu", (unsigned long)lastError);
        }
      else
        {
          NSLog(@"break sent successfully");
        }
      CloseHandle(proc);
#endif
    }
}

// action methods for toolbar...
- (void) go: (id) sender
{
  /* each run makes a new PID but we parse it only if non-zero */
  [self setSubProcessId:0];
  [debuggerView putString: @"run\n"];
}

- (void) pause: (id) sender
{
  [self setStatus: @"Stopped."];
  [self interrupt];
}

- (void) continue: (id) sender
{
  // [self setStatus: @"Continue..."];
  [debuggerView putString: @"continue\n"];
}

- (void) restart: (id) sender
{
  // [self setStatus: @"Restarting..."];
  [self interrupt];
  /* each run makes a new PID but we parse it only if non-zero */
  [self setSubProcessId:0];
  [debuggerView putString: @"run\n"];
  // [self setStatus: @"Running..."];
}

- (void) next: (id) sender
{
  // [self setStatus: @"Going to next line."];
  [debuggerView putString: @"next\n"];
}

- (void) stepInto: (id) sender
{
  // [self setStatus: @"Stepping into method."];
  [debuggerView putString: @"step\n"];  
}

- (void) stepOut: (id) sender
{
  // [self setStatus: @"Finishing method."];
  [debuggerView putString: @"finish\n"];  
}

- (void) up: (id) sender
{
  // [self setStatus: @"Up to calling method."];
  [debuggerView putString: @"up\n"];  
}

- (void) down: (id) sender
{
  // [self setStatus: @"Down to called method."];
  [debuggerView putString: @"down\n"];  
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

- (void) dealloc
{
  [breakpoints release];
  [super dealloc];
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
  else if([itemIdentifier isEqual: @"ContinueItem"])
    {
      [toolbarItem setLabel: @"Continue"];
      [toolbarItem setImage: continueImage];
      [toolbarItem setTarget: self];
      [toolbarItem setAction: @selector(continue:)];     
      [toolbarItem setTag: 1];
    }
  else if([itemIdentifier isEqual: @"RestartItem"])
    {
      [toolbarItem setLabel: @"Restart"];
      [toolbarItem setImage: restartImage];
      [toolbarItem setTarget: self];
      [toolbarItem setAction: @selector(restart:)];     
      [toolbarItem setTag: 2];
    }
  else if([itemIdentifier isEqual: @"NextItem"])
    {
      [toolbarItem setLabel: @"Next"];
      [toolbarItem setImage: nextImage];
      [toolbarItem setTarget: self];
      [toolbarItem setAction: @selector(next:)];     
      [toolbarItem setTag: 3];
    }
  else if([itemIdentifier isEqual: @"StepIntoItem"])
    {
      [toolbarItem setLabel: @"Step Into"];
      [toolbarItem setImage: stepInImage];
      [toolbarItem setTarget: self];
      [toolbarItem setAction: @selector(stepInto:)];     
      [toolbarItem setTag: 4];
    }
  else if([itemIdentifier isEqual: @"StepOutItem"])
    {
      [toolbarItem setLabel: @"Step Out"];
      [toolbarItem setImage: stepOutImage];
      [toolbarItem setTarget: self];
      [toolbarItem setAction: @selector(stepOut:)];     
      [toolbarItem setTag: 5];
    }
  else if([itemIdentifier isEqual: @"UpItem"])
    {
      [toolbarItem setLabel: @"Up"];
      [toolbarItem setImage: upImage];
      [toolbarItem setTarget: self];
      [toolbarItem setAction: @selector(up:)];     
      [toolbarItem setTag: 6];
    }
  else if([itemIdentifier isEqual: @"DownItem"])
    {
      [toolbarItem setLabel: @"Down"];
      [toolbarItem setImage: downImage];
      [toolbarItem setTarget: self];
      [toolbarItem setAction: @selector(down:)];     
      [toolbarItem setTag: 7];
    }

  return toolbarItem;
}

- (NSArray*) toolbarAllowedItemIdentifiers: (NSToolbar*)toolbar
{
  return [NSArray arrayWithObjects: @"GoItem", 
		  @"PauseItem", 
		  @"ContinueItem", 
		  @"RestartItem", 
		  @"NextItem", 
		  @"StepIntoItem", 
		  @"StepOutItem", 
		  @"UpItem", 
		  @"DownItem", 
		  nil];
}

- (NSArray*) toolbarDefaultItemIdentifiers: (NSToolbar*)toolbar
{ 
  return [NSArray arrayWithObjects: @"GoItem", 
		  @"PauseItem", 
		  @"ContinueItem", 
		  @"RestartItem", 
		  @"NextItem", 
		  @"StepIntoItem", 
		  @"StepOutItem", 
		  @"UpItem", 
		  @"DownItem", 
		  nil];
}

- (NSArray*) toolbarSelectableItemIdentifiers: (NSToolbar*)toolbar
{ 
  return [NSArray arrayWithObjects: @"GoItem", 
		  @"PauseItem", 
		  @"ContinueItem", 
		  @"RestartItem", 
		  @"NextItem", 
		  @"StepIntoItem", 
		  @"StepOutItem", 
		  @"UpItem", 
		  @"DownItem", 
		  nil];
}
@end
