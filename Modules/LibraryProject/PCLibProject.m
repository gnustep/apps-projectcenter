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

#include "PCLibProject.h"
#include "PCLibProj.h"

@implementation PCLibProject

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
  [rootCategories release];
  [rootKeys release];
  [rootEntries release];

  [super dealloc];
}

//----------------------------------------------------------------------------
// Project
//----------------------------------------------------------------------------

- (Class)builderClass
{
  return [PCLibProj class];
}

- (BOOL)canHavePublicHeaders
{
  return YES;
}

- (NSArray *)publicHeaders
{
  return [projectDict objectForKey:PCPublicHeaders];
}

- (void)setHeaderFile:(NSString *)file public:(BOOL)yn
{
  NSMutableArray *publicHeaders = [projectDict objectForKey:PCPublicHeaders];

  if (yn)
    {
      [publicHeaders addObject:file];
    }
  else if ([publicHeaders count] > 0 && [publicHeaders containsObject:file])
    {
      [publicHeaders removeObject:file];
    }

  [self setProjectDictObject:publicHeaders 
                      forKey:PCPublicHeaders 
		      notify:YES];
}

- (NSString *)projectDescription
{
  return @"GNUstep Objective-C library project";
}

- (NSArray *)buildTargets
{
  return [NSArray arrayWithObjects:
    @"library", @"debug", @"profile", @"dist", nil];
}

- (NSArray *)sourceFileKeys
{
  return [NSArray arrayWithObjects:
    PCClasses, PCHeaders, PCOtherSources,nil];
}

- (NSArray *)resourceFileKeys
{
  return [NSArray arrayWithObjects:
    PCInterfaces, PCImages, PCOtherResources, nil];
}

- (NSArray *)otherKeys
{
  return [NSArray arrayWithObjects:
    PCDocuFiles, PCLibraries, PCSubprojects, PCSupportingFiles, nil];
}

- (NSArray *)allowableSubprojectTypes
{
  return [NSArray arrayWithObjects:
    @"Bundle", @"Tool", nil];
}

- (NSArray *)localizableKeys
{
  return [NSArray arrayWithObjects: 
    PCInterfaces, PCImages, PCOtherResources, PCDocuFiles, nil];
}

// ============================================================================
// ==== File Handling
// ============================================================================

- (void)addFiles:(NSArray *)files forKey:(NSString *)type notify:(BOOL)yn
{
  if ([type isEqualToString:PCHeaders])
    {
      [super addFiles:files forKey:PCPublicHeaders notify:NO];
    }

  [super addFiles:files forKey:type notify:YES];
}

- (BOOL)renameFile:(NSString *)fromFile toFile:(NSString *)toFile
{
  NSString *category = [projectBrowser nameOfSelectedCategory];
  BOOL     success = NO;
  BOOL     isPublicHeader = YES;

  isPublicHeader = 
    [[projectDict objectForKey:PCPublicHeaders] containsObject:fromFile];

  success = [super renameFile:fromFile toFile:toFile];

  if (success && [category isEqualToString:[super categoryForKey:PCHeaders]])
    {
      if (isPublicHeader == NO)
	{
	  [self setHeaderFile:toFile public:NO];
	}
    }

  return success;
}

@end

@implementation PCLibProject (GeneratedFiles)

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
	  resourceItem = [NSString stringWithFormat:@"Resources/%@",
	                  [resources objectAtIndex:j]];
	  [resources replaceObjectAtIndex:j 
	                       withObject:resourceItem];
	}

      [mf appendResourceItems:resources];
      [resources release];
    }

  [self appendPublicHeaders:mf];
  
  // For compiling
  [mf appendHeaders:[projectDict objectForKey:PCHeaders]
          forTarget:[NSString stringWithFormat:@"lib%@",projectName]];
  [mf appendClasses:[projectDict objectForKey:PCClasses]
          forTarget:[NSString stringWithFormat:@"lib%@",projectName]];
  [mf appendOtherSources:[projectDict objectForKey:PCOtherSources]
          forTarget:[NSString stringWithFormat:@"lib%@",projectName]];

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
  [mff appendString:@"\n#\n# Bundle\n#\n"];
  [mff appendString:[NSString stringWithFormat:@"VERSION = %@\n",
    [projectDict objectForKey:PCRelease]]];
  [mff appendString:[NSString stringWithFormat:@"PACKAGE_NAME = %@\n",
    projectName]];
  [mff appendString:[NSString stringWithFormat:@"LIBRARY_VAR = %@\n",
    [projectName uppercaseString]]];
  [mff appendString:[NSString stringWithFormat:@"LIBRARY_NAME = lib%@\n",
    projectName]];
  [mff appendString:[NSString stringWithFormat:@"lib%@_HEADER_FILES_DIR = %@\n",
    projectName,@"."]];
  [mff appendString:[NSString stringWithFormat:
    @"lib%@_HEADER_FILES_INSTALL_DIR = /%@\n", projectName, projectName]];
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

- (void)appendPublicHeaders:(PCMakefileFactory *)mff
{
  NSArray *array = [projectDict objectForKey:PCPublicHeaders];

  if ([array count] == 0)
    {
      return;
    }

  [mff appendString:@"\n#\n# Public headers (will be installed)\n#\n"];

  [mff appendString:[NSString stringWithFormat:@"%@_HEADERS = ", 
                     projectName]];

  if (array && [array count])
    {
      NSString     *tmp;
      NSEnumerator *enumerator = [array objectEnumerator];

      while ((tmp = [enumerator nextObject])) 
	{
	  [mff appendString:[NSString stringWithFormat:@"\\\n%@ ",tmp]];
	}
    }
}

- (void)appendTail:(PCMakefileFactory *)mff
{
  [mff appendString:@"\n\n#\n# Makefiles\n#\n"];
  [mff appendString:@"-include GNUmakefile.preamble\n"];
  [mff appendString:@"include $(GNUSTEP_MAKEFILES)/aggregate.make\n"];
  [mff appendString:@"include $(GNUSTEP_MAKEFILES)/library.make\n"];
  [mff appendString:@"-include GNUmakefile.postamble\n"];
}

@end

@implementation PCLibProject (Inspector)

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
  [projectTypeField setStringValue:@"Library"];
  [projectNameField setStringValue:projectName];
  [projectLanguageField setStringValue:[projectDict objectForKey:@"LANGUAGE"]];
}

@end

