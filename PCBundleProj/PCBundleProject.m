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

#import "PCBundleProject.h"
#import "PCBundleMakefileFactory.h"

#import <ProjectCenter/ProjectCenter.h>

@interface PCBundleProject (CreateUI)

- (void)_initUI;

@end

@implementation PCBundleProject (CreateUI)

- (void)_initUI
{
  NSTextField *textField;
  NSRect frame = {{84,120}, {80, 80}};
  NSBox *box;

  [super _initUI];

  textField =[[NSTextField alloc] initWithFrame:NSMakeRect(16,240,88,21)];
  [textField setAlignment: NSRightTextAlignment];
  [textField setBordered: NO];
  [textField setEditable: NO];
  [textField setBezeled: NO];
  [textField setDrawsBackground: NO];
  [textField setStringValue:@"Principal class:"];
  [projectProjectInspectorView addSubview:textField];
  RELEASE(textField);

  frame = NSMakeRect(106,240,144,21);
  principalClassField =[[NSTextField alloc] initWithFrame:frame];
  [principalClassField setAlignment: NSLeftTextAlignment];
  [principalClassField setBordered: YES];
  [principalClassField setEditable: YES];
  [principalClassField setBezeled: YES];
  [principalClassField setDrawsBackground: YES];
  [principalClassField setStringValue:@""];
  [principalClassField setTarget:self];
  [principalClassField setAction:@selector(setPrincipalClass:)];
  [projectProjectInspectorView addSubview:principalClassField];
}

@end

@implementation PCBundleProject

//----------------------------------------------------------------------------
// Init and free
//----------------------------------------------------------------------------

- (id)init
{
  if ((self = [super init])) {
    rootCategories = [[NSDictionary dictionaryWithObjectsAndKeys:
				      PCGModels,@"Interfaces",
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
  [principalClassField release];

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
  
  if (!(content = [[PCBundleMakefileFactory sharedFactory] makefileForProject:self])) {
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
  return @"GNUstep Objective-C bundle project";
}

- (void)updateValuesFromProjectDict
{
  NSString *pc;

  [super updateValuesFromProjectDict];

  pc = [projectDict objectForKey:PCPrincipalClass];
  [principalClassField setStringValue:pc];
}

- (void)setPrincipalClass:(id)sender
{
  [projectDict setObject:[principalClassField stringValue] 
	       forKey:PCPrincipalClass];

  [self writeMakefile];
}

@end



