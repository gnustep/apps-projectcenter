/*
   GNUstep ProjectCenter - http://www.gnustep.org

   Copyright (C) 2004 Free Software Foundation

   Authors: Serg Stoyan

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

#include "PCResourceSetProject.h"
#include "PCResourceSetProj.h"

#include <ProjectCenter/PCMakefileFactory.h>

@implementation PCResourceSetProject

//----------------------------------------------------------------------------
// Init and free
//----------------------------------------------------------------------------

- (id)init
{
  if ((self = [super init]))
    {
      rootKeys = [[NSArray arrayWithObjects:
	PCOtherResources,
	PCSupportingFiles,
	PCNonProject,
	nil] retain];

      rootCategories = [[NSArray arrayWithObjects:
	@"Other Resources",
	@"Supporting Files",
	@"Non Project Files",
	nil] retain];

      rootEntries = [[NSDictionary 
	dictionaryWithObjects:rootCategories forKeys:rootKeys] retain];
    }

  return self;
}

- (void)dealloc
{
  [rootCategories release];
  [rootKeys release];
  [rootEntries release];

  if (projectAttributesView) [projectAttributesView release];
  
  [super dealloc];
}

//----------------------------------------------------------------------------
// Project
//----------------------------------------------------------------------------

- (Class)builderClass
{
  return [PCResourceSetProj class];
}

- (NSString *)projectDescription
{
  return @"Project that contains resources.";
}

- (NSArray *)resourceFileKeys
{
  return [NSArray arrayWithObjects:PCOtherResources, nil];
}

- (NSArray *)otherKeys
{
  return [NSArray arrayWithObjects:PCNonProject, nil];
}

- (NSArray *)allowableSubprojectTypes
{
  return [NSArray arrayWithObjects:
    @"Application", @"Bundle", @"Library", @"Framework", @"Tool", nil];
}

@end

@implementation PCResourceSetProject (GeneratedFiles)

- (BOOL)writeMakefile
{
  PCMakefileFactory *mf = [PCMakefileFactory sharedFactory];
  NSString          *mfl = nil;
  NSData            *mfd = nil;
  int               i, j;

  // Save the GNUmakefile backup
  [super writeMakefile];

  // Save GNUmakefile.preamble
  [mf createPreambleForProject:self];

  // Create the new file
  [mf createMakefileForProject:projectName];

  // Head
  [self appendHead:mf];

  // Resources
  [mf appendResources];
  for (i = 0; i < [[self resourceFileKeys] count]; i++)
    {
      NSString       *k = [[self resourceFileKeys] objectAtIndex:i];
      NSMutableArray *resources = [[projectDict objectForKey:k] mutableCopy];
      NSString       *resourceItem = nil;

      for (j = 0; j < [resources count]; j++)
	{
	  resourceItem = [resources objectAtIndex:j];
	  if ([[resourceItem pathComponents] count] == 1)
	    {
	      resourceItem = [NSString stringWithFormat:@"Resources/%@",
			   resourceItem];
	    }
	  [resources replaceObjectAtIndex:j withObject:resourceItem];
	}

      [mf appendResourceItems:resources];
      [resources release];
    }


  // Tail
  [self appendTail:mf];

  // Write the new file to disc!
  mfl = [projectPath stringByAppendingPathComponent:@"GNUmakefile"];
  if ((mfd = [mf encodedMakefile])) 
    {
      if ([mfd writeToFile:mfl atomically:YES]) 
	{
	  return YES;
	}
    }

  return NO;
}

- (void)appendHead:(PCMakefileFactory *)mff
{
  [mff appendString:@"\n#\n# Resource Set\n#\n"];
  [mff appendString:[NSString stringWithFormat:@"RESOURCE_SET_NAME = %@\n",
    projectName]];
  [mff appendString:
    [NSString stringWithFormat:@"@%RESOURCE_FILES_INSTALL_DIR = %@\n",
    [projectDict objectForKey:PCInstallDir]]];
}

- (void)appendTail:(PCMakefileFactory *)mff
{
  [mff appendString:@"\n\n#\n# Makefiles\n#\n"];
  [mff appendString:@"-include GNUmakefile.preamble\n"];
  [mff appendString:@"include $(GNUSTEP_MAKEFILES)/resource-set.make\n"];
  [mff appendString:@"-include GNUmakefile.postamble\n"];
}

@end

@implementation PCResourceSetProject (Inspector)

- (NSView *)projectAttributesView
{
  if (projectAttributesView == nil)
    {
      if ([NSBundle loadNibNamed:@"Inspector" owner:self] == NO)
	{
	  NSLog(@"PCLibraryProject: error loading Inspector NIB!");
	  return nil;
	}
      [projectAttributesView retain];
      [self updateInspectorValues:nil];
    }

  return projectAttributesView;
}

- (void)updateInspectorValues:(NSNotification *)aNotif 
{
}

@end

