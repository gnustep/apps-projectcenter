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

#import "PCLibProject.h"
#import "PCLibMakefileFactory.h"

#import <ProjectCenter/ProjectCenter.h>

#if defined(GNUSTEP)
#import <AppKit/IMLoading.h>
#endif

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
    rootCategories = [[NSDictionary dictionaryWithObjectsAndKeys:
				      PCSupportingFiles,@"Supporting Files",
				    PCSubprojects, @"Subprojects", 
				    PCLibraries, @"Libraries",
				    PCDocuFiles,@"Documentation",
				    PCOtherResources,@"Other Resources", 
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

- (BOOL)writeMakefile
{
    NSFileManager *fm = [NSFileManager defaultManager];
    NSString *makefile = [[self projectPath] stringByAppendingPathComponent:@"GNUmakefile"];
    NSData *content;

    if (![super writeMakefile]) {
        NSLog(@"Couldn't update PC.project...");
    }
    
    if (![fm movePath:makefile toPath:[projectPath stringByAppendingPathComponent:@"GNUmakefile~"] handler:nil]) {
        NSLog(@"Couldn't write a backup GNUmakefile...");
    }

    if (!(content = [[PCLibMakefileFactory sharedFactory] makefileForProject:self])) {
        NSLog([NSString stringWithFormat:@"Couldn't build the GNUmakefile %@!",makefile]);
        return NO;
    }
    if (![content writeToFile:makefile atomically:YES]) {
        NSLog([NSString stringWithFormat:@"Couldn't write the GNUmakefile %@!",makefile]);
        return NO;
    }
    return YES;
}

- (BOOL)isValidDictionary:(NSDictionary *)aDict
{
#warning No project check implemented, yet!
    return YES;
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
