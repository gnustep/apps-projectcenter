/*
   GNUstep ProjectCenter - http://www.gnustep.org

   Copyright (C) 2001-2004 Free Software Foundation

   Authors: Philippe C.D. Robert
            Serg Stoyan
	    
   Description: This is the project type 'Bundle' for GNUstep. You never 
                should create it yourself but use PCBundleProj for doing this. 
		Otherwise needed files don't get copied to the right place.

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

#ifndef _PCBUNDLEPROJECT_H
#define _PCBUNDLEPROJECT_H

#include <AppKit/AppKit.h>
#include <ProjectCenter/PCProject.h>

@class PCMakefileFactory;

@interface PCBundleProject : PCProject
{
  IBOutlet NSBox       *projectAttributesView;
  IBOutlet NSTextField *projectTypeField;
  IBOutlet NSTextField *projectNameField;
  IBOutlet NSTextField *projectLanguageField;
  IBOutlet NSTextField *principalClassField;
  IBOutlet NSTextField *bundleExtensionField;
}

//----------------------------------------------------------------------------
// Init and free
//----------------------------------------------------------------------------

- (id)init;
- (void)dealloc;

@end

@interface PCBundleProject (GeneratedFiles)

- (BOOL)writeMakefile;
- (void)appendHead:(PCMakefileFactory *)mff;
- (void)appendLibraries:(PCMakefileFactory*)mff;
- (void)appendTail:(PCMakefileFactory *)mff;

@end

@interface PCBundleProject (Inspector)

- (NSView *)projectAttributesView;
- (void)updateInspectorValues:(NSNotification *)aNotif;
- (void)setPrincipalClass:(id)sender;
- (void)setBundleExtension:(id)sender;

@end

#endif
