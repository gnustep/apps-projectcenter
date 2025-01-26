/*
   GNUstep ProjectCenter - http://www.gnustep.org/experience/ProjectCenter.html

   Copyright (C) 2003-2004 Free Software Foundation

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

#ifndef _PCLoadedFilesPanel_h_
#define _PCLoadedFilesPanel_h_

#import <AppKit/AppKit.h>

@class PCProjectManager;

@interface PCProjectLoadedFilesPanel : NSPanel
{
  PCProjectManager *projectManager;
  PCProject        *currentProject;
  NSBox            *contentBox;
  NSBox            *emptyBox;
}

- (id)initWithProjectManager:(PCProjectManager *)aManager;

@end

#endif
