/*
   GNUstep ProjectCenter - http://www.gnustep.org

   Copyright (C) 2001 Free Software Foundation

   Author: Philippe C.D. Robert <phr@3dkit.org>

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

#import "PCProjectBuilder.h"
#import "PCProject.h"
#import "PCProject+ComponentHandling.h"
#import "PCProjectManager.h"

#import <AppKit/AppKit.h>

#ifndef IMAGE
#define IMAGE(X) [[[NSImage alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForImageResource:(X)]] autorelease]
#endif

#ifndef NOTIFICATION_CENTER
#define NOTIFICATION_CENTER [NSNotificationCenter defaultCenter]
#endif

#define DEFAULT_RPM_ROOT @"/usr/src/redhat/"

@interface PCProjectBuilder (CreateUI)

- (void)_createComponentView;

@end

@implementation PCProjectBuilder (CreateUI)

- (void)_createComponentView
{
  NSSplitView *split;
  NSScrollView *scrollView1; 
  NSScrollView *scrollView2; 
  NSMatrix* matrix;
  NSRect _w_frame;
  NSButtonCell* buttonCell = [[[NSButtonCell alloc] init] autorelease];
  NSBox *box;
  id button;
  id textField;

  componentView = [[NSBox alloc] initWithFrame:NSMakeRect(-1,-1,562,248)];
  [componentView setTitlePosition:NSNoTitle];
  [componentView setBorderType:NSNoBorder];
  [componentView setAutoresizingMask:NSViewWidthSizable | NSViewHeightSizable];
  [componentView setContentViewMargins: NSMakeSize(0.0,0.0)];

  /*
   */

  scrollView1 = [[NSScrollView alloc] initWithFrame:NSMakeRect (-1,0,562,46)];

  [scrollView1 setHasHorizontalScroller: NO];
  [scrollView1 setHasVerticalScroller: YES];
  [scrollView1 setBorderType: NSBezelBorder];
  [scrollView1 setAutoresizingMask:(NSViewWidthSizable | NSViewHeightSizable)];

  logOutput = [[NSTextView alloc] initWithFrame:[[scrollView1 contentView] frame]];

  [logOutput setRichText:NO];
  [logOutput setEditable:NO];
  [logOutput setSelectable:YES];
  [logOutput setAutoresizingMask: NSViewWidthSizable | NSViewHeightSizable];
  //[logOutput setBackgroundColor:[NSColor lightGrayColor]];
  [logOutput setBackgroundColor:[NSColor colorWithDeviceRed:0.93
                                                      green:0.77 
						       blue:0.46 
						      alpha:1.0]];
  [[logOutput textContainer] setWidthTracksTextView:YES];
  [[logOutput textContainer] setHeightTracksTextView:YES];
  [logOutput setHorizontallyResizable: NO];
  [logOutput setVerticallyResizable: YES];
  [logOutput setMinSize: NSMakeSize (0, 0)];
  [logOutput setMaxSize: NSMakeSize (1E7, 1E7)];
  [[logOutput textContainer] setContainerSize: 
                               NSMakeSize ([logOutput frame].size.width,1e7)];
  [[logOutput textContainer] setWidthTracksTextView:YES];

  [scrollView1 setDocumentView:logOutput];

  /*
   *
   */

  scrollView2 = [[NSScrollView alloc] initWithFrame:NSMakeRect (-1,0,562,92)];

  [scrollView2 setHasHorizontalScroller:NO];
  [scrollView2 setHasVerticalScroller:YES];
  [scrollView2 setBorderType: NSBezelBorder];
  [scrollView2 setAutoresizingMask:(NSViewWidthSizable | NSViewHeightSizable)];

  errorOutput = [[NSTextView alloc] initWithFrame:[[scrollView2 contentView] frame]];

  [errorOutput setRichText:NO];
  [errorOutput setEditable:NO];
  [errorOutput setSelectable:YES];
  [errorOutput setAutoresizingMask: NSViewWidthSizable | NSViewHeightSizable];
  [errorOutput setBackgroundColor:[NSColor whiteColor]];
  [errorOutput setHorizontallyResizable: NO];  
  [errorOutput setVerticallyResizable: YES];
  [errorOutput setMinSize: NSMakeSize (0, 0)];
  [errorOutput setMaxSize: NSMakeSize (1E7, 1E7)];
  [[errorOutput textContainer] setContainerSize: 
				 NSMakeSize ([errorOutput frame].size.width, 1e7)];

  [[errorOutput textContainer] setWidthTracksTextView:YES];
  //[[errorOutput textContainer] setHeightTracksTextView:YES];

  [scrollView2 setDocumentView:errorOutput];

  split = [[NSSplitView alloc] initWithFrame:NSMakeRect(-1,-1,562,152)];  
  [split setAutoresizingMask: (NSViewWidthSizable | NSViewHeightSizable)];
  [split addSubview: scrollView1];
  [split addSubview: scrollView2];
  [split adjustSubviews];
  
  [componentView addSubview:split];

  RELEASE(scrollView1);
  RELEASE(scrollView2);
  RELEASE(split);

  /*
   * 2 build Buttons
   */

  _w_frame = NSMakeRect(-1,160,120,60);
  matrix = [[NSMatrix alloc] initWithFrame: _w_frame
			     mode: NSHighlightModeMatrix
			     prototype: buttonCell
			     numberOfRows:1
			     numberOfColumns:2];
  [matrix sizeToCells];
  [matrix setSelectionByRect:YES];
  [matrix setAutoresizingMask: (NSViewMaxXMargin | NSViewMinYMargin)];
  [matrix setTarget:self];
  [matrix setAction:@selector(build:)];
  [componentView addSubview:matrix];

  RELEASE(matrix);

  button = [matrix cellAtRow:0 column:0];
  [button setTag:0];
  [button setImagePosition:NSImageAbove];
  [button setImage:IMAGE(@"ProjectCenter_make")];
  [button setButtonType:NSMomentaryPushButton];
  [button setTitle:@"Build"];

  button = [matrix cellAtRow:0 column:1];
  [button setTag:1];
  [button setImagePosition:NSImageAbove];
  [button setImage:IMAGE(@"ProjectCenter_clean")];
  [button setButtonType:NSMomentaryPushButton];
  [button setTitle:@"Clean"];

  box = [[NSBox alloc] initWithFrame:NSMakeRect(128,160,204,60)];
  [box setTitle:@"Build Target"];
  [box setBorderType:NSBezelBorder];
  [box setAutoresizingMask: (NSViewMaxXMargin | NSViewMinYMargin)];
  [componentView addSubview:box];
  RELEASE(box);

  popup = [[NSPopUpButton alloc] initWithFrame:NSMakeRect(8,6,172,21)];
  [popup addItemWithTitle:@"Default"];
  [popup addItemWithTitle:@"Debug"];
  [popup addItemWithTitle:@"Profile"];
  [popup addItemWithTitle:@"Install"];
  [popup addItemWithTitle:@"Tarball"];
  [popup addItemWithTitle:@"RPM"];
  [popup setTarget:self];
  [popup setAction:@selector(popupChanged:)];
  [box addSubview:popup];
  RELEASE(popup);

  /*
   * Status
   */

  textField = [[NSTextField alloc] initWithFrame:NSMakeRect(334,192,48,15)];
  [textField setAlignment: NSRightTextAlignment];
  [textField setBordered: NO];
  [textField setEditable: NO];
  [textField setBezeled: NO];
  [textField setDrawsBackground: NO];
  [textField setStringValue:@"Status:"];
  [textField setAutoresizingMask: (NSViewMaxXMargin | 
				   NSViewMinYMargin)];
  [componentView addSubview:textField];

  RELEASE(textField);

  /*
   * Status message
   */

  buildStatusField = [[NSTextField alloc] initWithFrame:NSMakeRect(386,192,104,15)];
  [buildStatusField setAlignment: NSLeftTextAlignment];
  [buildStatusField setBordered: NO];
  [buildStatusField setEditable: NO];
  [buildStatusField setBezeled: NO];
  [buildStatusField setDrawsBackground: NO];
  [buildStatusField setStringValue:@"waiting..."];
  [buildStatusField setAutoresizingMask: (NSViewMaxXMargin | 
					  NSViewWidthSizable | 
					  NSViewMinYMargin)];
  [componentView addSubview:buildStatusField];

  RELEASE(buildStatusField);

  /*
   * Target
   */

  textField = [[NSTextField alloc] initWithFrame:NSMakeRect(334,172,48,15)];
  [textField setAlignment: NSRightTextAlignment];
  [textField setBordered: NO];
  [textField setBezeled: NO];
  [textField setEditable: NO];
  [textField setDrawsBackground: NO];
  [textField setStringValue:@"Target:"];
  [textField setAutoresizingMask: (NSViewMaxXMargin | 
				   NSViewMinYMargin)];
  [componentView addSubview:textField];

  RELEASE(textField);

  /*
   * Target message
   */

  targetField = [[NSTextField alloc] initWithFrame:NSMakeRect(386,172,104,15)];
  [targetField setAlignment: NSLeftTextAlignment];
  [targetField setBordered: NO];
  [targetField setEditable: NO];
  [targetField setBezeled: NO];
  [targetField setDrawsBackground: NO];
  [targetField setStringValue:@"Default..."];
  [targetField setAutoresizingMask: (NSViewMaxXMargin | 
				     NSViewWidthSizable | 
				     NSViewMinYMargin)];
  [componentView addSubview:targetField];

  [componentView sizeToFit];
  RELEASE(targetField);
}

@end

@implementation PCProjectBuilder

- (id)initWithProject:(PCProject *)aProject
{
    NSAssert(aProject,@"No project specified!");

    if ((self = [super init])) {
        makePath = [[aProject projectDict] objectForKey:PCBuildTool];

	if( [makePath isEqualToString:@""] )
	{
	    makePath = [NSString stringWithString:@"/usr/bin/make"];
        }

	RETAIN(makePath);
	currentProject = aProject;
    }
    return self;
}

- (void)dealloc
{
  [componentView release];
  [makePath release];

  [super dealloc];
}

- (NSView *)componentView;
{
  if (!componentView) {
    [self _createComponentView];
  }

  return componentView;
}

- (void)build:(id)sender
{
    NSString *tg = nil;
    NSTask *makeTask;
    NSMutableArray *args;
    NSPipe *logPipe;
    NSPipe *errorPipe;
    NSDictionary *optionDict;
    NSString *status;
    SEL postProcess = NULL;
    NSDictionary *env = [[NSProcessInfo processInfo] environment];

    if( [[currentProject projectWindow] isDocumentEdited] )
    {
	if (NSRunAlertPanel(@"Project Changed!",
	                    @"Should it be saved first?",
			    @"Yes",@"No",nil) == NSAlertDefaultReturn) 
	{
	    [currentProject save];
	}
    }

  logPipe = [NSPipe pipe];
  readHandle = [[logPipe fileHandleForReading] retain];

  errorPipe = [NSPipe pipe];
  errorReadHandle = [[errorPipe fileHandleForReading] retain];

  makeTask = [[NSTask alloc] init];

  optionDict = [currentProject buildOptions];
  args = [NSMutableArray array];

  switch ([[sender selectedCell] tag]) 
  {
    case 0:
      status = [NSString stringWithString:@"Building..."];
      switch( [popup indexOfSelectedItem] )
      {
          case 0:
	    break;

          case 1:
	    [args addObject:@"debug=yes"];
	    break;

          case 2:
	    [args addObject:@"profile=yes"];
	    [args addObject:@"static=yes"];
	    break;

          case 3:
	    [args addObject:@"install"];
	    break;
	    
          case 4:
	    [args addObject:@"dist"];
	    break;
	    
          case 5:
	    [args addObject:@"rpm"];
	    postProcess = @selector(copyPackageTo:);

	    if ( [currentProject writeSpecFile] == NO )
	    {
		return;
	    }

	    if( [env objectForKey:@"RPM_TOPDIR"] == nil )
	    {
		NSRunAlertPanel(@"Attention!",
	                @"First set the environment variable 'RPM_TOPDIR'!",
			@"OK",nil,nil);     
		return;
	    }
	    break;

	  default:
	    break;
      }
      break;
    case 1:
      if (NSRunAlertPanel(@"Clean Project?",
                          @"Do you really want to clean project '%@'?",
			  @"Yes",
			  @"No",
			  nil,
			  [currentProject projectName]) == NSAlertAlternateReturn) {
        return;
      }
      status = [NSString stringWithString:@"Cleaning..."];
      [args addObject:@"distclean"];
      break;
  }

  [buildStatusField setStringValue:status];  

  [NOTIFICATION_CENTER addObserver:self 
		       selector:@selector(logStdOut:) 
		       name:NSFileHandleDataAvailableNotification
		       object:readHandle];
  
  [NOTIFICATION_CENTER addObserver:self 
		       selector:@selector(logErrOut:) 
		       name:NSFileHandleDataAvailableNotification
		       object:errorReadHandle];
  
  [NOTIFICATION_CENTER addObserver: self
		       selector: @selector(buildDidTerminate:)
		       name: NSTaskDidTerminateNotification
		       object: makeTask];  
  
  [makeTask setArguments:args];  
  [makeTask setCurrentDirectoryPath:[currentProject projectPath]];
  [makeTask setLaunchPath:makePath];
  
  [makeTask setStandardOutput:logPipe];
  [makeTask setStandardError:errorPipe];

  [logOutput setString:@""];
  [readHandle waitForDataInBackgroundAndNotify];

  [errorOutput setString:@""];
  [errorReadHandle waitForDataInBackgroundAndNotify];
  
  [makeTask launch];
  [makeTask waitUntilExit];

  if (postProcess) {
    [self performSelector:postProcess];
    postProcess = NULL;
  }
  
  [buildStatusField setStringValue:@"Waiting..."];  

  [NOTIFICATION_CENTER removeObserver:self 
		       name:NSFileHandleDataAvailableNotification
		       object:readHandle];
  
  [NOTIFICATION_CENTER removeObserver:self 
		       name:NSFileHandleDataAvailableNotification
		       object:errorReadHandle];
  
  [NOTIFICATION_CENTER removeObserver:self 
		       name:NSTaskDidTerminateNotification 
		       object:makeTask];

  RELEASE(readHandle);
  RELEASE(errorReadHandle);  
  AUTORELEASE(makeTask);
}

- (void)popupChanged:(id)sender
{
  NSString *target = [targetField stringValue];

  switch ([sender indexOfSelectedItem]) 
  {
      case 0:
	  target = [NSString stringWithString:@"Default"];
          break;
      case 1:
	  target = [NSString stringWithString:@"Debug"];
          break;
      case 2:
	  target = [NSString stringWithString:@"Profile"];
          break;
      case 3:
	  target = [NSString stringWithString:@"Install"];
          break;
      case 4:
	  target = [NSString stringWithString:@"Tarball"];
          break;
      case 5:
	  target = [NSString stringWithString:@"RPM"];
          break;
      default:
          break;
  }
  [targetField setStringValue:target];  
}

- (void)logStdOut:(NSNotification *)aNotif
{
  NSData *data;

  if ((data = [readHandle availableData])) {
    [self logData:data error:NO];
  }

  [readHandle waitForDataInBackgroundAndNotifyForModes:nil];
}

- (void)logErrOut:(NSNotification *)aNotif
{
  NSData *data;

  if ((data = [errorReadHandle availableData])) {
    [self logData:data error:YES];
  }

  [errorReadHandle waitForDataInBackgroundAndNotifyForModes:nil];
}

- (void)buildDidTerminate:(NSNotification *)aNotif
{
  int status = [[aNotif object] terminationStatus];

  if (status == 0) {
    [self logString:@"*** Build Succeeded!\n" error:NO newLine:YES];
  } 
  else {
    [self logString:@"*** Build Failed!" error:YES newLine:YES];
    [[logOutput window] orderFront:self];
  }
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

- (void)logString:(NSString *)string error:(BOOL)yn
{
  [self logString:string error:yn newLine:YES];
}

- (void)logString:(NSString *)str error:(BOOL)yn newLine:(BOOL)newLine
{
  NSTextView *out = (yn)?errorOutput:logOutput;

  [out replaceCharactersInRange:NSMakeRange([[out string] length],0) withString:str];

  if (newLine) {
    [out replaceCharactersInRange:NSMakeRange([[out string] length], 0) withString:@"\n"];
  }
  else {
    [out replaceCharactersInRange:NSMakeRange([[out string] length], 0) withString:@" "];
  }
  
  [out scrollRangeToVisible:NSMakeRange([[out string] length], 0)];
}

- (void)logData:(NSData *)data error:(BOOL)yn
{
  NSString *s = [[NSString alloc] initWithData:data 
				  encoding:[NSString defaultCStringEncoding]];

  [self logString:s error:yn newLine:YES];
  [s autorelease];
}

@end




