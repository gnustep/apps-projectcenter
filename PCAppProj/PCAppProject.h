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

/*
 Description:

 This is the project type 'Application' for GNUstep. You never should create 
 it yourself but use PCAppProj for doing this. Otherwise needed files don't 
 get copied to the right place.

 */

#import <AppKit/AppKit.h>
#import <ProjectCenter/PCProject.h>

@interface PCAppProject : PCProject
{
  NSTextField *appClassField;
  NSTextField *appImageField;
  NSButton *setAppIconButton;
  NSImageView *appIconView;
  NSImage *icon;
}

//----------------------------------------------------------------------------
// Init and free
//----------------------------------------------------------------------------

- (id)init;
- (void)dealloc;

//----------------------------------------------------------------------------
// Project
//----------------------------------------------------------------------------

- (BOOL)writeMakefile;

- (BOOL)isValidDictionary:(NSDictionary *)aDict;

- (NSArray *)sourceFileKeys;
- (NSArray *)resourceFileKeys;
- (NSArray *)otherKeys;
- (NSArray *)buildTargets;
- (NSString *)projectDescription;

- (BOOL)isExecutable;

- (void)updateValuesFromProjectDict;

@end
