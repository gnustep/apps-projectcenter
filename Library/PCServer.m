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

#include "PCServer.h"
#include "PCDefines.h"
#include "PCProject.h"
#include "PCEditor.h"

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
  return NO;
}

- (BOOL)registerFileSubmenu:(NSMenu *)menu
{
  return NO;
}

- (BOOL)registerToolsSubmenu:(NSMenu *)menu
{
  return NO;
}

/*- (BOOL)registerPrefController:(id<PreferenceController>)prefs
{
  return NO;
}

- (BOOL)registerEditor:(id<ProjectEditor>)anEditor
{
  return NO;
}

- (BOOL)registerDebugger:(id<ProjectDebugger>)aDebugger
{
  return NO;
}*/

- (PCProject *)activeProject
{
  return NO;
}

- (NSString*)pathToActiveProject
{
  return NO;
}

- (id)activeFile
{
  return nil;
}

- (NSString*)pathToActiveFile
{
  return nil;
}

- (NSArray*)selectedFiles
{
  return nil;
}

- (NSArray*)touchedFiles
{
  return nil;
}

- (BOOL)queryTouchedFiles
{
  return NO;
}

- (BOOL)addFileAt:(NSString*)filePath toProject:(PCProject *)projectPath
{
  return NO;
}

- (BOOL)removeFileFromProject:(NSString *)filePath
{
  return NO;
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
