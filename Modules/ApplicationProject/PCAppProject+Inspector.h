/*
   GNUstep ProjectCenter - http://www.gnustep.org

   Copyright (C) 2001 Free Software Foundation

   Author: Serg Stoyan <stoyan@on.com.ua>

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

#ifndef _PCAppProject_Inspector_h_
#define _PCAppProject_Inspector_h_

#include "PCAppProject.h"

@interface PCAppProject (Inspector)

// ----------------------------------------------------------------------------
// --- User Interface
// ----------------------------------------------------------------------------

- (void)createBuildAttributes;
- (void)createProjectAttributes;
- (void)createFileAttributes;
- (NSView *)buildAttributesView;
- (NSView *)projectAttributesView;
- (NSView *)fileAttributesView;
- (void)setAppClass:(id)sender;
- (void)setAppIcon:(id)sender;
- (BOOL)setAppIconWithImageAtPath:(NSString *)path;
- (void)clearAppIcon:(id)sender;
- (void)setMainNib:(id)sender;
- (BOOL)setMainNibWithFileAtPath:(NSString *)path;
- (void)clearMainNib:(id)sender;

// ----------------------------------------------------------------------------
// --- Actions
// ----------------------------------------------------------------------------

- (void)changeCommonProjectEntry:(id)sender;
- (void)setAppClass:(id)sender;
- (void)setFile:(id)sender;
- (void)clearFile:(id)sender;
- (BOOL)setAppIconWithImageAtPath:(NSString *)path;
- (void)setMainNib:(id)sender;
- (BOOL)setMainNibWithFileAtPath:(NSString *)path;
- (void)clearMainNib:(id)sender;

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

- (int)numberOfRowsInTableView:(NSTableView *)aTableView;
- (id)            tableView: (NSTableView *)aTableView
  objectValueForTableColumn: (NSTableColumn *)aTableColumn
                        row: (int)rowIndex;
- (void) tableView:(NSTableView *)aTableView
    setObjectValue:anObject
    forTableColumn:(NSTableColumn *)aTableColumn
               row:(int)rowIndex;

// ----------------------------------------------------------------------------
// --- Notifications
// ----------------------------------------------------------------------------

- (void)updateInspectorValues:(NSNotification *)aNotif;
- (void)browserDidSetPath:(NSNotification *)aNotif;

@end

#endif
