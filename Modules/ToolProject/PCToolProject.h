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
*/

/*
   Description:

   This is the project type 'Tool' for GNUstep. You never should create 
   it yourself but use PCToolProj for doing this. Otherwise needed files don't 
   get copied to the right place.
*/
 
#ifndef _PCTOOLPROJECT_H
#define _PCTOOLPROJECT_H

#include <AppKit/AppKit.h>
#include <ProjectCenter/PCProject.h>

@class PCMakefileFactory;

@interface PCToolProject : PCProject
{
  IBOutlet NSBox       *projectAttributesView;
  IBOutlet NSTextField *projectTypeField;
  IBOutlet NSTextField *projectNameField;
  IBOutlet NSTextField *projectLanguageField;

  NSMutableDictionary  *infoDict;
}

//----------------------------------------------------------------------------
// Init and free
//----------------------------------------------------------------------------

- (id)init;
- (void)assignInfoDict:(NSMutableDictionary *)dict;
- (void)loadInfoFileAtPath:(NSString *)path;
- (void)dealloc;

@end

@interface PCToolProject (GeneratedFiles)

- (void)writeInfoEntry:(NSString *)name forKey:(NSString *)key;
- (BOOL)writeInfoFile;

- (BOOL)writeMakefile;
- (void)appendHead:(PCMakefileFactory *)mff;
- (void)appendLibraries:(PCMakefileFactory*)mff;
- (void)appendTail:(PCMakefileFactory *)mff;

@end

@interface PCToolProject (Inspector)

- (NSView *)projectAttributesView;
- (void)updateInspectorValues:(NSNotification *)aNotif;

@end

#endif
