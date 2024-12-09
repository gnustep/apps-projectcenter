/*
   GNUstep ProjectCenter - http://www.gnustep.org/experience/ProjectCenter.html

   Copyright (C) 2004-2021 Free Software Foundation

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

#import <ProjectCenter/PCLogController.h>
#import <ProjectCenter/PCNewProjectFromSourcesPanel.h>

static PCNewProjectFromSourcesPanel *newProjectPanel = nil;

// dlsa - addFromSources
@implementation PCNewProjectFromSourcesPanel

+ (PCNewProjectFromSourcesPanel *)addProjectPanel
{
  if (newProjectPanel == nil)
    {
      newProjectPanel = [[self alloc] init];
    }

  return newProjectPanel;
}

// --- "Add Project..." panel
- (id)init
{
  NSRect fr;

  self = [super init];

  fr = NSMakeRect(20,30,160,21);

  // Panel
  [self setAllowsMultipleSelection:YES];

  return self;
}

- (void)setAccessaryView: (NSView*)view
{
  projectTypeAccessaryView = view;
}

- (void)setCategories:(NSArray *)categories
{
  [projectTypePopup removeAllItems];
  [projectTypePopup addItemsWithTitles:categories];
}

- (void)selectCategory:(NSString *)category
{
  [self setAccessoryView:projectTypeAccessaryView];
  [projectTypePopup selectItemWithTitle:category];
  [self projectTypesForAddPopupClicked:self];
}

- (NSString *)selectedCategory
{
  return [projectTypePopup titleOfSelectedItem];
}

- (void)setFileTypes:(NSArray *)fileTypes
{
  NSString  *path = nil;

  [super setAllowedFileTypes: fileTypes];

  path = [_browser path];
  [self validateVisibleColumns];
  [_browser setPath:path];

  [self display];
}

- (void)projectTypesForAddPopupClicked:(id)sender
{
  NSString  *category = [projectTypePopup titleOfSelectedItem];

  if ([[self delegate] respondsToSelector:@selector(categoryChangedTo:)])
    {
      [[self delegate] categoryChangedTo:category];
    }
}


@end
