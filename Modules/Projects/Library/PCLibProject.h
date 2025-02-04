/*
   GNUstep ProjectCenter - http://www.gnustep.org/experience/ProjectCenter.html

   Copyright (C) 2001-2004 Free Software Foundation

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
   Software Foundation, Inc., 31 Milk Street #960789 Boston, MA 02196 USA.
*/

#ifndef _PCLibProject_h
#define _PCLibProject_h

#import <AppKit/AppKit.h>
#import <ProjectCenter/PCDefines.h>
#import <ProjectCenter/PCProject.h>
#import <Protocols/ProjectType.h>
// dlsa - create from sources
#import <ProjectCenter/PCProjectManager.h>

@class PCMakefileFactory;

@interface PCLibProject : PCProject <ProjectType>
{
  IBOutlet NSBox *projectAttributesView;
}

//----------------------------------------------------------------------------
// Init and free
//----------------------------------------------------------------------------

- (id)init;

- (PCProject *)createProjectAt:(NSString *)path;
// dlsa - addFromSources
- (PCProject *)createProjectFromSourcesAt: (NSString *)path withOption: (NSString *)projOption;

@end

@interface PCLibProject (GeneratedFiles)

- (BOOL)writeMakefile;
- (void)appendHead:(PCMakefileFactory *)mff;
- (void)appendPublicHeaders:(PCMakefileFactory *)mff;
- (void)appendTail:(PCMakefileFactory *)mff;

@end

@interface PCLibProject (Inspector)

- (NSView *)projectAttributesView;
- (void)updateInspectorValues:(NSNotification *)aNotif;

@end


#endif
