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

#import "PCToolProject.h"
#import "PCToolProj.h"

#import <ProjectCenter/PCMakefileFactory.h>

@interface PCToolProject (CreateUI)

- (void)_initUI;

@end

@implementation PCToolProject (CreateUI)

- (void)_initUI
{
  [super _initUI];
}

@end

@implementation PCToolProject

//----------------------------------------------------------------------------
// Init and free
//----------------------------------------------------------------------------

- (id)init
{
  if ((self = [super init])) {
    rootCategories = [[NSDictionary dictionaryWithObjectsAndKeys:
				    PCSupportingFiles,@"Supporting Files",
				    PCImages,@"Images",
				    PCOtherResources,@"Other Resources",
				    PCSubprojects,@"Subprojects",
				    PCLibraries,@"Libraries",
				    PCDocuFiles,@"Documentation",
				    PCOtherSources,@"Other Sources",
				    PCHeaders,@"Headers",
				    PCClasses,@"Classes",
				    nil] retain];
    
  }
  return self;
}

- (void)dealloc
{
  [rootCategories release];
  
  [super dealloc];
}

//----------------------------------------------------------------------------
// Project
//----------------------------------------------------------------------------

- (Class)builderClass
{
    return [PCToolProj class];
}

- (BOOL)writeMakefile
{
    NSData   *mfd;
    NSString *mfl = [projectPath stringByAppendingPathComponent:@"GNUmakefile"];
    int i; 
    PCMakefileFactory *mf = [PCMakefileFactory sharedFactory];
    NSDictionary      *dict = [self projectDict];

    // Save the project file
    [super writeMakefile];
   
    // Create the new file
    [mf createMakefileForProject:[self projectName]];
   
    [mf appendString:@"include $(GNUSTEP_MAKEFILES)/common.make\n"];
    [mf appendSubprojects:[dict objectForKey:PCSubprojects]];

    [mf appendTool];
    [mf appendInstallDir:[dict objectForKey:PCInstallDir]];
    [mf appendToolIcon:[dict objectForKey:PCToolIcon]];

    [mf appendToolLibraries:[dict objectForKey:PCLibraries]];

    [mf appendResources];
    for (i=0;i<[[self resourceFileKeys] count];i++)
    {
        NSString *k = [[self resourceFileKeys] objectAtIndex:i];
        [mf appendResourceItems:[dict objectForKey:k]];
    }

    [mf appendHeaders:[dict objectForKey:PCHeaders]];
    [mf appendClasses:[dict objectForKey:PCClasses]];
    [mf appendCFiles:[dict objectForKey:PCOtherSources]];

    [mf appendTailForTool];

    // Write the new file to disc!
    if (mfd = [mf encodedMakefile]) 
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
    return [NSArray arrayWithObjects:PCOtherResources,PCImages,nil];
}

- (NSArray *)otherKeys
{
    return [NSArray arrayWithObjects:PCDocuFiles,PCSupportingFiles,nil];
}

- (NSArray *)buildTargets
{
}

- (NSString *)projectDescription
{
    return @"Project that handles GNUstep/ObjC based tools.";
}

- (BOOL)isExecutable
{
  return YES;
}

- (void)updateValuesFromProjectDict
{
  [super updateValuesFromProjectDict];

  //[appClassField setStringValue:[projectDict objectForKey:PCAppClass]];
}

@end
