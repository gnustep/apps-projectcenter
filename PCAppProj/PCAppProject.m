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

#import "PCAppProject.h"
#import "PCAppMakefileFactory.h"

#import <ProjectCenter/ProjectCenter.h>

#if defined(GNUSTEP)
#import <AppKit/IMLoading.h>
#endif

@interface PCAppProject (CreateUI)

- (void)_initUI;

@end

@implementation PCAppProject (CreateUI)

- (void)_initUI
{
  NSTextField *textField;
  NSRect frame = {{84,120}, {80, 80}};
  NSBox *_box;

  [super _initUI];

  textField =[[NSTextField alloc] initWithFrame:NSMakeRect(16,256,64,21)];
  [textField setAlignment: NSRightTextAlignment];
  [textField setBordered: NO];
  [textField setEditable: NO];
  [textField setBezeled: NO];
  [textField setDrawsBackground: NO];
  [textField setStringValue:@"App class:"];
  [projectProjectInspectorView addSubview:[textField autorelease]];

  appClassField =[[NSTextField alloc] initWithFrame:NSMakeRect(84,256,176,21)];
  [appClassField setAlignment: NSLeftTextAlignment];
  [appClassField setBordered: YES];
  [appClassField setEditable: YES];
  [appClassField setBezeled: YES];
  [appClassField setDrawsBackground: YES];
  [appClassField setStringValue:@""];
  [projectProjectInspectorView addSubview:appClassField];

  textField =[[NSTextField alloc] initWithFrame:NSMakeRect(16,204,64,21)];
  [textField setAlignment: NSRightTextAlignment];
  [textField setBordered: NO];
  [textField setEditable: NO];
  [textField setBezeled: NO];
  [textField setDrawsBackground: NO];
  [textField setStringValue:@"App icon:"];
  [projectProjectInspectorView addSubview:[textField autorelease]];

  appImageField =[[NSTextField alloc] initWithFrame:NSMakeRect(84,204,176,21)];
  [appImageField setAlignment: NSLeftTextAlignment];
  [appImageField setBordered: YES];
  [appImageField setEditable: YES];
  [appImageField setBezeled: YES];
  [appImageField setDrawsBackground: YES];
  [appImageField setStringValue:@""];
  [projectProjectInspectorView addSubview:appImageField];

  setAppIconButton =[[NSButton alloc] initWithFrame:NSMakeRect(180,180,80,21)];
  [setAppIconButton setTitle:@"Set..."];
  [setAppIconButton setTarget:self];
  [setAppIconButton setAction:@selector(setAppIcon:)];
  [projectProjectInspectorView addSubview:setAppIconButton];

  _box = [[NSBox alloc] init];
  [_box setFrame:frame];
  [_box setTitlePosition:NSNoTitle];
  //[_box setBorderType:NSNoBorder];
  [projectProjectInspectorView addSubview:_box];
  AUTORELEASE(_box);

  appIconView = [[NSImageView alloc] initWithFrame:frame];
  [_box addSubview:appIconView];
}

@end

@implementation PCAppProject

//----------------------------------------------------------------------------
// Init and free
//----------------------------------------------------------------------------

- (id)init
{
  if ((self = [super init])) {
    rootCategories = [[NSDictionary dictionaryWithObjectsAndKeys:
				      PCGModels,@"Interfaces",
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
  [appClassField release];
  [appImageField release];
  [setAppIconButton release];
  [appIconView release];

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

    if (!(content = [[PCAppMakefileFactory sharedFactory] makefileForProject:self])) {
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
    return [NSArray arrayWithObjects:PCGModels,PCOtherResources,PCImages,nil];
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
    return @"Project that handles GNUstep/ObjC based applications.";
}

- (BOOL)isExecutable
{
  return YES;
}

- (void)updateValuesFromProjectDict
{
  [super updateValuesFromProjectDict];

  [appClassField setStringValue:[projectDict objectForKey:PCAppClass]];
  [appImageField setStringValue:[projectDict objectForKey:PCAppIcon]];
}

@end
