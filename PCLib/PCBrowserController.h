/*
   GNUstep ProjectCenter - http://www.projectcenter.ch

   Copyright (C) 2000 Philippe C.D. Robert

   Author: Philippe C.D. Robert <phr@projectcenter.ch>

   This file is part of ProjectCenter.

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

#import <AppKit/AppKit.h>

@class PCProject;

@interface PCBrowserController : NSObject
{
  id browser;
  PCProject *project;
}

- (void)dealloc;

- (void)click:(id)sender;
- (void)doubleClick:(id)sender;

- (void)projectDictDidChange:(NSNotification *)aNotif;

- (NSString *)nameOfSelectedFile;
- (NSString *)pathOfSelectedFile;

- (void)setBrowser:(NSBrowser *)aBrowser;
- (void)setProject:(PCProject *)aProj;

@end

@interface PCBrowserController (ProjectBrowserDelegate)

- (void)browser:(NSBrowser *)sender createRowsForColumn:(int)column inMatrix:(NSMatrix *)matrix;
- (void)browser:(NSBrowser *)sender willDisplayCell:(id)cell atRow:(int)row column:(int)column;
- (BOOL)browser:(NSBrowser *)sender selectCellWithString:(NSString *)title inColumn:(int)column;

@end

extern NSString *FileShouldOpenNotification;

