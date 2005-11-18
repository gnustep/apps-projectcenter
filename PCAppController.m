/*
   GNUstep ProjectCenter - http://www.gnustep.org

   Copyright (C) 2001 Free Software Foundation

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

#include "PCAppController.h"
#include "PCMenuController.h"
#include "PCInfoController.h"
#include "Library/PCPrefController.h"
#include "Library/PCLogController.h"

#include "Library/ProjectCenter.h"

@implementation PCAppController

//============================================================================
//==== Intialization & deallocation
//============================================================================

+ (void)initialize
{
}

- (id)init
{
  if ((self = [super init]))
    {
      infoController = [[PCInfoController alloc] init];
      // Termporary workaround to initialize defaults values
      prefController = [PCPrefController sharedPCPreferences];
      logController  = [PCLogController sharedLogController];
      
      projectManager = [[PCProjectManager alloc] init];
      [projectManager setDelegate:self];
      [projectManager setPrefController:prefController];
    }

  return self;
}

- (void)dealloc
{
  [super dealloc];
}

- (void)awakeFromNib
{
  [menuController setAppController:self];
  [menuController setProjectManager:projectManager];
}

//============================================================================
//==== Accessory methods
//============================================================================

- (PCProjectManager *)projectManager
{
  return projectManager;
}

- (PCMenuController *)menuController
{
  return menuController;
}

- (PCInfoController *)infoController
{
  return infoController;
}

- (PCPrefController *)prefController
{
  return prefController;
}

- (PCLogController *)logController
{
  return logController;
}

- (PCServer *)doServer
{
  return doServer;
}

//============================================================================
//==== Misc...
//============================================================================

- (BOOL)application:(NSApplication *)application openFile:(NSString *)fileName
{
  [NSApp activateIgnoringOtherApps:YES];

  if ([[fileName pathExtension] isEqualToString:@"pcproj"] == YES
      || [[fileName pathExtension] isEqualToString:@"project"] == YES) 
    {
      [projectManager openProjectAt:fileName];
    }
  else
    {
      [projectManager openFileWithEditor:fileName];
    }

  return YES;
}

- (void)applicationWillFinishLaunching:(NSNotification *)notification
{
//  [bundleLoader loadBundles];
}

- (void)applicationDidFinishLaunching:(NSNotification *)notification
{
  NSString *connectionName = [NSString stringWithFormat:@"ProjectCenter"];

  if ([[prefController objectForKey:DisplayLog] isEqualToString:@"YES"])
    {
      [logController showPanel];
    }

  [logController 
    logMessage:@"Loading additional subsystems..." withTag:PC_INFO sender:self];

  doServer = [[PCServer alloc] init];
  
  NS_DURING
    
  doConnection = [[NSConnection alloc] init];
  [doConnection registerName:connectionName];
  
  NS_HANDLER
    
  NSRunAlertPanel(@"Warning!",
		  @"Could not register the DO connection %@",
                  @"OK",nil,nil,nil,
		  connectionName);
  NS_ENDHANDLER
    
  [[NSNotificationCenter defaultCenter] addObserver:doServer 
                                           selector:@selector(connectionDidDie:)
                                             name:NSConnectionDidDieNotification
                                            object:doConnection];
  
  [doConnection setDelegate:doServer];

  [[NSNotificationCenter defaultCenter] 
    postNotificationName:PCAppDidInitNotification
                  object:nil];
}

- (BOOL)applicationShouldTerminate:(id)sender
{
  NSString *poq;
  NSString *soq;
  BOOL     quit;

  poq = [[NSUserDefaults standardUserDefaults] objectForKey:PromptOnQuit];
  soq = [[NSUserDefaults standardUserDefaults] objectForKey:SaveOnQuit];
  if ([poq isEqualToString:@"YES"])
    {
      if (NSRunAlertPanel(@"Quit!",
			  @"Do you really want to quit ProjectCenter?",
			  @"No", @"Yes", nil))
	{
	  return NO;
	}

    }

  // Save projects if preferences tells that
  if ([soq isEqualToString:@"YES"])
    {
      quit = [projectManager saveAllProjects];
    }

  // Close all loaded projects
  quit = [projectManager closeAllProjects];

  if (quit == NO)
    {
      return NO;
    }

  [[NSNotificationCenter defaultCenter]
    postNotificationName:PCAppWillTerminateNotification
                  object:nil];

  return YES;
}

- (void)applicationWillTerminate:(NSNotification *)notification
{
#ifdef DEVELOPMENT
  NSLog (@"--- Application WILL terminate");
#endif

// It's broken. Disable it until support for GNUSTEP_BUILD_DIR will 
// be implemented
/*  if ([[[NSUserDefaults standardUserDefaults] 
      stringForKey:DeleteCacheWhenQuitting] isEqualToString:@"YES"]) 
    {
      [[NSFileManager defaultManager] 
	removeFileAtPath:[projectManager rootBuildPath]
	         handler:nil];
    }*/

  [[NSUserDefaults standardUserDefaults] synchronize];

  //--- Cleanup
  if (doConnection)
    {
      [doConnection invalidate];
      RELEASE(doConnection);
    }

  RELEASE(infoController);
  RELEASE(prefController);
  RELEASE(logController);
  RELEASE(menuController);
  RELEASE(projectManager);

  RELEASE(doServer);

#ifdef DEVELOPMENT
  NSLog (@"--- Application WILL terminate.END");
#endif
}

@end

