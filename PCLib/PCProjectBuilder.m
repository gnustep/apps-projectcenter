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
#include "PCButton.h"

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
  [buildPanel setHidesOnDeactivate: NO];
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
  id           textField;

  componentView = [[NSBox alloc] initWithFrame: NSMakeRect(8, -1, 464, 322)];
  [componentView setTitlePosition: NSNoTitle];
  [componentView setBorderType: NSNoBorder];
  [componentView setAutoresizingMask: NSViewWidthSizable 
                                    | NSViewHeightSizable];
  [componentView setContentViewMargins: NSMakeSize (0.0, 0.0)];

  /*
   * 4 build Buttons
   */
  buildButton = [[PCButton alloc] initWithFrame: NSMakeRect(0,264,50,50)];
  [buildButton setTitle: @"Build"];
  [buildButton setImage: IMAGE(@"ProjectCenter_make")];
  [buildButton setAlternateImage: IMAGE(@"Stop")];
  [buildButton setTarget: self];
  [buildButton setAction: @selector(startBuild:)];
  [buildButton setAutoresizingMask: (NSViewMaxXMargin | NSViewMinYMargin)];
  [buildButton setButtonType: NSToggleButton];
  [componentView addSubview: buildButton];
  RELEASE (buildButton);
  
  cleanButton = [[PCButton alloc] initWithFrame: NSMakeRect(50,264,50,50)];
  [cleanButton setTitle: @"Clean"];
  [cleanButton setImage: IMAGE(@"ProjectCenter_clean")];
  [cleanButton setAlternateImage: IMAGE(@"Stop")];
  [cleanButton setTarget: self];
  [cleanButton setAction: @selector(startClean:)];
  [cleanButton setAutoresizingMask: (NSViewMaxXMargin | NSViewMinYMargin)];
  [cleanButton setButtonType: NSToggleButton];
  [componentView addSubview: cleanButton];
  RELEASE (cleanButton);

  installButton = [[PCButton alloc] initWithFrame: NSMakeRect(100,264,50,50)];
  [installButton setTitle: @"Install"];
  [installButton setImage: IMAGE(@"ProjectCenter_install")];
  [installButton setAlternateImage: IMAGE(@"Stop")];
  [installButton setTarget: self];
  [installButton setAction: @selector(startInstall:)];
  [installButton setAutoresizingMask: (NSViewMaxXMargin | NSViewMinYMargin)];
  [installButton setButtonType: NSToggleButton];
  [componentView addSubview: installButton];
  RELEASE (installButton);

  optionsButton = [[PCButton alloc] initWithFrame: NSMakeRect(150,264,50,50)];
  [optionsButton setTitle: @"Options"];
  [optionsButton setImage: IMAGE(@"ProjectCenter_prefs")];
  [optionsButton setTarget: self];
  [optionsButton setAction: @selector(showOptionsPanel:)];
  [optionsButton setAutoresizingMask: (NSViewMaxXMargin | NSViewMinYMargin)];
  [optionsButton setButtonType: NSMomentaryPushButton];
  [componentView addSubview: optionsButton];
  RELEASE (optionsButton);

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
    initWithFrame: NSMakeRect (200, 293, 48, 21)];
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
    initWithFrame:NSMakeRect(251, 293, 220, 21)];
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
    initWithFrame: NSMakeRect (200, 270, 48, 21)];
  [textField setAlignment: NSRightTextAlignment];
  [textField setBordered: NO];
  [textField setSelectable: NO];
  [textField setEditable: NO];
  [textField setBezeled: NO];
  [textField setDrawsBackground: NO];
//  [textField setBackgroundColor: [NSColor darkGrayColor]];
  [textField setStringValue:@"Status:"];
  [textField setAutoresizingMask: (NSViewMaxXMargin | NSViewMinYMargin)];
  [componentView addSubview:textField];
  RELEASE(textField);

  /*
   * Status message
   */
  buildStatusField = [[NSTextField alloc]
    initWithFrame: NSMakeRect (251, 270, 220, 21)];
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
  [buildTarget release];
  [buildArgs release];
  [makePath release];

  [super dealloc];
}

- (NSPanel *) createBuildPanel
{
  if (!buildPanel)
    {
      [self _createBuildPanel];
    }

  return buildPanel;
}

- (NSPanel *) buildPanel
{
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

- (void)setTooltips
{
  [buildButton setShowTooltip:YES];
  [cleanButton setShowTooltip:YES];
  [installButton setShowTooltip:YES];
  [optionsButton setShowTooltip:YES];
}


- (void)startBuild:(id)sender
{
  NSString *tFString = [targetField stringValue];
  NSArray  *tFArray = [tFString componentsSeparatedByString: @" "];

  // [makeTask isRunning] doesn't work here.
  // "waitpid 7045, result -1, error No child processes" is printed.
  if (makeTask)
    {
      [makeTask terminate];
      return;
    }

  [buildTarget setString: [tFArray objectAtIndex: 0]];

  // Set build arguments
  if ([buildTarget isEqualToString: @"Debug"])
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
  [cleanButton setEnabled:NO];
  [installButton setEnabled:NO];
  [self build: self];
}

- (void)startClean:(id)sender
{
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
	  [cleanButton setState: NSOffState];
	  return;
	}
    }
  [buildTarget setString: @"Clean"];
  statusString = [NSString stringWithString: @"Cleaning..."];
  [buildArgs addObject: @"distclean"];
  [buildButton setEnabled:NO];
  [installButton setEnabled:NO];
  [self build: self];
}

- (void)startInstall:(id)sender
{
  [buildTarget setString: @"Install"];
  statusString = [NSString stringWithString: @"Installing..."];
  [buildArgs addObject: @"install"];
  [buildButton setEnabled:NO];
  [cleanButton setEnabled:NO];
  [self build: self];
}

- (void)showOptionsPanel:(id)sender
{
  if (!optionsPanel)
    {
      [self _createOptionsPanel];
    }
  [optionsPanel orderFront: nil];
}


- (void)build:(id)sender
{
  NSPipe              *logPipe;
  NSPipe              *errorPipe;
//  NSDictionary        *optionDict = [currentProject buildOptions];
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

  // Prepearing to building
  logPipe = [NSPipe pipe];
//  readHandle = [[logPipe fileHandleForReading] retain];
  readHandle = [logPipe fileHandleForReading];

  errorPipe = [NSPipe pipe];
//  errorReadHandle = [[errorPipe fileHandleForReading] retain];
  errorReadHandle = [errorPipe fileHandleForReading];

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

  [NSThread detachNewThreadSelector: @selector(make:)
                           toTarget: self
                         withObject: data];

  [NOTIFICATION_CENTER addObserver: self
                          selector: @selector (buildDidTerminate:)
			      name: NSTaskDidTerminateNotification
			    object: makeTask];

  return;
}

- (void)buildDidTerminate:(NSNotification *)aNotif
{
  int status = [[aNotif object] terminationStatus];

  if ([aNotif object] == makeTask)
    {
      [NOTIFICATION_CENTER removeObserver: self 
	                             name: NSFileHandleDataAvailableNotification
	                           object: readHandle];

      [NOTIFICATION_CENTER removeObserver: self 
	                             name: NSFileHandleDataAvailableNotification
 	                           object: errorReadHandle];

      [NOTIFICATION_CENTER removeObserver: self 
	                             name: NSTaskDidTerminateNotification 
	                           object: makeTask];
      //  RELEASE (readHandle);
      //  RELEASE (errorReadHandle);

      if (status == 0)
	{
	  [self logString: 
	    [NSString stringWithFormat: @"=== %@ succeeded!", buildTarget] 
	    error: NO
	    newLine: NO];
	  [buildStatusField setStringValue: [NSString stringWithFormat: @"%@ - %@ succeeded...", [currentProject projectName], buildTarget]];
	} 
      else
	{
	  [self logString: [NSString stringWithFormat: @"=== %@ terminated!", buildTarget] error: NO newLine: NO];
	  [buildStatusField setStringValue: [NSString stringWithFormat: 
	    @"%@ - %@ terminated...", [currentProject projectName], buildTarget]];
	}

      // Rstore buttons state
      if ([buildTarget isEqualToString: @"Build"])
	{
	  [buildButton setState: NSOffState];
	  [cleanButton setEnabled:YES];
	  [installButton setEnabled:YES];
	}
      else if ([buildTarget isEqualToString: @"Clean"])
	{
	  [cleanButton setState: NSOffState];
	  [buildButton setEnabled:YES];
	  [installButton setEnabled:YES];
	}
      else if ([buildTarget isEqualToString: @"Install"])
	{
	  [installButton setState: NSOffState];
	  [buildButton setEnabled:YES];
	  [cleanButton setEnabled:YES];
	}

      [buildArgs removeAllObjects];
      [buildTarget setString: @"Default"];

      /*  RELEASE (makeTask);*/
      makeTask = nil;
    }
}

- (void)popupChanged:(id)sender
{
  NSString *target = [targetField stringValue];

  target = [NSString stringWithFormat: 
            @"%@ with args ' %@ '", 
            [popup titleOfSelectedItem], 
            [buildTargetArgsField stringValue]];

  [targetField setStringValue: target];

}

- (void)logStdOut:(NSNotification *)aNotif
{
  NSData *data;

  if ((data = [readHandle availableData]))
    {
      [self logData: data error: NO];
    }

  [readHandle waitForDataInBackgroundAndNotifyForModes: nil];
}

- (void)logErrOut:(NSNotification *)aNotif
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

- (void)make:(NSDictionary *)data
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
