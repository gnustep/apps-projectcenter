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

   $Id$
*/

#ifndef _PCPROJECTBUILDER_H
#define _PCPROJECTBUILDER_H

#import <AppKit/AppKit.h>

#ifndef GNUSTEP_BASE_VERSION
@protocol ProjectComponent;
#else
#import <ProjectCenter/ProjectComponent.h>
#endif

@class PCProject;

@interface PCProjectBuilder : NSObject <ProjectComponent>
{
  NSBox *componentView;
  NSPopUpButton *popup;

  NSTextView *logOutput;
  NSTextView *errorOutput;

  NSString *makePath;

  id buildStatusField;
  id targetField;

  PCProject *currentProject;
  NSDictionary *currentOptions;

  NSFileHandle *readHandle;
  NSFileHandle *errorReadHandle;
}

- (id)initWithProject:(PCProject *)aProject;
- (void)dealloc;

- (NSView *)componentView;

- (void)build:(id)sender;
- (void)popupChanged:(id)sender;

- (void)logStdOut:(NSNotification *)aNotif;
- (void)logErrOut:(NSNotification *)aNotif;

- (void)buildDidTerminate:(NSNotification *)aNotif;

- (void)copyPackageTo:(NSString *)path;

@end

@interface PCProjectBuilder (BuildLogging)

- (void)logString:(NSString *)string error:(BOOL)yn;
- (void)logString:(NSString *)string error:(BOOL)yn newLine:(BOOL)newLine;
- (void)logData:(NSData *)data error:(BOOL)yn;

@end

#endif
