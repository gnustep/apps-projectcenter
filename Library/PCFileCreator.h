/*
   GNUstep ProjectCenter - http://www.gnustep.org

   Copyright (C) 2001-2004 Free Software Foundation

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

#ifndef _PCFileCreator_h
#define _PCFileCreator_h

#include <AppKit/AppKit.h>

#define ProtocolFile	@"Objective-C Protocol"
#define ObjCClass	@"Objective-C Class"
#define ObjCHeader	@"Objective-C Header"
#define CFile		@"C File"
#define CHeader	        @"C Header"
#define GSMarkupFile	@"GNUstep Markup"

@class PCProject;

@interface PCFileCreator : NSObject
{
  NSMutableString *file;
}

+ (id)sharedCreator;

- (NSString *)name;
- (NSDictionary *)creatorDictionary;

// The implementation needs some heavy cleanup!
- (NSDictionary *)createFileOfType:(NSString *)type
                              path:(NSString *)path
			   project:(PCProject *)aProject;

- (void)replaceTagsInFileAtPath:(NSString *)newFile
                    withProject:(PCProject *)aProject;

@end

#endif
