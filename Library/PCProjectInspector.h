/*
   GNUstep ProjectCenter - http://www.gnustep.org

   Copyright (C) 2000-2004 Free Software Foundation

   Authors: Philippe C.D. Robert
            Serg Stoyan

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

@interface PCFileNameField : NSTextField
{
}

- (void)setEditableField:(BOOL)yn;
- (BOOL)textShouldSetEditable;

@end

@interface PCProjectInspector : NSObject
{
  PCProjectManager *projectManager;
  PCProject        *project;
  NSDictionary     *projectDict;

  IBOutlet NSPanel       *inspectorPanel;
  IBOutlet NSBox         *contentView;
  IBOutlet NSPopUpButton *inspectorPopup;
  IBOutlet NSBox         *inspectorView;

  // Build Attributes
  IBOutlet NSBox          *buildAttributesView;
  IBOutlet NSTextField    *projectNameLabel;
  IBOutlet NSPopUpButton  *searchOrderPopup;
  IBOutlet NSScrollView   *searchOrderScroll;
  NSTableView             *searchOrderList;
  NSTableColumn           *searchOrderColumn;
  NSMutableArray          *searchItems;
  NSArray                 *searchHeaders;
  NSArray                 *searchLibs;
  IBOutlet NSTextField    *searchOrderTF;
  IBOutlet NSButton       *searchOrderSet;
  IBOutlet NSButton       *searchOrderRemove;
  IBOutlet NSButton       *searchOrderAdd;
  IBOutlet NSTextField    *cppOptField;
  IBOutlet NSTextField    *objcOptField;
  IBOutlet NSTextField    *cOptField;
  IBOutlet NSTextField    *ldOptField;
  IBOutlet NSTextField    *installPathField;
  IBOutlet NSTextField    *toolField;

  // Project Attributes
  // Suuplied by concrete project
  NSView           *projectAttributesView;

  // Project Description
  IBOutlet NSBox          *projectDescriptionView;
  IBOutlet NSTextField    *descriptionField;
  IBOutlet NSTextField    *releaseField;
  IBOutlet NSTextField    *licenseField;
  IBOutlet NSTextField    *licDescriptionField;
  IBOutlet NSTextField    *urlField;
  NSTableView    *authorsList;
  NSTableColumn  *authorsColumn;
  IBOutlet NSScrollView   *authorsScroll;
  NSMutableArray *authorsItems;
  IBOutlet NSButton       *authorAdd;
  IBOutlet NSButton       *authorRemove;
  IBOutlet NSButton       *authorUp;
  IBOutlet NSButton       *authorDown;

  // File Attributes
  IBOutlet NSBox           *fileAttributesView;
  IBOutlet NSImageView     *fileIconView;
  IBOutlet PCFileNameField *fileNameField;
  NSString                 *fileName;
}

// ============================================================================
// ==== Intialization & deallocation
// ============================================================================
- (id)initWithProjectManager:(PCProjectManager *)manager;
- (void)close;
- (void)dealloc;

// ============================================================================
// ==== Panel and contents
// ============================================================================
- (BOOL)loadPanel;
- (NSPanel *)panel;
- (NSView *)contentView;

// ============================================================================
// ==== Actions
// ============================================================================
- (void)inspectorPopupDidChange:(id)sender;
- (void)changeCommonProjectEntry:(id)sender;
- (void)selectSectionWithTitle:(NSString *)sectionTitle;

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

- (void)beginFileRename;
- (void)browserDidSetPath:(NSNotification *)aNotif;
- (void)setFANameAndIcon:(PCProjectBrowser *)browser;

@end

#endif
