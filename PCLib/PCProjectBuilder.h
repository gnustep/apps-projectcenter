/*
   GNUstep ProjectCenter - http://www.projectcenter.ch

   Copyright (C) 2000 Philippe C.D. Robert

   Author: Philippe C.D. Robert <phr@projectcenter.ch>

   This file is part of ProjectCenter.

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

#import <Foundation/Foundation.h>

@class PCProject;

@class NSWindow;
@class NSTextView;

@interface PCProjectBuilder : NSObject
{
  NSWindow *buildWindow;

  NSTextView *logOutput;
  NSTextView *errorOutput;

  NSMutableDictionary *buildTasks;
  NSString *makePath;

  id buildStatusField;
  id targetField;

  PCProject *currentProject;
  NSDictionary *currentOptions;

  NSFileHandle *readHandle;
  NSFileHandle *errorReadHandle;
}

+ (id)sharedBuilder;

- (id)init;
- (void)dealloc;

- (void)showPanelWithProject:(PCProject *)proj options:(NSDictionary *)options;

- (void)build:(id)sender;

- (void)logStdOut:(NSNotification *)aNotif;
- (void)logErrOut:(NSNotification *)aNotif;

- (void)buildDidTerminate:(NSNotification *)aNotif;

- (void)projectDidChange:(NSNotification *)aNotif;

@end

@interface PCProjectBuilder (BuildLogging)

- (void)logString:(NSString *)string error:(BOOL)yn;
- (void)logString:(NSString *)string error:(BOOL)yn newLine:(BOOL)newLine;
- (void)logData:(NSData *)data error:(BOOL)yn;

@end




