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

#include <Foundation/Foundation.h>

@class PCProject;

@protocol FileCreator

+ (id)sharedCreator;

- (NSString *)name;
- (NSDictionary *)creatorDictionary;
    // Object is the creator and key is the type of the file to be created

- (NSDictionary *)createFileOfType:(NSString *)type path:(NSString *)path project:(PCProject *)aProject;
    // Creates the file and returns a dictionary containing the full path of it as the key and the type as object (and perhaps other files that have been added during this process!); including path extensions etc!

@end


