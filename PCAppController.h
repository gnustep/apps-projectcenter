/*
   GNUstep ProjectCenter - http://www.gnustep.org

   Copyright (C) 2001 Free Software Foundation

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
*/

#ifndef _PCAPPCONTROLLER_H
#define _PCAPPCONTROLLER_H

#include <AppKit/AppKit.h>

#include "PCPrefController.h"
#include "PCFindController.h"
#include "PCInfoController.h"
#include "PCLogController.h"

@class PCServer;
@class PCProjectManager;
@class PCFileManager;
@class PCMenuController;

@interface PCAppController : NSObject
{
  PCInfoController *infoController;
  PCPrefController *prefController;
  PCFindController *finder;
  PCLogController  *logger;

  PCProjectManager *projectManager;
  PCMenuController *menuController;
  
  PCServer         *doServer;
  NSConnection     *doConnection;
  
  id		   delegate;
}

//============================================================================
//==== Intialization & deallocation
//============================================================================

+ (void)initialize;

- (id)init;
- (void)dealloc;

- (BOOL)respondsToSelector:(SEL)aSelector; 
- (void)forwardInvocation:(NSInvocation *)anInvocation;
- (NSMethodSignature *)methodSignatureForSelector:(SEL)aSelector;

//============================================================================
//==== Delegate
//============================================================================

- (id)delegate;
- (void)setDelegate:(id)aDelegate;

//============================================================================
//==== Accessory methods
//============================================================================

- (PCProjectManager *)projectManager;
- (PCInfoController *)infoController;
- (PCPrefController *)prefController;
- (PCMenuController *)menuController;
- (PCServer *)doServer;
- (PCFindController *)finder;
- (PCLogController *)logger;

//============================================================================
//==== Application
//============================================================================

- (BOOL)application:(NSApplication *)application openFile:(NSString *)fileName;

- (void)applicationWillFinishLaunching:(NSNotification *)notification;
- (void)applicationDidFinishLaunching:(NSNotification *)notification;

- (BOOL)applicationShouldTerminate:(id)sender;
- (void)applicationWillTerminate:(NSNotification *)notification;

@end

#endif
