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
#include "PCBundleProject.h"
#include "PCBundleProj.h"

#include <ProjectCenter/PCMakefileFactory.h>

#include <ProjectCenter/ProjectCenter.h>

//#define BUNDLE_INSTALL @"$(GNUSTEP_LOCAL_ROOT)/Library/Bundles/"
#define BUNDLE_INSTALL @"$(GNUSTEP_INSTALLATION_DIR)/Library/Bundles/"

@interface PCBundleProject (CreateUI)

- (void)_initUI;

@end

@implementation PCBundleProject (CreateUI)

- (void)_initUI
{
  NSTextField *textField;
  NSRect frame = {{84,120}, {80, 80}};

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
  if ((self = [super init]))
    {
      rootObjects = [[NSArray arrayWithObjects: PCClasses,
						PCHeaders,
						PCOtherSources,
						PCGModels,
						PCImages,
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
					     @"Interfaces",
					     @"Images",
					     @"Other Resources",
					     @"Subprojects",
					     @"Documentation",
					     @"Supporting Files",
					     @"Libraries",
					     @"Non Project Files",
					     nil] retain];

      rootCategories = [[NSDictionary 
	dictionaryWithObjects:rootObjects forKeys:rootKeys] retain];

      principalClassField = nil;
    }

  return self;
}

- (void)dealloc
{
  [rootCategories release];
  [rootObjects release];
  [rootKeys release];
  [principalClassField release];

  [super dealloc];
}

//----------------------------------------------------------------------------
// Project
//----------------------------------------------------------------------------

- (Class)builderClass
{
    return [PCBundleProj class];
}

- (BOOL)writeMakefile
{
    NSString *tmp;
    NSData   *mfd;
    NSString *mfl = [projectPath stringByAppendingPathComponent:@"GNUmakefile"];
    int i; 
    PCMakefileFactory *mf = [PCMakefileFactory sharedFactory];
    NSDictionary      *dict = [self projectDict];
    NSArray           *classes = [dict objectForKey:PCClasses];
    NSString          *iDir = [dict objectForKey:PCInstallDir];

    // Save the project file
    [super writeMakefile];
   
    if( [iDir isEqualToString:@""] )
    {
        iDir = [NSString stringWithString:BUNDLE_INSTALL];
    }

    if ((tmp = [dict objectForKey:PCPrincipalClass]) &&
        [tmp isEqualToString:@""] == NO)
    {
    }
    else if ([classes count]) 
    {
        tmp = [[classes objectAtIndex:0] stringByDeletingPathExtension];
    }
    else tmp = [NSString string];

    [mf createMakefileForProject:[self projectName]];

    [mf appendString:@"include $(GNUSTEP_MAKEFILES)/common.make\n"];

    [mf appendSubprojects:[dict objectForKey:PCSubprojects]];

    [mf appendBundle];
    [mf appendBundleInstallDir:iDir];
    [mf appendPrincipalClass:tmp];
    [mf appendLibraries:[dict objectForKey:PCLibraries]];

    [mf appendResources];
    for (i=0;i<[[self resourceFileKeys] count];i++)
    {
        NSString *k = [[self resourceFileKeys] objectAtIndex:i];
        [mf appendResourceItems:[dict objectForKey:k]];
    }

    [mf appendHeaders:[dict objectForKey:PCHeaders]];
    [mf appendClasses:[dict objectForKey:PCClasses]];
    [mf appendOtherSources:[dict objectForKey:PCOtherSources]];

    [mf appendTailForBundle];

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
  return [NSArray arrayWithObjects:PCGModels,PCOtherResources,PCImages,nil];
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

  [projectWindow setDocumentEdited:YES];
}

@end



