/*
   GNUstep ProjectCenter - http://www.gnustep.org

   Copyright (C) 2000-2002 Free Software Foundation

   Author: Philippe C.D. Robert <probert@siggraph.org>

   This file is part of GNUstep.

   This application is free software; you can redistribute it and/or
   modify it under the terms of the GNU General Public
   License as published by the Free Software Foundation; either
   version 2 of the License, or (at your option) any later version.

   This application is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
   Library General Public License for more details.

   You should have received a copy of the GNU General Public
   License along with this library; if not, write to the Free
   Software Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111 USA.

   $Id$
*/

#include "PCProjectBuilder.h"
#include "PCDefines.h"
#include "PCProject.h"
#include "PCProject+ComponentHandling.h"
#include "PCProjectManager.h"
#include "PCSplitView.h"

#include <AppKit/AppKit.h>

#ifndef IMAGE
#define IMAGE(X) [NSImage imageNamed: X]
#endif

#ifndef NOTIFICATION_CENTER
#define NOTIFICATION_CENTER [NSNotificationCenter defaultCenter]
#endif

#define DEFAULT_RPM_ROOT @"/usr/src/redhat/"

@interface PCProjectBuilder (CreateUI)

- (void) _createBuildPanel;
- (void) _createComponentView;
- (void) _createOptionsPanel;

@end

@implementation PCProjectBuilder (CreateUI)

- (void) _createBuildPanel
{
  buildPanel = [[NSPanel alloc]
    initWithContentRect: NSMakeRect (0, 300, 480, 322)
              styleMask: (NSTitledWindowMask 
		          | NSClosableWindowMask
		          | NSResizableWindowMask)
                backing: NSBackingStoreRetained
                  defer: YES];
  [buildPanel setMinSize: NSMakeSize(440, 322)];
  [buildPanel setFrameAutosaveName: @"ProjectBuilder"];
  [buildPanel setReleasedWhenClosed: NO];
  [buildPanel setTitle: [NSString stringWithFormat: 
                         @"%@ - Project Build", [currentProject projectName]]];

  if (![buildPanel setFrameUsingName: @"ProjectBuilder"])
    {
      [buildPanel center];
    }
}

- (void) _createComponentView
{
  NSSplitView  *split;
  NSScrollView *scrollView1; 
  NSScrollView *scrollView2; 
  NSRect       _w_frame;
  NSButtonCell *buttonCell = [[[NSButtonCell alloc] init] autorelease];
  NSBox        *box;
  id           button;
  id           textField;
  BOOL         separateView;


  componentView = [[NSBox alloc] initWithFrame: NSMakeRect(8, -1, 464, 322)];
  [componentView setTitlePosition: NSNoTitle];
  [componentView setBorderType: NSNoBorder];
  [componentView setAutoresizingMask: NSViewWidthSizable 
                                    | NSViewHeightSizable];
  [componentView setContentViewMargins: NSMakeSize (0.0, 0.0)];

  /*
   * 4 build Buttons
   */
  _w_frame = NSMakeRect(0, 270, 176, 44);
  matrix = [[NSMatrix alloc] initWithFrame: _w_frame
                                      mode: NSHighlightModeMatrix
				 prototype: buttonCell
			      numberOfRows: 1
			   numberOfColumns: 4];
  [matrix sizeToCells];
  [matrix setSelectionByRect: YES];
  [matrix setAutoresizingMask: (NSViewMaxXMargin | NSViewMinYMargin)];
  [matrix setTarget: self];
  [matrix setAction: @selector (topButtonPressed:)];
  [componentView addSubview: matrix];

  button = [matrix cellAtRow: 0 column: 0];
  [button setTag: 0];
  [button setImagePosition: NSImageOnly];
  [button setFont: [NSFont systemFontOfSize: 10.0]];
  [button setImage: IMAGE(@"ProjectCenter_make")];
  [button setAlternateImage: IMAGE(@"Stop")];
  [button setButtonType: NSToggleButton];
  [button setTitle: @"Build"];

  button = [matrix cellAtRow: 0 column: 1];
  [button setTag: 1];
  [button setImagePosition: NSImageOnly];
  [button setFont: [NSFont systemFontOfSize: 10.0]];
  [button setImage: IMAGE(@"ProjectCenter_clean")];
  [button setAlternateImage: IMAGE(@"Stop")];
  [button setButtonType: NSToggleButton];
  [button setTitle: @"Clean"];

  button = [matrix cellAtRow: 0 column: 2];
  [button setTag: 2];
  [button setImagePosition: NSImageOnly];
  [button setFont: [NSFont systemFontOfSize: 10.0]];
  [button setImage: IMAGE(@"ProjectCenter_install")];
  [button setAlternateImage: IMAGE(@"Stop")];
  [button setButtonType: NSToggleButton];
  [button setTitle: @"Install"];
  
  button = [matrix cellAtRow: 0 column: 3];
  [button setTag: 3];
  [button setImagePosition: NSImageOnly];
  [button setFont: [NSFont systemFontOfSize: 10.0]];
  [button setImage: IMAGE(@"ProjectCenter_prefs")];
  [button setAlternateImage: IMAGE(@"Stop")];
  [button setButtonType: NSToggleButton];
  [button setTitle: @"Options"];

  /*
   *  Error and Log output
   */
  scrollView1 = [[NSScrollView alloc] 
    initWithFrame:NSMakeRect (0, 0, 464, 120)];

  [scrollView1 setHasHorizontalScroller:NO];
  [scrollView1 setHasVerticalScroller:YES];
  [scrollView1 setBorderType: NSBezelBorder];
  [scrollView1 setAutoresizingMask:(NSViewWidthSizable | NSViewHeightSizable)];

  errorOutput = [[NSTextView alloc] 
    initWithFrame: [[scrollView1 contentView] frame]];

  [errorOutput setRichText: NO];
  [errorOutput setEditable: NO];
  [errorOutput setSelectable: YES];
  [errorOutput setAutoresizingMask: NSViewWidthSizable | NSViewHeightSizable];
  [errorOutput setBackgroundColor: [NSColor colorWithDeviceRed: 0.88
                                                         green: 0.76 
                                                          blue: 0.60 
                                                         alpha: 1.0]];
  [errorOutput setHorizontallyResizable: NO]; 
  [errorOutput setVerticallyResizable: YES];
  [errorOutput setMinSize: NSMakeSize (0, 0)];
  [errorOutput setMaxSize: NSMakeSize (1E7, 1E7)];
  [[errorOutput textContainer] setContainerSize: 
    NSMakeSize ([errorOutput frame].size.width, 1e7)];

  [[errorOutput textContainer] setWidthTracksTextView:YES];

  [scrollView1 setDocumentView:errorOutput];

  /*
   */
  scrollView2 = [[NSScrollView alloc] 
    initWithFrame:NSMakeRect (0, 0, 480, 133)];

  [scrollView2 setHasHorizontalScroller: NO];
  [scrollView2 setHasVerticalScroller: YES];
  [scrollView2 setBorderType: NSBezelBorder];
  [scrollView2 setAutoresizingMask:(NSViewWidthSizable | NSViewHeightSizable)];

  logOutput = [[NSTextView alloc] 
    initWithFrame:[[scrollView2 contentView] frame]];

  [logOutput setRichText:NO];
  [logOutput setEditable:NO];
  [logOutput setSelectable:YES];
  [logOutput setAutoresizingMask: NSViewWidthSizable | NSViewHeightSizable];
  [logOutput setBackgroundColor: [NSColor lightGrayColor]];
  [[logOutput textContainer] setWidthTracksTextView:YES];
  [[logOutput textContainer] setHeightTracksTextView:YES];
  [logOutput setHorizontallyResizable: NO];
  [logOutput setVerticallyResizable: YES];
  [logOutput setMinSize: NSMakeSize (0, 0)];
  [logOutput setMaxSize: NSMakeSize (1E7, 1E7)];
  [[logOutput textContainer] setContainerSize: 
    NSMakeSize ([logOutput frame].size.width, 1e7)];
  [[logOutput textContainer] setWidthTracksTextView:YES];

  [scrollView2 setDocumentView:logOutput];

  split = [[PCSplitView alloc] initWithFrame: NSMakeRect (-1, -1, 464, 253)];
  [split setAutoresizingMask: (NSViewWidthSizable | NSViewHeightSizable)];
  [split addSubview: scrollView1];
  [split addSubview: scrollView2];
  [split adjustSubviews];

  [componentView addSubview: split];

  RELEASE (scrollView1);
  RELEASE (scrollView2);
  RELEASE (split);

  /*
   * Target
   */
  textField = [[NSTextField alloc]
    initWithFrame: NSMakeRect (188, 293, 48, 21)];
  [textField setAlignment: NSRightTextAlignment];
  [textField setBordered: NO];
  [textField setBezeled: NO];
  [textField setEditable: NO];
  [textField setSelectable: NO];
  [textField setDrawsBackground: NO];
  [textField setStringValue:@"Target:"];
  [textField setAutoresizingMask: (NSViewMaxXMargin | NSViewMinYMargin)];
  [componentView addSubview: textField];

  RELEASE(textField);

  /*
   * Target message
   */
  targetField = [[NSTextField alloc] 
    initWithFrame:NSMakeRect(239, 293, 220, 21)];
  [targetField setAlignment: NSLeftTextAlignment];
  [targetField setBordered: NO];
  [targetField setEditable: NO];
  [targetField setBezeled: NO];
  [targetField setSelectable: NO];
  [targetField setDrawsBackground: NO];
  [targetField setStringValue: @"Default with args ' '"];
  [targetField setAutoresizingMask: (NSViewMaxXMargin | 
				     NSViewWidthSizable | 
				     NSViewMinYMargin)];
  [componentView addSubview:targetField];

  RELEASE (targetField);

  /*
   * Status
   */
  textField = [[NSTextField alloc]
    initWithFrame: NSMakeRect (188, 270, 48, 21)];
  [textField setAlignment: NSRightTextAlignment];
  [textField setBordered: NO];
  [textField setSelectable: NO];
  [textField setEditable: NO];
  [textField setBezeled: NO];
  [textField setDrawsBackground: NO];
  [textField setStringValue:@"Status:"];
  [textField setAutoresizingMask: (NSViewMaxXMargin | NSViewMinYMargin)];
  [componentView addSubview:textField];

  RELEASE(textField);

  /*
   * Status message
   */

  buildStatusField = [[NSTextField alloc]
    initWithFrame: NSMakeRect (239, 270, 220, 21)];
  [buildStatusField setAlignment: NSLeftTextAlignment];
  [buildStatusField setBordered: NO];
  [buildStatusField setEditable: NO];
  [buildStatusField setSelectable: NO];
  [buildStatusField setBezeled: NO];
  [buildStatusField setDrawsBackground: NO];
  [buildStatusField setStringValue: @"Waiting..."];
  [buildStatusField setAutoresizingMask: (NSViewMaxXMargin | 
					  NSViewWidthSizable | 
					  NSViewMinYMargin)];
  [componentView addSubview: buildStatusField];

  RELEASE(buildStatusField);

}

- (void) _createOptionsPanel
{
  NSView      *cView = nil;
  NSTextField *textField = nil;

  optionsPanel = [[NSPanel alloc] 
    initWithContentRect: NSMakeRect (100, 100, 300, 120)
              styleMask: NSTitledWindowMask | NSClosableWindowMask
	        backing: NSBackingStoreBuffered
		  defer: YES];
  [optionsPanel setDelegate: self];
  [optionsPanel setReleasedWhenClosed: NO];
  [optionsPanel setTitle: @"Build Options"];
  cView = [optionsPanel contentView];

  // Args
  textField = [[NSTextField alloc] initWithFrame: NSMakeRect (8,91,60,21)];
  [textField setAlignment: NSRightTextAlignment];
  [textField setBordered: NO];
  [textField setEditable: NO];
  [textField setBezeled: NO];
  [textField setDrawsBackground: NO];
  [textField setStringValue: @"Arguments:"];
  [cView addSubview: textField];
  
  RELEASE (textField);

  // Args message
  buildTargetArgsField = [[NSTextField alloc]
    initWithFrame: NSMakeRect (70, 91, 220, 21)];
  [buildTargetArgsField setAlignment: NSLeftTextAlignment];
  [buildTargetArgsField setBordered: NO];
  [buildTargetArgsField setEditable: YES];
  [buildTargetArgsField setBezeled: YES];
  [buildTargetArgsField setDrawsBackground: YES];
  [buildTargetArgsField setStringValue: @""];
  [buildTargetArgsField setDelegate: self];
  [buildTargetArgsField setTarget: self];
  [buildTargetArgsField setAction: @selector (setArguments:)];
  [cView addSubview: buildTargetArgsField];

//  RELEASE (buildTargetArgsField);

  // Host
  textField = [[NSTextField alloc] initWithFrame: NSMakeRect (8,67,60,21)];
  [textField setAlignment: NSRightTextAlignment];
  [textField setBordered: NO];
  [textField setEditable: NO];
  [textField setBezeled: NO];
  [textField setDrawsBackground: NO];
  [textField setStringValue: @"Host:"];
  [cView addSubview: textField];

  RELEASE (textField);

  // Host message
  buildTargetHostField = [[NSTextField alloc] 
    initWithFrame: NSMakeRect (70, 67, 220, 21)];
  [buildTargetHostField setAlignment: NSLeftTextAlignment];
  [buildTargetHostField setBordered: NO];
  [buildTargetHostField setEditable: YES];
  [buildTargetHostField setBezeled: YES];
  [buildTargetHostField setDrawsBackground: YES];
  [buildTargetHostField setStringValue: @"localhost"];
  [buildTargetHostField setDelegate: self];
  [buildTargetHostField setTarget: self];
  [buildTargetHostField setAction: @selector (setHost:)];
  [cView addSubview: buildTargetHostField];
  
//  RELEASE (buildTargetArgsField);

  // Target
  textField = [[NSTextField alloc]
    initWithFrame: NSMakeRect (8, 40, 60, 21)];
  [textField setAlignment: NSRightTextAlignment];
  [textField setBordered: NO];
  [textField setBezeled: NO];
  [textField setEditable: NO];
  [textField setSelectable: NO];
  [textField setDrawsBackground: NO];
  [textField setStringValue: @"Target:"];
  [textField setAutoresizingMask: (NSViewMaxXMargin | NSViewMinYMargin)];
  [cView addSubview: textField];

  RELEASE(textField);

  // Target popup
  popup = [[NSPopUpButton alloc] 
    initWithFrame: NSMakeRect (70, 40, 220, 21)];
  [popup addItemWithTitle: @"Default"];
  [popup addItemWithTitle: @"Debug"];
  [popup addItemWithTitle: @"Profile"];
  [popup addItemWithTitle: @"Tarball"];
  [popup addItemWithTitle: @"RPM"];
  [popup setTarget: self];
  [popup setAction: @selector (popupChanged:)];
  [popup setAutoresizingMask: (NSViewMaxXMargin | NSViewMinYMargin)];
  [cView addSubview: popup];

  RELEASE (popup);
}

@end

@implementation PCProjectBuilder

- (id)initWithProject: (PCProject *)aProject
{
  NSAssert(aProject, @"No project specified!");

  if ((self = [super init]))
    {
      makePath = [[aProject projectDict] objectForKey: PCBuildTool];

      if( [makePath isEqualToString: @""] )
	{
	  makePath = [NSString stringWithString: @"/usr/bin/make"];
	}
      RETAIN(makePath);

      buildTarget = [[NSMutableString alloc] initWithString: @"Default"];
      buildArgs = [[NSMutableArray array] retain];
      postProcess = NULL;
      currentProject = aProject;
      makeTask = nil;
    }

  return self;
}

- (void) dealloc
{
  [matrix release];
  [buildTarget release];
  [buildArgs release];
  [makePath release];

  [super dealloc];
}

- (NSPanel *) buildPanelCreate: (BOOL)create
{
  if (!buildPanel && create)
    {
      [self _createBuildPanel];
    }

  return buildPanel;
}

- (NSView *) componentView
{
  if (!componentView)
    {
      [self _createComponentView];
    }

  return componentView;
}

- (void) topButtonPressed: (id)sender
{
  NSString *tFString = [targetField stringValue];
  NSArray  *tFArray = [tFString componentsSeparatedByString: @" "];

  if (makeTask)
    {
      [makeTask terminate];
      return;
    }

  [buildTarget setString: [tFArray objectAtIndex: 0]];

  switch ([[sender selectedCell] tag]) 
    {
    case 0:
      // Set build arguments
      if ([buildTarget isEqualToString: @"Default"])
	{
	  ;
	}
      else if ([buildTarget isEqualToString: @"Debug"])
	{
	  [buildArgs addObject: @"debug=yes"];
	}
      else if ([buildTarget isEqualToString: @"Profile"])
	{
	  [buildArgs addObject: @"profile=yes"];
	  [buildArgs addObject: @"static=yes"];
	}
      else if ([buildTarget isEqualToString: @"Tarball"])
	{
	  [buildArgs addObject: @"dist"];
	}
      else if ([buildTarget isEqualToString: @"RPM"])
	{
	  [buildArgs addObject: @"rpm"];
	  postProcess = @selector (copyPackageTo:);
	}

      statusString = [NSString stringWithString: @"Building..."];
      [buildTarget setString: @"Build"];
      [self build: self];
      break;
      
    case 1:
      if ([[[[NSUserDefaults standardUserDefaults] dictionaryRepresentation]
	  objectForKey: PromptOnClean] isEqualToString: @"YES"])
	{
	  if (NSRunAlertPanel(@"Clean Project?",
			      @"Do you really want to clean project '%@'?",
			      @"Yes",
			      @"No",
			      nil,
			      [currentProject projectName])
	      == NSAlertAlternateReturn)
	    {
	      return;
	    }
	}
      [buildTarget setString: @"Clean"];
      statusString = [NSString stringWithString: @"Cleaning..."];
      [buildArgs addObject: @"distclean"];
      [self build: self];
      break;
      
    case 2:
      [buildTarget setString: @"Install"];
      statusString = [NSString stringWithString: @"Installing..."];
      [buildArgs addObject: @"install"];
      [self build: self];
      break;

    case 3:
      if (!optionsPanel)
	{
	  [self _createOptionsPanel];
	}
      [optionsPanel orderFront: nil];
      return;
    }
}

- (void) build: (id)sender
{
  NSPipe              *logPipe;
  NSPipe              *errorPipe;
  NSDictionary        *optionDict = [currentProject buildOptions];
  NSString            *status;
  NSDictionary        *env = [[NSProcessInfo processInfo] environment];
  NSMutableDictionary *data = [NSMutableDictionary dictionary];

  // Checking prerequisites
  if ([[currentProject projectWindow] isDocumentEdited])
    {
      if (NSRunAlertPanel(@"Project Changed!",
			  @"Should it be saved first?",
			  @"Yes",@"No",nil) == NSAlertDefaultReturn) 
	{
	  [currentProject save];
	}
    }

  if( [buildTarget isEqualToString: @"RPM"] 
      && [env objectForKey:@"RPM_TOPDIR"] == nil )
    {
      NSRunAlertPanel(@"Attention!",
		      @"First set the environment variable 'RPM_TOPDIR'!",
		      @"OK",nil,nil);     
      return;
    }

  NSLog (@"Status: %@ BuildTarget: %@", statusString, buildTarget);

  // Prepearing to building
  logPipe = [NSPipe pipe];
  readHandle = [[logPipe fileHandleForReading] retain];

  errorPipe = [NSPipe pipe];
  errorReadHandle = [[errorPipe fileHandleForReading] retain];

  [readHandle waitForDataInBackgroundAndNotify];
  [errorReadHandle waitForDataInBackgroundAndNotify];

  [NOTIFICATION_CENTER addObserver: self 
                          selector: @selector (logStdOut:)
			      name: NSFileHandleDataAvailableNotification
			    object: readHandle];

  [NOTIFICATION_CENTER addObserver: self 
                          selector: @selector (logErrOut:) 
			      name: NSFileHandleDataAvailableNotification
			    object: errorReadHandle];

  [buildStatusField setStringValue: statusString];

  // Run build thread
  [data setObject: buildArgs forKey: @"args"];
  [data setObject: [currentProject projectPath] forKey: @"currentDirectory"];
  [data setObject: makePath forKey: @"makePath"];
  [data setObject: logPipe forKey: @"logPipe"];
  [data setObject: errorPipe forKey: @"errorPipe"];

  [logOutput setString: @""];
  [errorOutput setString: @""];

  [NSThread detachNewThreadSelector: @selector (make:)
                           toTarget: self
                         withObject: data];

  [NOTIFICATION_CENTER addObserver: self
                          selector: @selector (buildDidTerminate:)
			      name: NSTaskDidTerminateNotification
			    object: makeTask];

  return;
}

- (void)buildDidTerminate: (NSNotification *)aNotif
{
  int status = [[aNotif object] terminationStatus];

  [NOTIFICATION_CENTER removeObserver: self 
                                 name: NSFileHandleDataAvailableNotification
			       object: readHandle];

  [NOTIFICATION_CENTER removeObserver: self 
                                 name: NSFileHandleDataAvailableNotification
			       object: errorReadHandle];

  [NOTIFICATION_CENTER removeObserver: self 
                                 name: NSTaskDidTerminateNotification 
			       object: makeTask];
  RELEASE (readHandle);
  RELEASE (errorReadHandle);

  if (status == 0)
    {
      [self logString: [NSString stringWithFormat: @"=== %@ succeeded!", buildTarget] error: NO newLine: NO];
      [buildStatusField setStringValue: [NSString stringWithFormat: 
	@"%@ - %@ succeeded...", [currentProject projectName], buildTarget]];
      [[matrix selectedCell] setState: NSOffState];
      [matrix setNeedsDisplay: YES];
    } 
  else
    {
      [self logString: [NSString stringWithFormat: @"=== %@ terminated!", buildTarget] error: NO newLine: NO];
      [buildStatusField setStringValue: [NSString stringWithFormat: 
	@"%@ - %@ terminated...", [currentProject projectName], buildTarget]];
    }

  [buildArgs removeAllObjects];
  [buildTarget setString: @"Default"];
  makeTask = nil;
}

- (void)popupChanged: (id)sender
{
  NSString *target = [targetField stringValue];

  target = [NSString stringWithFormat: 
            @"%@ with args ' %@ '", 
            [popup titleOfSelectedItem], 
            [buildTargetArgsField stringValue]];

  [targetField setStringValue: target];

}

- (void)logStdOut: (NSNotification *)aNotif
{
  NSData *data;

  if ((data = [readHandle availableData]))
    {
      [self logData: data error: NO];
    }

  [readHandle waitForDataInBackgroundAndNotifyForModes: nil];
}

- (void)logErrOut: (NSNotification *)aNotif
{
  NSData *data;

  if ((data = [errorReadHandle availableData]))
    {
      [self logData:data error:YES];
    }

  [errorReadHandle waitForDataInBackgroundAndNotifyForModes:nil];
}

- (void)copyPackageTo:(NSString *)path
{
  NSString *source = nil;
  NSString *dest = nil;
  NSString *rpm = nil;
  NSString *srcrpm = nil;

  // Copy the rpm files to the source directory
  if (source) 
  {
    [[NSFileManager defaultManager] copyPath:srcrpm toPath:dest handler:nil];
    [[NSFileManager defaultManager] copyPath:rpm    toPath:dest handler:nil];
  }
}

@end

@implementation PCProjectBuilder (BuildLogging)

- (void)logString: (NSString *)string
            error: (BOOL)yn
{
  [self logString: string error: yn newLine: NO];
}

- (void)logString: (NSString *)str
            error: (BOOL)yn
	  newLine: (BOOL)newLine
{
  NSTextView *out = (yn) ? errorOutput : logOutput;

  [out replaceCharactersInRange:
    NSMakeRange ([[out string] length],0) withString: str];

  if (newLine)
    {
      [out replaceCharactersInRange:
	NSMakeRange ([[out string] length], 0) withString: @"\n"];
    }
  else
    {
      [out replaceCharactersInRange:
	NSMakeRange ([[out string] length], 0) withString: @" "];
    }

  [out scrollRangeToVisible: NSMakeRange([[out string] length], 0)];
  [out setNeedsDisplay: YES];
}

- (void)logData: (NSData *)data
          error: (BOOL)yn
{
  NSString *s = [[NSString alloc] initWithData: data 
				  encoding: [NSString defaultCStringEncoding]];

  [self logString: s error: yn newLine: NO];
  [s autorelease];
}

@end

@implementation PCProjectBuilder (BuildThread)

- (void) make: (NSDictionary *)data
{
  NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
  
  makeTask = [[NSTask alloc] init];
  [makeTask setArguments: [data objectForKey: @"args"]];
  [makeTask setCurrentDirectoryPath: [data objectForKey: @"currentDirectory"]];
  [makeTask setLaunchPath: [data objectForKey: @"makePath"]];

  [makeTask setStandardOutput: [data objectForKey: @"logPipe"]];
  [makeTask setStandardError: [data objectForKey: @"errorPipe"]];

  [makeTask launch];
  [makeTask waitUntilExit];

  if ([makeTask terminationStatus] && postProcess)
    {
      [self performSelector: postProcess];
      postProcess = NULL;
    }

  [pool release];
}

@end
