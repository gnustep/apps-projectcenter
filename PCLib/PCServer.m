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

#import "PCServer.h"
#import "ProjectCenter.h"
#import "PCBrowserController.h"
#import "PCEditor.h"

@implementation PCServer

//----------------------------------------------------------------------------
// Init and free
//----------------------------------------------------------------------------

- (id)init
{
  if ((self = [super init])) 
  {
    clients = [[NSMutableArray alloc] init];
  }
  return self;
}

- (void)dealloc
{
  RELEASE(clients);

  [super dealloc];
}

//----------------------------------------------------------------------------
// Server
//----------------------------------------------------------------------------

- (BOOL)registerProjectSubmenu:(NSMenu *)menu
{
}

- (BOOL)registerFileSubmenu:(NSMenu *)menu
{
}

- (BOOL)registerToolsSubmenu:(NSMenu *)menu
{
}

- (BOOL)registerPrefController:(id<PreferenceController>)prefs
{
}

- (BOOL)registerEditor:(id<ProjectEditor>)anEditor
{
}

- (BOOL)registerDebugger:(id<ProjectDebugger>)aDebugger
{
}

- (PCProject *)activeProject
{
}

- (NSString*)pathToActiveProject
{
}

- (id)activeFile
{
}

- (NSString*)pathToActiveFile
{
}

- (NSArray*)selectedFiles
{
}

- (NSArray*)touchedFiles
{
}

- (BOOL)queryTouchedFiles
{
}

- (BOOL)addFileAt:(NSString*)filePath toProject:(PCProject *)projectPath
{
}

- (BOOL)removeFileFromProject:(NSString *)filePath
{
}

- (void)connectionDidDie:(NSNotification *)notif
{
    id clientCon = [notif object];

    if ([clientCon isKindOfClass:[NSConnection class]]) {
        int i;

        for (i=0;i<[clients count];i++) {
            id client = [clients objectAtIndex:i];

            if ([client isProxy] && [client connectionForProxy] == clientCon) {
                [clients removeObjectAtIndex:i];
            }
        }        
    }
}

@end
