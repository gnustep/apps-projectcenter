/*
   GNUstep ProjectCenter - http://www.gnustep.org/experience/ProjectCenter.html

   Copyright (C) 2026 Free Software Foundation

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
   Software Foundation, Inc., 31 Milk Street #960789 Boston, MA 02196 USA.
*/

#import <AppKit/AppKit.h>

#import "PCAppController.h"

@interface PCProjectDocument : NSDocument
{
}
@end

@implementation PCProjectDocument

- (BOOL)_openProjectURL:(NSURL *)url
{
  id appDelegate = [NSApp delegate];

  if (![url isFileURL]
      || ![appDelegate respondsToSelector:@selector(application:openFile:)])
    {
      return NO;
    }

  return [appDelegate application:NSApp openFile:[url path]];
}

- (BOOL)readFromURL:(NSURL *)url ofType:(NSString *)type
{
  return [self _openProjectURL:url];
}

- (BOOL)readFromFile:(NSString *)fileName ofType:(NSString *)type
{
  return [self _openProjectURL:[NSURL fileURLWithPath:fileName]];
}

- (void)makeWindowControllers
{
}

- (void)showWindows
{
  NSURL *url = nil;

  if ([self respondsToSelector:@selector(fileURL)])
    {
      url = [self fileURL];
    }
  if (url == nil && [self fileName] != nil)
    {
      url = [NSURL fileURLWithPath:[self fileName]];
    }

  if (url != nil)
    {
      [self _openProjectURL:url];
    }
}

@end
