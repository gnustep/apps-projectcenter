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

#include "PCProjectDebugger.h"
#include "PCProjectDebugger+UInterface.h"
#include "PCDefines.h"
#include "PCProject.h"
#include "PCProjectManager.h"
#include "PCButton.h"

#include <AppKit/AppKit.h>

#ifndef NOTIFICATION_CENTER
#define NOTIFICATION_CENTER [NSNotificationCenter defaultCenter]
#endif

enum {
    DEBUG_DEFAULT_TARGET = 1,
    DEBUG_DEBUG_TARGET   = 2
};

@protocol Terminal

- (BOOL)terminalRunProgram:(NSString *)path
             withArguments:(NSArray *)args
               inDirectory:(NSString *)directory
                properties:(NSDictionary *)properties;

@end

@implementation PCProjectDebugger

- (id)initWithProject:(PCProject *)aProject
{
  NSAssert (aProject, @"No project specified!");

  if ((self = [super init]))
    {
      NSFont *font = [NSFont userFixedPitchFontOfSize: 10.0];

      currentProject = aProject;
      debugTarget = DEBUG_DEFAULT_TARGET;

      textAttributes = 
	[NSDictionary dictionaryWithObject:font forKey:NSFontAttributeName];
      [textAttributes retain];
    }

  return self;
}

- (void)dealloc
{
  RELEASE (componentView);
  RELEASE (textAttributes);

  if (readHandle)
    {
      RELEASE (readHandle);
    }
    
  if (errorReadHandle)
    {
      RELEASE (errorReadHandle);
    }

  [super dealloc];
}

- (NSPanel *) createLaunchPanel
{
  if (!launchPanel)
    {
      [self _createLaunchPanel];
    }

  return launchPanel;
}

- (NSPanel *) launchPanel
{
  return launchPanel;
}

- (NSView *)componentView;
{
  if (!componentView)
    {
      [self _createComponentView];
    }

  return componentView;
}

- (void)setTooltips
{
  [runButton setShowTooltip:YES];
  [debugButton setShowTooltip:YES];
}

- (void)popupChanged:(id)sender
{
  switch ([sender indexOfSelectedItem])
  {
      case 0:
          debugTarget = DEBUG_DEFAULT_TARGET;
          break;
      case 1:
          debugTarget = DEBUG_DEBUG_TARGET;
          break;
      default:
          break;
  }
}

- (void)debug:(id)sender
{
  if ([[[[NSUserDefaults standardUserDefaults] dictionaryRepresentation]
              objectForKey:ExternalDebugger] isEqualToString: @"YES"])
  {
    NSString *dp = [currentProject projectName];
    NSString *fp = nil;
    NSString *pn = nil;
    NSString *gdbPath;
    NSArray  *args;
    NSTask   *task;
    NSDistantObject <Terminal>*terminal;
    
    /* Get the Terminal application */
    terminal = (NSDistantObject<Terminal> *)[NSConnection rootProxyForConnectionWithRegisteredName:@"Terminal" host:nil];

    /* Prepare tasks */
    switch( debugTarget )
    {
        case DEBUG_DEFAULT_TARGET:
	    pn = [dp stringByAppendingPathExtension:@"app"];
            break;
        case DEBUG_DEBUG_TARGET:
	    pn = [dp stringByAppendingPathExtension:@"debug"];
            break;
        default:
	    [NSException raise:@"PCInternalDevException" 
                        format:@"Unknown build target!"];
            break;
    }

    if( terminal == nil ) 
    {
      NSRunAlertPanel(@"Attention!", @"Terminal.app is not running! Please\nlaunch it before debugging %@", @"Abort",nil,nil,pn);
      [debugButton setState:NSOffState];
      return;
    }

    fp = [[NSFileManager defaultManager] currentDirectoryPath];
    dp = [fp stringByAppendingPathComponent:dp];
    fp = [dp stringByAppendingPathComponent:pn];

    task = [[NSTask alloc] init];
    [task setLaunchPath:fp];
    fp = [task validatedLaunchPath];
    RELEASE(task);

    if( fp == nil )
    {
      NSRunAlertPanel(@"Attention!", @"No executable found in %@!", @"Abort",nil,nil,dp);
      [debugButton setState:NSOffState];
      return;
    }

    task = [[NSTask alloc] init];

    dp = [[NSUserDefaults standardUserDefaults] objectForKey:PDebugger];
    if(dp == nil)
    {
      dp = [NSString stringWithString:@"/usr/bin/gdb"];
    }

    if([[NSFileManager defaultManager] isExecutableFileAtPath:dp] == NO)
    {
      NSRunAlertPanel(@"Attention!", @"Invalid debugger specified: %@!", @"Abort",nil,nil,dp);
      RELEASE(task);
      [debugButton setState:NSOffState];
      return;
    }

    [task setLaunchPath:dp];
    gdbPath = [task validatedLaunchPath];
    RELEASE(task);

    args = [NSArray arrayWithObjects:
                        gdbPath,
                        @"--args",
                        AUTORELEASE(fp),
                        nil];

    [terminal terminalRunProgram: AUTORELEASE(gdbPath)
                       withArguments: args
                         inDirectory: nil
                          properties: nil];
  }
  else
  {
    NSRunAlertPanel(@"Attention!",
                    @"Integrated debugging is not yet available...",
                    @"OK",nil,nil);
  }
  [debugButton setState:NSOffState];
}

- (void)run:(id)sender
{
  NSMutableArray *args;
  NSPipe *logPipe;
  NSPipe *errorPipe;
  NSString *openPath;

  logPipe = [NSPipe pipe];
  RELEASE(readHandle);
  readHandle = [[logPipe fileHandleForReading] retain];

  errorPipe = [NSPipe pipe];
  RELEASE(errorReadHandle);
  errorReadHandle = [[errorPipe fileHandleForReading] retain];

  RELEASE(launchTask);
  launchTask = [[NSTask alloc] init];

  args = [[NSMutableArray alloc] init];

  /*
   * Ugly hack! We should ask the porject itself about the req. information!
   *
   */

  if ([currentProject isKindOfClass:NSClassFromString(@"PCAppProject")] ||
      [currentProject isKindOfClass:NSClassFromString(@"PCRenaissanceProject")] ||
      [currentProject isKindOfClass:NSClassFromString(@"PCGormProject")]) 
  {
    NSString *tn = nil;
    NSString *pn = [currentProject projectName];

    openPath = [NSString stringWithString:@"openapp"];

    switch( debugTarget )
    {
        case DEBUG_DEFAULT_TARGET:
	    tn = [pn stringByAppendingPathExtension:@"app"];
            break;
        case DEBUG_DEBUG_TARGET:
	    tn = [pn stringByAppendingPathExtension:@"debug"];
            break;
        default:
	    [NSException raise:@"PCInternalDevException" 
                        format:@"Unknown build target!"];
            break;
    }
    [args addObject:tn];
  }
  else if ([currentProject isKindOfClass:NSClassFromString(@"PCToolProject")]) 
  {
    openPath = [NSString stringWithString:@"opentool"];
    [args addObject:[currentProject projectName]];
  }
  else 
  {
    [NSException raise:@"PCInternalDevException" 
                format:@"Unknown executable project type!"];
    return;
  }

  /*
   * Setting everything up
   */

  [NOTIFICATION_CENTER addObserver:self 
		       selector:@selector(logStdOut:) 
		       name:NSFileHandleDataAvailableNotification
		       object:readHandle];
  
  [NOTIFICATION_CENTER addObserver:self 
		       selector:@selector(logErrOut:) 
		       name:NSFileHandleDataAvailableNotification
		       object:errorReadHandle];

  [NOTIFICATION_CENTER addObserver:self
		       selector: @selector(buildDidTerminate:)
		       name: NSTaskDidTerminateNotification
		       object:launchTask];  
  
  [launchTask setArguments:args];  
  RELEASE(args);

  [launchTask setCurrentDirectoryPath:[currentProject projectPath]];
  [launchTask setLaunchPath:openPath];
  
  [launchTask setStandardOutput:logPipe];
  [launchTask setStandardError:errorPipe];

  [stdOut setString:@""];
  [readHandle waitForDataInBackgroundAndNotify];

  [stdOut setString:@""];
  [errorReadHandle waitForDataInBackgroundAndNotify];

  /*
   * Go! Later on this will be handled much more optimised!
   *
   */

  [launchTask launch];
}

- (void)buildDidTerminate:(NSNotification *)aNotif
{
  if ([aNotif object] == launchTask) {

    /*
     * Clean up...
     *
     */
    [NOTIFICATION_CENTER removeObserver:self 
			 name:NSFileHandleDataAvailableNotification
			 object:readHandle];
    
    [NOTIFICATION_CENTER removeObserver:self 
			 name:NSFileHandleDataAvailableNotification
			 object:errorReadHandle];

    [NOTIFICATION_CENTER removeObserver:self 
			 name:NSTaskDidTerminateNotification 
			 object:launchTask];

    RELEASE(launchTask);
    launchTask = nil;

    [runButton setState:NSOffState];
    [componentView display];
  }
}

- (void)logStdOut:(NSNotification *)aNotif
{
  NSData *data;

  if ((data = [readHandle availableData]))
    {
      [self logData:data error:NO];
    }

  [readHandle waitForDataInBackgroundAndNotifyForModes:nil];
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

@end

@implementation PCProjectDebugger (BuildLogging)

- (void)logString:(NSString *)str newLine:(BOOL)newLine
{
  [stdOut replaceCharactersInRange:NSMakeRange([[stdOut string] length],0) 
       withString:str];

  if (newLine) {
    [stdOut replaceCharactersInRange:NSMakeRange([[stdOut string] length], 0) 
	 withString:@"\n"];
  }
  else {
    [stdOut replaceCharactersInRange:NSMakeRange([[stdOut string] length], 0) 
	 withString:@" "];
  }
  
  [stdOut scrollRangeToVisible:NSMakeRange([[stdOut string] length], 0)];
}

- (void)logData:(NSData *)data error:(BOOL)yn
{
  NSString *s = nil;
  NSAttributedString *as = nil;

//  [self logString:s newLine:NO];
  s = [[NSString alloc] initWithData:data
                            encoding:[NSString defaultCStringEncoding]];
  as = [[NSAttributedString alloc] initWithString:s
                                       attributes:textAttributes];
  [[stdOut textStorage] appendAttributedString: as];
  [stdOut scrollRangeToVisible:NSMakeRange([[stdOut string] length], 0)];

  [s release];
  [as release];
}

@end
