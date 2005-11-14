/*
   GNUstep ProjectCenter - http://www.gnustep.org

   Copyright (C) 2001-2004 Free Software Foundation

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

#include <ProjectCenter/PCMakefileFactory.h>
#include <ProjectCenter/ProjectCenter.h>

#include "PCBundleProj.h"
#include "PCBundleProject.h"

@implementation PCBundleProject

//----------------------------------------------------------------------------
// Init and free
//----------------------------------------------------------------------------

- (id)init
{
  if ((self = [super init]))
    {
      rootKeys = [[NSArray arrayWithObjects:
	PCClasses,
	PCHeaders,
	PCOtherSources,
	PCInterfaces,
	PCImages,
	PCOtherResources,
	PCSubprojects,
	PCDocuFiles,
	PCSupportingFiles,
	PCLibraries,
	PCNonProject,
	nil] retain];

      rootCategories = [[NSArray arrayWithObjects:
	@"Classes",
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

      rootEntries = [[NSDictionary 
	dictionaryWithObjects:rootCategories forKeys:rootKeys] retain];

    }

  return self;
}

- (void)dealloc
{
#ifdef DEVELOPMENT
  NSLog(@"PCBundleProject: dealloc");
#endif
  [rootCategories release];
  [rootKeys release];
  [rootEntries release];

  [projectAttributesView release];

  [super dealloc];
}

//----------------------------------------------------------------------------
// Project
//----------------------------------------------------------------------------

- (Class)builderClass
{
  return [PCBundleProj class];
}

- (NSString *)projectDescription
{
  return @"GNUstep Objective-C bundle project";
}

- (NSArray *)buildTargets
{
  return [NSArray arrayWithObjects:
    @"bundle", @"debug", @"profile", @"dist", nil];
}

- (NSArray *)sourceFileKeys
{
  return [NSArray arrayWithObjects:
    PCClasses, PCHeaders, PCOtherSources,
    PCSubprojects, PCSupportingFiles, nil];
}

- (NSArray *)resourceFileKeys
{
  return [NSArray arrayWithObjects:
    PCInterfaces, PCOtherResources, PCImages, PCDocuFiles, nil];
}

- (NSArray *)otherKeys
{
  return [NSArray arrayWithObjects:
    PCLibraries, PCNonProject, nil];
}

- (NSArray *)allowableSubprojectTypes
{
  return [NSArray arrayWithObjects:
    @"Aggregate", @"Bundle", @"Tool", @"Library", nil];
}

- (NSArray *)localizableKeys
{
  return [NSArray arrayWithObjects: 
    PCInterfaces, PCImages, PCOtherResources, PCDocuFiles, nil];
}

@end

@implementation PCBundleProject (GeneratedFiles)

- (BOOL)writeMakefile
{
  PCMakefileFactory *mf = [PCMakefileFactory sharedFactory];
  int               i,j; 
  NSString          *mfl = nil;
  NSData            *mfd = nil;

  // Save the GNUmakefile backup
  [super writeMakefile];

  // Save GNUmakefile.preamble
  [mf createPreambleForProject:self];

  // Create the new file
  [mf createMakefileForProject:projectName];

  // Head
  [self appendHead:mf];

  // Libraries
  [self appendLibraries:mf];

  // Subprojects
  if ([[projectDict objectForKey:PCSubprojects] count] > 0)
    {
      [mf appendSubprojects:[projectDict objectForKey:PCSubprojects]];
    }

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
	  [resources replaceObjectAtIndex:j 
	                       withObject:resourceItem];
	}

      [mf appendResourceItems:resources];
      [resources release];
    }

  [mf appendHeaders:[projectDict objectForKey:PCHeaders]];
  [mf appendClasses:[projectDict objectForKey:PCClasses]];
  [mf appendOtherSources:[projectDict objectForKey:PCOtherSources]];

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
  NSString *installDir = [projectDict objectForKey:PCInstallDir];

  [mff appendString:@"\n#\n# Bundle\n#\n"];
  [mff appendString:[NSString stringWithFormat:@"VERSION = %@\n",
  [projectDict objectForKey:PCRelease]]];
  [mff appendString:[NSString stringWithFormat:@"PACKAGE_NAME = %@\n",
    projectName]];
  [mff appendString:[NSString stringWithFormat:@"BUNDLE_NAME = %@\n",
    projectName]];
  [mff appendString:[NSString stringWithFormat:@"%@_PRINCIPAL_CLASS = %@\n",
    projectName, [projectDict objectForKey:PCPrincipalClass]]];
  [mff appendString:[NSString stringWithFormat:@"BUNDLE_EXTENSION = %@\n",
    [projectDict objectForKey:PCBundleExtension]]];

  if ([installDir isEqualToString:@""])
    {
      [mff appendString:
	[NSString stringWithFormat:@"%@_STANDARD_INSTALL = no\n",
        projectName]];
    }
  else
    {
      [mff appendString:[NSString stringWithFormat:@"BUNDLE_INSTALL_DIR = %@\n",
        installDir]];
    }
}

- (void)appendLibraries:(PCMakefileFactory *)mff
{
  NSArray *libs = [projectDict objectForKey:PCLibraries];

  [mff appendString:@"\n#\n# Libraries\n#\n"];

  [mff appendString:
    [NSString stringWithFormat:@"%@_LIBRARIES_DEPEND_UPON += ",projectName]];

  if (libs && [libs count])
    {
      NSString     *tmp;
      NSEnumerator *enumerator = [libs objectEnumerator];

      while ((tmp = [enumerator nextObject])) 
	{
	  if (![tmp isEqualToString:@"gnustep-base"] &&
	      ![tmp isEqualToString:@"gnustep-gui"]) 
	    {
	      [mff appendString:[NSString stringWithFormat:@"-l%@ ",tmp]];
	    }
	}
    }
}

- (void)appendTail:(PCMakefileFactory *)mff
{
  [mff appendString:@"\n\n#\n# Makefiles\n#\n"];
  [mff appendString:@"-include GNUmakefile.preamble\n"];
  [mff appendString:@"include $(GNUSTEP_MAKEFILES)/aggregate.make\n"];
  [mff appendString:@"include $(GNUSTEP_MAKEFILES)/bundle.make\n"];
  [mff appendString:@"-include GNUmakefile.postamble\n"];
}

@end

@implementation PCBundleProject (Inspector)

- (NSView *)projectAttributesView
{
  if (projectAttributesView == nil)
    {
      if ([NSBundle loadNibNamed:@"Inspector" owner:self] == NO)
	{
	  NSLog(@"PCBundleProject: error loading Inspector NIB!");
	  return nil;
	}
      [projectAttributesView retain];
      [self updateInspectorValues:nil];
    }

  return projectAttributesView;
}

- (void)updateInspectorValues:(NSNotification *)aNotif 
{
  [projectTypeField setStringValue:@"Bundle"];
  [projectNameField setStringValue:projectName];
  [projectLanguageField
    setStringValue:[projectDict objectForKey:@"LANGUAGE"]];
  [principalClassField 
    setStringValue:[projectDict objectForKey:PCPrincipalClass]];
  [bundleExtensionField 
    setStringValue:[projectDict objectForKey:PCBundleExtension]];
}

- (void)setPrincipalClass:(id)sender
{
  [self setProjectDictObject:[principalClassField stringValue]
                      forKey:PCPrincipalClass
		      notify:YES];
}

- (void)setBundleExtension:(id)sender
{
  [self setProjectDictObject:[bundleExtensionField stringValue]
                      forKey:PCBundleExtension
		      notify:YES];
}

@end

