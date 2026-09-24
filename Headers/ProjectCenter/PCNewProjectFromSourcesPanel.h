/*
   GNUstep ProjectCenter - http://www.gnustep.org/experience/ProjectCenter.html

   Copyright (C) 2021 Free Software Foundation

   Authors: Daniel Santos

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

#ifndef _PCNewProjectFromSourcesPanel_h_
#define _PCNewProjectFromSourcesPanel_h_

#import <AppKit/AppKit.h>

// dlsa - addFromSources
@interface PCNewProjectFromSourcesPanel : NSOpenPanel
{
  NSView	*projectTypeAccessaryView;
  NSPopUpButton *projectTypePopup;
}

+ (PCNewProjectFromSourcesPanel *)addProjectPanel;

- (void)setAccessaryView: (NSView*)view;
- (void)setCategories:(NSArray *)categories;
- (void)selectCategory:(NSString *)category;
- (NSString *)selectedCategory;
- (void)setFileTypes:(NSArray *)projectTypes;

- (void)projectTypesForAddPopupClicked:(id)sender;

@end

@interface NSObject (PCNewProjectFromSourcesPanelDelegate)

- (void)categoryChangedTo:(NSString *)category;

@end

#endif
