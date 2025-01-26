/*
   GNUstep ProjectCenter - http://www.gnustep.org/experience/ProjectCenter.html

   Copyright (C) 2004 Free Software Foundation

   Authors: Serg Stoyan

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

#ifndef _PCAddFilesPanel_h_
#define _PCAddFilesPanel_h_

//#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>

@interface PCAddFilesPanel : NSOpenPanel
{
  NSBox	        *fileTypeAccessaryView;
  NSPopUpButton *fileTypePopup;
}

+ (PCAddFilesPanel *)addFilesPanel;

- (void)setCategories:(NSArray *)categories;
- (void)selectCategory:(NSString *)category;
- (NSString *)selectedCategory;
- (void)setFileTypes:(NSArray *)fileTypes;

- (void)filesForAddPopupClicked:(id)sender;

@end

@interface NSObject (PCAddFilesPanelDelegate)

- (void)categoryChangedTo:(NSString *)category;

@end

#endif
