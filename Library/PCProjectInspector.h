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
*/

#ifndef _PCProjectInspector_h_
#define _PCProjectInspector_h_

@class PCProjectManager;
@class PCProjectBrowser;

@interface PCProjectInspector : NSObject
{
  PCProjectManager *projectManager;
  PCProject        *project;
  NSDictionary     *projectDict;

  NSPanel          *inspectorPanel;
  NSBox            *contentView;
  NSPopUpButton    *inspectorPopup;
  NSBox            *hLine;
  NSBox            *inspectorView;

  // Build Attributes
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

  // Project Attributes
  // Suuplied by concrete project
  NSView           *projectAttributesView;

  // Project Description
  NSBox          *projectDescriptionView;
  NSTextField    *descriptionField;
  NSTextField    *releaseField;
  NSTextField    *licenseField;
  NSTextField    *licDescriptionField;
  NSTextField    *urlField;
  NSBox          *authorsBox;
  NSTableView    *authorsList;
  NSTableColumn  *authorsColumn;
  NSScrollView   *authorsScroll;
  NSMutableArray *authorsItems;
  NSButton       *authorAdd;
  NSButton       *authorRemove;
  NSButton       *authorUp;
  NSButton       *authorDown;

  // File Attributes
  NSBox          *fileAttributesView;
  NSImageView    *fileIconView;
  NSTextField    *fileNameField;
}

// ============================================================================
// ==== Intialization & deallocation
// ============================================================================
- (void)_initUI;
- (id)initWithProjectManager:(PCProjectManager *)manager;
- (void)close;
- (void)dealloc;

// ============================================================================
// ==== Panel and contents
// ============================================================================
- (NSPanel *)panel;
- (NSView *)contentView;

// ============================================================================
// ==== Actions
// ============================================================================
- (void)inspectorPopupDidChange:(id)sender;
- (void)changeCommonProjectEntry:(id)sender;

// ============================================================================
// ==== Notifications
// ============================================================================
- (void)activeProjectDidChange:(NSNotification *)aNotif;
- (void)updateValues:(NSNotification *)aNotif;

// ============================================================================
// ==== Build Attributes
// ============================================================================
- (void)createBuildAttributes;

// ----------------------------------------------------------------------------
// --- Search Order
// ----------------------------------------------------------------------------
- (void)searchOrderPopupDidChange:(id)sender;
- (void)searchOrderDoubleClick:(id)sender;
- (void)searchOrderClick:(id)sender;
- (void)setSearchOrderButtonsState;
- (void)setSearchOrder:(id)sender;
- (void)removeSearchOrder:(id)sender;
- (void)addSearchOrder:(id)sender;
- (void)syncSearchOrder;

// ============================================================================
// ==== Project Description
// ============================================================================
- (void)createProjectDescription;

// ============================================================================
// ==== File Attributes
// ============================================================================
- (void)createFileAttributes;

- (void)browserDidSetPath:(NSNotification *)aNotif;

- (void)setFANameAndIcon:(PCProjectBrowser *)browser;

@end

#endif
