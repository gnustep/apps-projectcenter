/*
   GNUstep ProjectCenter - http://www.gnustep.org/experience/ProjectCenter.html

   Copyright (C) 2002-2004 Free Software Foundation

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

#ifndef _PCProjectEditorProtocol_h_
#define _PCProjectEditorProtocol_h_

#include <Foundation/Foundation.h>

@protocol CodeParser;

@protocol ProjectEditor

// ===========================================================================
// ==== File handling
// ===========================================================================

- (BOOL)saveEditedFiles:(NSArray *)files;
- (BOOL)saveAllFiles;
- (BOOL)saveFile;
- (BOOL)saveFileAs:(NSString *)file;
- (BOOL)saveFileTo:(NSString *)file;
- (BOOL)revertFileToSaved;

@end

extern NSString *PCEditorDidChangeFileNameNotification;

extern NSString *PCEditorWillOpenNotification;
extern NSString *PCEditorDidOpenNotification;
extern NSString *PCEditorDidCloseNotification;

extern NSString *PCEditorDidBecomeActiveNotification;
extern NSString *PCEditorDidResignActiveNotification;

/*extern NSString *PCEditorDidChangeNotification;
extern NSString *PCEditorWillSaveNotification;
extern NSString *PCEditorDidSaveNotification;
extern NSString *PCEditorSaveDidFailNotification;
extern NSString *PCEditorWillRevertNotification;
extern NSString *PCEditorDidRevertNotification;
extern NSString *PCEditorDeletedNotification;
extern NSString *PCEditorRenamedNotification;*/

#endif 

