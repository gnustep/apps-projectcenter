/*
   GNUstep ProjectCenter - http://www.gnustep.org

   Copyright (C) 2000-2004 Free Software Foundation

   Authors: Philippe C.D. Robert
            Serg Stoyan

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
*/

#include <AppKit/AppKit.h>

#include "PCDefines.h"
#include "PCSplitView.h"
#include "PCButton.h"

#include "PCProjectManager.h"
#include "PCProject.h"
#include "PCProjectBuilder.h"

#include "PCLogController.h"

#ifndef IMAGE
#define IMAGE(X) [NSImage imageNamed: X]
#endif

#ifndef NOTIFICATION_CENTER
#define NOTIFICATION_CENTER [NSNotificationCenter defaultCenter]
#endif

@implementation PCProjectBuilder (UserInterface)

- (void) _createComponentView
{
  NSSplitView  *split;
  NSScrollView *scrollView1; 
  NSScrollView *scrollView2;
  id           textField;

  componentView = [[NSBox alloc] initWithFrame: NSMakeRect(8,-1,464,322)];
  [componentView setTitlePosition: NSNoTitle];
  [componentView setBorderType: NSNoBorder];
  [componentView setAutoresizingMask: NSViewWidthSizable 
                                    | NSViewHeightSizable];
  [componentView setContentViewMargins: NSMakeSize (0.0, 0.0)];

  /*
   * 4 build Buttons
   */
  buildButton = [[PCButton alloc] initWithFrame: NSMakeRect(0,271,43,43)];
  [buildButton setToolTip: @"Build"];
  [buildButton setImage: IMAGE(@"Build")];
  [buildButton setAlternateImage: IMAGE(@"Stop")];
  [buildButton setTarget: self];
  [buildButton setAction: @selector(startBuild:)];
  [buildButton setAutoresizingMask: (NSViewMaxXMargin | NSViewMinYMargin)];
  [buildButton setButtonType: NSToggleButton];
  [componentView addSubview: buildButton];
  RELEASE (buildButton);
  
  cleanButton = [[PCButton alloc] initWithFrame: NSMakeRect(44,271,43,43)];
  [cleanButton setToolTip: @"Clean"];
  [cleanButton setImage: IMAGE(@"Clean")];
  [cleanButton setAlternateImage: IMAGE(@"Stop")];
  [cleanButton setTarget: self];
  [cleanButton setAction: @selector(startClean:)];
  [cleanButton setAutoresizingMask: (NSViewMaxXMargin | NSViewMinYMargin)];
  [cleanButton setButtonType: NSToggleButton];
  [componentView addSubview: cleanButton];
  RELEASE (cleanButton);

  installButton = [[PCButton alloc] initWithFrame: NSMakeRect(88,271,43,43)];
  [installButton setToolTip: @"Install"];
  [installButton setImage: IMAGE(@"Install")];
  [installButton setAlternateImage: IMAGE(@"Stop")];
  [installButton setTarget: self];
  [installButton setAction: @selector(startInstall:)];
  [installButton setAutoresizingMask: (NSViewMaxXMargin | NSViewMinYMargin)];
  [installButton setButtonType: NSToggleButton];
  [componentView addSubview: installButton];
  RELEASE (installButton);

  optionsButton = [[PCButton alloc] initWithFrame: NSMakeRect(132,271,43,43)];
  [optionsButton setToolTip: @"Options"];
  [optionsButton setImage: IMAGE(@"Options")];
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
  RELEASE(errorOutput);

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
  RELEASE(logOutput);

  split = [[PCSplitView alloc] initWithFrame: NSMakeRect (0, 0, 464, 255)];
  [split setAutoresizingMask: (NSViewWidthSizable | NSViewHeightSizable)];

  [split addSubview: scrollView1];
  RELEASE (scrollView1);
  [split addSubview: scrollView2];
  RELEASE (scrollView2);

  [split adjustSubviews];
  [componentView addSubview: split];
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

- (id)initWithProject:(PCProject *)aProject
{
  NSAssert(aProject, @"No project specified!");

//  PCLogInfo(self, @"initWithProject %@", [aProject projectName]);
  
  if ((self = [super init]))
    {
      currentProject = aProject;
      buildTarget = [[NSMutableString alloc] initWithString:@"Default"];
      buildArgs = [[NSMutableArray array] retain];
      postProcess = NULL;
      makeTask = nil;
      _isBuilding = NO;
      _isCleaning = NO;
    }

  return self;
}

- (void)dealloc
{
#ifdef DEVELOPMENT
  NSLog (@"PCProjectBuilder: dealloc");
#endif
  [buildTarget release];
  [buildArgs release];
  [makePath release];

//  PCLogInfo(self, @"componentView RC: %i", [componentView retainCount]);
//  PCLogInfo(self, @"RC: %i", [self retainCount]);
  [componentView release];

  [super dealloc];
}

- (NSView *)componentView
{
  if (!componentView)
    {
      [self _createComponentView];
    }

  return componentView;
}

// --- Accessory
- (BOOL)isBuilding
{
  return _isBuilding;
}

- (BOOL)isCleaning
{
  return _isCleaning;
}

- (void)performStartBuild
{
  if (!_isBuilding && !_isCleaning)
    {
      [buildButton performClick:self];
    }
}

- (void)performStartClean
{
  if (!_isCleaning && !_isBuilding)
    {
      [cleanButton performClick:self];
    }
}

- (void)performStopBuild
{
  if (_isBuilding)
    {
      [buildButton performClick:self];
    }
  else if (_isCleaning)
    {
      [cleanButton performClick:self];
    }
}

// --- GUI Actions
- (void)startBuild:(id)sender
{
  NSString *tFString = [targetField stringValue];
  NSArray  *tFArray = [tFString componentsSeparatedByString:@" "];

  if ([self stopBuild:self] == YES)
    {// We've just stopped build process
      return;
    }
  makePath = [[NSUserDefaults standardUserDefaults] objectForKey:BuildTool];

  [buildTarget setString:[tFArray objectAtIndex:0]];

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
  [self build:self];
  _isBuilding = YES;
}

- (BOOL)stopBuild:(id)sender
{
  // [makeTask isRunning] doesn't work here.
  // "waitpid 7045, result -1, error No child processes" is printed.
  if (makeTask)
    {
      PCLogStatus(self, @"task will terminate");
      [makeTask terminate];
      return YES;
    }

  return NO;
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
  _isCleaning = YES;
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

// --- Actions
- (void)build:(id)sender
{
  NSPipe       *logPipe;
  NSPipe       *errorPipe;
  NSDictionary *env = [[NSProcessInfo processInfo] environment];

  // Support build options!!!
  //NSDictionary        *optionDict = [currentProject buildOptions];

  // Checking prerequisites
  if ([currentProject isProjectChanged])
    {
      if (NSRunAlertPanel(@"Project Changed!",
			  @"Should it be saved first?",
			  @"Yes",@"No",nil) == NSAlertDefaultReturn) 
	{
	  [currentProject save];
	}
    }
  else
    {
      // Synchronize PC.project and generated files just for case
      [currentProject save];
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
  readHandle = [logPipe fileHandleForReading];
  [readHandle waitForDataInBackgroundAndNotify];

  [NOTIFICATION_CENTER addObserver: self 
                          selector: @selector (logStdOut:)
			      name: NSFileHandleDataAvailableNotification
			    object: readHandle];

  errorPipe = [NSPipe pipe];
  errorReadHandle = [errorPipe fileHandleForReading];
  [errorReadHandle waitForDataInBackgroundAndNotify];

  [NOTIFICATION_CENTER addObserver: self 
                          selector: @selector (logErrOut:) 
			      name: NSFileHandleDataAvailableNotification
			    object: errorReadHandle];

  [buildStatusField setStringValue: statusString];

  // Run make task
  [logOutput setString: @""];
  [errorOutput setString: @""];

  [NOTIFICATION_CENTER addObserver: self 
                          selector: @selector (buildDidTerminate:) 
			      name: NSTaskDidTerminateNotification
			    object: nil];

  makeTask = [[NSTask alloc] init];
  [makeTask setArguments: buildArgs];
  [makeTask setCurrentDirectoryPath: [currentProject projectPath]];
  [makeTask setLaunchPath: makePath];

  [makeTask setStandardOutput: logPipe];
  [makeTask setStandardError: errorPipe];

  [makeTask launch];
}

- (void)buildDidTerminate:(NSNotification *)aNotif
{
  int status;

  if ([aNotif object] != makeTask)
    {
      return;
    }

  [NOTIFICATION_CENTER removeObserver:self];

  status = [makeTask terminationStatus];
  if (status == 0)
    {
      [self logString: 
	[NSString stringWithFormat: @"=== %@ succeeded!", buildTarget] 
	error: NO newLine: NO];
      [buildStatusField setStringValue: 
	[NSString stringWithFormat: 
	@"%@ - %@ succeeded...", [currentProject projectName], buildTarget]];
    } 
  else
    {
      [self logString: 
	[NSString stringWithFormat: @"=== %@ terminated!", buildTarget]
	error: NO newLine: NO];
      [buildStatusField setStringValue: 
	[NSString stringWithFormat: 
	@"%@ - %@ terminated...", [currentProject projectName], buildTarget]];
    }

  // Rstore buttons state
  if ([buildTarget isEqualToString: @"Build"])
    {
      [buildButton setState: NSOffState];
      [cleanButton setEnabled: YES];
      [installButton setEnabled: YES];
    }
  else if ([buildTarget isEqualToString: @"Clean"])
    {
      [cleanButton setState: NSOffState];
      [buildButton setEnabled: YES];
      [installButton setEnabled: YES];
    }
  else if ([buildTarget isEqualToString: @"Install"])
    {
      [installButton setState: NSOffState];
      [buildButton setEnabled: YES];
      [cleanButton setEnabled: YES];
    }

  [buildArgs removeAllObjects];
  [buildTarget setString: @"Default"];

  RELEASE(makeTask);
  makeTask = nil;

  // Run post process if configured
  if (status && postProcess)
    {
      [self performSelector: postProcess];
      postProcess = NULL;
    }

  _isBuilding = NO;
  _isCleaning = NO;
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
  RELEASE(s);
}

@end

