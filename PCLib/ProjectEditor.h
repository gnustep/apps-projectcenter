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

 A ProjectEditor is used to create an editor that will work together with PC.
 Every such editor must conform to this protocol!

 With this approach this procedure can be implemented as a bundle and
 therefore PC remains open for future extensions!
*/

#import <Foundation/Foundation.h>

@protocol ProjectEditor

- (void)openFile:(NSString *)path;
- (void)saveFile:(NSString *)path;
- (void)closeFile:(NSString *)path;
- (void)revertFile:(NSString *)path;

@end

@interface NSObject (EditorDelegates)

- (void)editor:(id<ProjectEditor>)editor didOpenFile:(NSString *)path;
- (void)editor:(id<ProjectEditor>)editor didModifyFile:(NSString *)path;
- (void)editor:(id<ProjectEditor>)editor didSaveFile:(NSString *)path;
- (void)editor:(id<ProjectEditor>)editor didCloseFile:(NSString *)path;
- (void)editorWillTerminate:(id<ProjectEditor>)editor;

@end
