/*
   GNUstep ProjectCenter - http://www.gnustep.org

   Copyright (C) 2003 Free Software Foundation

   Author: Philippe C.D. Robert <phr@3dkit.org>
   Modified by Daniel Luederwald <das_flip@gmx.de>

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

/*
 Description:

 This is the project type 'RenaissanceApplication' for GNUstep. You never should create 
 it yourself but use PCRenaissanceProj for doing this. Otherwise needed files don't 
 get copied to the right place.

 */
 
#ifndef _PCRENAISSANCEPROJECT_H
#define _PCRENAISSANCEPROJECT_H

#include <AppKit/AppKit.h>
#include <ProjectCenter/PCProject.h>

@interface PCRenaissanceProject : PCProject
{
  NSTextField *appClassField;
  NSTextField *appImageField;
  NSButton *setAppIconButton;
  NSButton *clearAppIconButton;
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

- (Class)builderClass;

- (BOOL)writeMakefile;

- (NSArray *)sourceFileKeys;
- (NSArray *)resourceFileKeys;
- (NSArray *)otherKeys;
- (NSArray *)buildTargets;
- (NSString *)projectDescription;

- (BOOL)isExecutable;

- (void)updateValuesFromProjectDict;

- (void)clearAppIcon:(id)sender;
- (void)setAppIcon:(id)sender;

- (BOOL)setAppIconWithImageAtPath:(NSString *)path;

- (void)setAppClass:(id)sender;

@end

#endif
