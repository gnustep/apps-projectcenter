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
#import "PCToolMakefileFactory.h"

#import <ProjectCenter/ProjectCenter.h>

#if defined(GNUSTEP)
#import <AppKit/IMLoading.h>
#endif

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
    
    [self _initUI];
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
    NSFileManager *fm = [NSFileManager defaultManager];
    NSData   *mfd;
    NSString *mf = [projectPath stringByAppendingPathComponent:@"GNUmakefile"];

    // Save the project file
    [super writeMakefile];
   
    if (mfd = [[PCToolMakefileFactory sharedFactory] makefileForProject:self]) {
        if ([mfd writeToFile:mf atomically:YES]) {
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
