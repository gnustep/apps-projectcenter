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

#include "PCProject+UInterface.h"
#include "PCLibProject.h"
#include "PCLibProj.h"

#include <ProjectCenter/PCMakefileFactory.h>

@interface PCLibProject (CreateUI)

- (void)_initUI;

@end

@implementation PCLibProject (CreateUI)

- (void)_initUI
{
  [super _initUI];
}

@end

@implementation PCLibProject

//----------------------------------------------------------------------------
// Init and free
//----------------------------------------------------------------------------

- (id)init
{
  if ((self = [super init])) {
      rootObjects = [[NSArray arrayWithObjects: PCClasses,
						PCHeaders,
						PCOtherSources,
						PCOtherResources,
						PCSubprojects,
						PCDocuFiles,
						PCSupportingFiles,
						PCLibraries,
						PCNonProject,
						nil] retain];

      rootKeys = [[NSArray arrayWithObjects: @"Classes",
					     @"Headers",
					     @"Other Sources",
					     @"Other Resources",
					     @"Subprojects",
					     @"Documentation",
					     @"Supporting Files",
					     @"Libraries",
					     @"Non Project Files",
					     nil] retain];

      rootCategories = [[NSDictionary 
	dictionaryWithObjects:rootObjects forKeys:rootKeys] retain];
    
  }
  return self;
}

- (void)dealloc
{
  [rootCategories release];
  [rootObjects release];
  [rootKeys release];
  
  [super dealloc];
}

//----------------------------------------------------------------------------
// Project
//----------------------------------------------------------------------------

- (Class)builderClass
{
    return [PCLibProj class];
}

- (BOOL)writeMakefile
{
    NSData   *mfd;
    NSString *mfl = [projectPath stringByAppendingPathComponent:@"GNUmakefile"];
    PCMakefileFactory *mf = [PCMakefileFactory sharedFactory];
    NSDictionary      *dict = [self projectDict];

    // Save the project file
    [super writeMakefile];
   
    [mf createMakefileForProject:[self projectName]];
    [mf appendString:@"include $(GNUSTEP_MAKEFILES)/common.make\n"];
    [mf appendString:@"include Version\n"];
    [mf appendSubprojects:[dict objectForKey:PCSubprojects]];

    [mf appendLibrary];
    [mf appendLibraryInstallDir:[dict objectForKey:PCInstallDir]];
    [mf appendLibraryLibraries:[dict objectForKey:PCLibraries]];

    [mf appendLibraryHeaders:[dict objectForKey:PCHeaders]];
    [mf appendLibraryClasses:[dict objectForKey:PCClasses]];
    [mf appendLibraryOtherSources:[dict objectForKey:PCOtherSources]];

    [mf appendTailForLibrary];

    // Write the new file to disc!
    if ((mfd = [mf encodedMakefile]))
    {
        if ([mfd writeToFile:mfl atomically:YES])
        {
            return YES;
        }
    }

    return NO;
}

- (NSArray *)sourceFileKeys
{
    return [NSArray arrayWithObjects:PCClasses,PCOtherSources,nil];
}

- (NSArray *)resourceFileKeys
{
    return [NSArray array];
}

- (NSArray *)otherKeys
{
    return [NSArray arrayWithObjects:PCDocuFiles,PCSupportingFiles,nil];
}

- (NSArray *)buildTargets
{
  return nil;
}

- (NSString *)projectDescription
{
    return @"Project that handles GNUstep/ObjC based libraries.";
}

- (void)updateValuesFromProjectDict
{
  [super updateValuesFromProjectDict];

  //[appClassField setStringValue:[projectDict objectForKey:PCAppClass]];
}

@end
