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

   $Id$
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

@interface PCAppProject : PCProject
{
  NSBox          *buildAttributesView;
  NSTextField    *projectNameLabel;
  NSPopUpButton  *searchOrderPopup;
  NSTableView    *searchOrderList;
  NSTableColumn  *searchOrderColumn;
  NSScrollView   *searchOrderScroll;
  NSMutableArray *searchItems;
  NSArray        *searchHeaders;
  NSArray        *searchLibs;
  NSTextField    *searchOrderTF;
  NSButton       *searchOrderSet;
  NSButton       *searchOrderRemove;
  NSButton       *searchOrderAdd;
  NSTextField    *cppOptField;
  NSTextField    *objcOptField;
  NSTextField    *cOptField;
  NSTextField    *ldOptField;
  NSTextField    *installPathField;
  NSTextField    *toolField;
               
  NSBox          *projectAttributesView;
  NSTextField    *projectTypeField;
  NSTextField    *projectNameField;
  NSTextField    *projectLanguageField;
  NSTextField    *appClassField;
  NSTextField    *appImageField;
  NSTextField    *helpFileField;
  NSTextField    *mainNIBField;
  NSButton       *setAppIconButton;
  NSButton       *clearAppIconButton;
  NSImageView    *iconView;
  NSImage        *icon;
               
  NSBox          *fileAttributesView;
  NSImageView    *fileIconView;
  NSTextField    *fileNameField;

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

- (BOOL)writeInfoFile;
- (BOOL)writeMakefile;
- (void)appendHead:(PCMakefileFactory *)mff;
- (void)appendApplication:(PCMakefileFactory *)mff;
- (void)appendTail:(PCMakefileFactory *)mff;
- (BOOL)writeMakefilePreamble;

@end

#endif
