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

   This is the project type 'Application' for GNUstep. You never should create 
   it yourself but use PCAppProj for doing this. Otherwise needed files don't 
   get copied to the right place.
 */
 
#ifndef _PCAppProj_PCAppProject_h_
#define _PCAppProj_PCAppProject_h_

#include <AppKit/AppKit.h>
#include <ProjectCenter/PCProject.h>
#include <ProjectCenter/PCProjectInspector.h>

@interface PCAppTextField : NSTextField
{
}

@end

@interface PCAppProject : PCProject
{
  IBOutlet NSBox          *projectAttributesView;
  IBOutlet NSTextField    *projectTypeField;
  IBOutlet NSTextField    *projectNameField;
  IBOutlet NSTextField    *projectLanguageField;
  IBOutlet NSTextField    *appClassField;

  PCAppTextField          *activeTextField;
  IBOutlet PCAppTextField *appImageField;
  IBOutlet PCAppTextField *helpFileField;
  IBOutlet PCAppTextField *mainNIBField;

  IBOutlet NSImageView    *iconView;
  NSImage                 *icon;
  IBOutlet NSButton       *setFieldButton;
  IBOutlet NSButton       *clearFieldButton;

  NSTableView             *docIconsList;
  NSTableColumn           *docExtColumn;
  NSTableColumn           *docIconColumn;
  NSMutableArray          *docIconsItems;
  IBOutlet NSScrollView   *docIconsScroll;

  IBOutlet NSButton       *addDocIcon;
  IBOutlet NSButton       *removeDocIcon;
               
  NSMutableDictionary *infoDict;
}

// ----------------------------------------------------------------------------
// --- Init and free
// ----------------------------------------------------------------------------

- (id)init;
- (void)assignInfoDict:(NSMutableDictionary *)dict;
- (void)loadInfoFileAtPath:(NSString *)path;
- (void)dealloc;

@end

@interface PCAppProject (GeneratedFiles)

- (void)writeInfoEntry:(NSString *)name forKey:(NSString *)key;
- (BOOL)writeInfoFile;
- (NSArray *)convertExtensions;
- (BOOL)writeMakefile;
- (void)appendHead:(PCMakefileFactory *)mff;
- (void)appendApplication:(PCMakefileFactory *)mff;
- (void)appendTail:(PCMakefileFactory *)mff;

@end

#endif
