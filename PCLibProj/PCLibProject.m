/*
   GNUstep ProjectCenter - http://www.projectcenter.ch

   Copyright (C) 2000 Philippe C.D. Robert

   Author: Philippe C.D. Robert <phr@projectcenter.ch>

   This file is part of ProjectCenter.

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
  // Always call super!!!
  [super _initUI];

  projectAttributeInspectorView = [[NSBox alloc] init];
  [projectAttributeInspectorView setTitlePosition:NSAtTop];
  [projectAttributeInspectorView setBorderType:NSGrooveBorder];
  //    [projectAttributeInspectorView addSubview:projectTypePopup];
  [projectAttributeInspectorView sizeToFit];
  [projectAttributeInspectorView setAutoresizingMask:NSViewWidthSizable];
  
  projectProjectInspectorView = [[NSBox alloc] init];
  [projectProjectInspectorView setTitlePosition:NSAtTop];
  [projectProjectInspectorView setBorderType:NSGrooveBorder];
  //    [projectProjectInspectorView addSubview:projectTypePopup];
  [projectProjectInspectorView sizeToFit];
  [projectProjectInspectorView setAutoresizingMask:NSViewWidthSizable];
  
  projectFileInspectorView = [[NSBox alloc] init];
  [projectFileInspectorView setTitlePosition:NSAtTop];
  [projectFileInspectorView setBorderType:NSGrooveBorder];
  //    [projectFileInspectorView addSubview:projectTypePopup];
  [projectFileInspectorView sizeToFit];
  [projectFileInspectorView setAutoresizingMask:NSViewWidthSizable];

  _needsAdditionalReleasing = YES;
}

@end

@implementation PCLibProject

//----------------------------------------------------------------------------
// Init and free
//----------------------------------------------------------------------------

- (id)init
{
    if ((self = [super init])) {
        rootCategories = [[NSDictionary dictionaryWithObjectsAndKeys:PCClasses,@"Classes",PCHeaders,@"Headers",PCOtherSources,@"Other Sources",PCOtherResources,@"Other Resources", PCSubprojects, @"Subprojects", PCLibraries, @"Libraries",PCDocuFiles,@"Documentation",nil] retain];

        _needsAdditionalReleasing = NO;

#if defined(GNUSTEP)
        [self _initUI];
#else
        if(![NSBundle loadNibNamed:@"LibProject.nib" owner:self]) {
	  [[NSException exceptionWithName:NIB_NOT_FOUND_EXCEPTION reason:@"Could not load LibProject.gmodel" userInfo:nil] raise];
	  return nil;
        }
#endif
    }
    return self;
}

- (void)dealloc
{
    [rootCategories release];

    if (_needsAdditionalReleasing) {
        [projectAttributeInspectorView release];
        [projectProjectInspectorView release];
        [projectFileInspectorView release];
    }

    [super dealloc];
}

//----------------------------------------------------------------------------
// Project
//----------------------------------------------------------------------------

- (BOOL)writeMakefile
{
    NSFileManager *fm = [NSFileManager defaultManager];
    NSString *makefile = [projectPath stringByAppendingPathComponent:@"GNUmakefile"];
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

@end
