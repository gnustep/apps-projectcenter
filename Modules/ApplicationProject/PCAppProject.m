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

#include <ProjectCenter/ProjectCenter.h>
#include <ProjectCenter/PCProjectBrowser.h>

#include "PCAppProject.h"
#include "PCAppProject+Inspector.h"
#include "PCAppProj.h"

@implementation PCAppProject

// ----------------------------------------------------------------------------
// --- Init and free
// ----------------------------------------------------------------------------

- (id)init
{

  if ((self = [super init]))
    {
      rootObjects = [[NSArray arrayWithObjects: PCClasses,
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

      rootKeys = [[NSArray arrayWithObjects: @"Classes",
					     @"Headers",
					     @"Other Sources",
					     @"Interfaces",
					     @"Images",
					     @"Other Resources",
					     @"Subprojects",
					     @"Documentation",
//					     @"Context Help",
					     @"Supporting Files",
//					     @"Frameworks",
					     @"Libraries",
					     @"Non Project Files",
					     nil] retain];

      rootCategories = [[NSDictionary 
	dictionaryWithObjects:rootObjects forKeys:rootKeys] retain];
	
    }
  return self;
}

- (void)assignInfoDict:(NSMutableDictionary *)dict
{
  infoDict = [dict mutableCopy];
}

- (void)loadInfoFileAtPath:(NSString *)path
{
  NSString *infoFile = nil;

  infoFile = [path stringByAppendingPathComponent:@"Info-gnustep.plist"];
  infoDict = [[NSMutableDictionary alloc] initWithContentsOfFile:infoFile];
}

- (void)dealloc
{
  NSLog (@"PCAppProject: dealloc");

  RELEASE(infoDict);
  RELEASE(projectAttributesView);

  RELEASE(rootCategories);
  RELEASE(rootObjects);
  RELEASE(rootKeys);

  [super dealloc];
}

// ----------------------------------------------------------------------------
// --- PCProject overridings
// ----------------------------------------------------------------------------

- (Class)builderClass
{
  return [PCAppProj class];
}

- (NSString *)projectDescription
{
  return @"Project that handles GNUstep ObjC based applications.";
}

- (BOOL)isExecutable
{
  return YES;
}

- (NSString *)execToolName
{
  return [NSString stringWithString:@"openapp"];
}

- (NSArray *)fileTypesForCategory:(NSString *)category
{
//  NSLog(@"Category: %@", category);

  if ([category isEqualToString:PCClasses])
    {
      return [NSArray arrayWithObjects:@"m",nil];
    }
  else if ([category isEqualToString:PCHeaders])
    {
      return [NSArray arrayWithObjects:@"h",nil];
    }
  else if ([category isEqualToString:PCOtherSources])
    {
      return [NSArray arrayWithObjects:@"c",@"C",nil];
    }
  else if ([category isEqualToString:PCInterfaces])
    {
      return [NSArray arrayWithObjects:@"gmodel",@"gorm",nil];
    }
  else if ([category isEqualToString:PCImages])
    {
      return [NSImage imageFileTypes];
    }
  else if ([category isEqualToString:PCSubprojects])
    {
      return [NSArray arrayWithObjects:@"subproj",nil];
    }
  else if ([category isEqualToString:PCLibraries])
    {
      return [NSArray arrayWithObjects:@"so",@"a",@"lib",nil];
    }

  return nil;
}

- (NSString *)dirForCategory:(NSString *)category
{
  if ([category isEqualToString:PCImages])
    {
      return [projectPath stringByAppendingPathComponent:@"Images"];
    }
  else if ([category isEqualToString:PCDocuFiles])
    {
      return [projectPath stringByAppendingPathComponent:@"Documentation"];
    }

  return projectPath;
}

- (NSArray *)buildTargets
{
  return [NSArray arrayWithObjects:
    @"app", @"debug", @"profile", @"dist", nil];
}

- (NSArray *)sourceFileKeys
{
  return [NSArray arrayWithObjects:
    PCClasses, PCOtherSources, nil];
}

- (NSArray *)resourceFileKeys
{
  return [NSArray arrayWithObjects:
    PCInterfaces, PCOtherResources, PCImages, nil];
}

- (NSArray *)otherKeys
{
  return [NSArray arrayWithObjects:
    PCDocuFiles, PCSupportingFiles, PCNonProject, nil];
}

- (NSArray *)allowableSubprojectTypes
{
  return [NSArray arrayWithObjects:
    @"Bundle", @"Tool", @"Framework", @"Library", @"Palette", nil];
}

- (NSArray *)defaultLocalizableKeys
{
  return [NSArray arrayWithObjects: PCInterfaces, nil];
}

- (NSArray *)localizableKeys
{
  return [NSArray arrayWithObjects: 
    PCInterfaces, PCImages, PCOtherResources, PCDocuFiles, nil];
}

// ============================================================================
// ==== File Handling
// ============================================================================

- (BOOL)removeFiles:(NSArray *)files forKey:(NSString *)key
{
  NSMutableArray *filesToRemove = [[files mutableCopy] autorelease];
  NSString       *mainNibFile = [projectDict objectForKey:PCMainInterfaceFile];
  NSString       *appIcon = [projectDict objectForKey:PCAppIcon];

  if (!files || !key)
    {
      return NO;
    }

  // Check for main NIB file
  if ([key isEqualToString:PCInterfaces] && [files containsObject:mainNibFile])
    {
      int ret;
      ret = NSRunAlertPanel(@"Remove",
			    @"You've selected to remove main interface file.\nDo you still want to remove it?",
			    @"Remove", @"Leave", nil);
			    
      if (ret == NSAlertAlternateReturn) // Leave
	{
	  [filesToRemove removeObject:mainNibFile];
	}
      else
	{
	  [self clearMainNib:self];
	}
    }
  // Check for application icon files
  else if ([key isEqualToString:PCImages] && [files containsObject:appIcon])
    {
      int ret;
      ret = NSRunAlertPanel(@"Remove",
			    @"You've selected to remove application icon file.\nDo you still want to remove it?",
			    @"Remove", @"Leave", nil);
			    
      if (ret == NSAlertAlternateReturn) // Leave
	{
	  [filesToRemove removeObject:appIcon];
	}
      else
	{
	  [self clearAppIcon:self];
	}
    }

  return [super removeFiles:filesToRemove forKey:key];
}

@end

@implementation PCAppProject (GeneratedFiles)

- (void)writeInfoEntry:(NSString *)name forKey:(NSString *)key
{
  id entry = [projectDict objectForKey:key];

  if (entry == nil)
    {
      NSLog(@"%@ is nil", name);
      return;
    }

  if ([entry isKindOfClass:[NSString class]] && [entry isEqualToString:@""])
    {
      NSLog(@"%@ is empty string", name);
      [infoDict removeObjectForKey:name];
      return;
    }

  if ([entry isKindOfClass:[NSArray class]] && [entry count] <= 0)
    {
      NSLog(@"%@ is empty array", name);
      [infoDict removeObjectForKey:name];
      return;
    }

  [infoDict setObject:entry forKey:name];
}

- (BOOL)writeInfoFile
{
  NSString *infoFile = nil;

  [self writeInfoEntry:@"ApplicationDescription" forKey:PCDescription];
  [self writeInfoEntry:@"ApplicationIcon" forKey:PCAppIcon];
  [self writeInfoEntry:@"ApplicationName" forKey:PCProjectName];
  [self writeInfoEntry:@"ApplicationRelease" forKey:PCRelease];
  [self writeInfoEntry:@"Authors" forKey:PCAuthors];
  [self writeInfoEntry:@"Copyright" forKey:PCCopyright];
  [self writeInfoEntry:@"CopyrightDescription" forKey:PCCopyrightDescription];
  [self writeInfoEntry:@"FullVersionID" forKey:PCVersion];
  [self writeInfoEntry:@"NSExecutable" forKey:PCProjectName];
  [self writeInfoEntry:@"NSIcon" forKey:PCAppIcon];
  [self writeInfoEntry:@"NSMainNibFile" forKey:PCMainInterfaceFile];
  [self writeInfoEntry:@"NSPrincipalClass" forKey:PCPrincipalClass];
  [infoDict setObject:@"Application" forKey:@"NSRole"];
  [self writeInfoEntry:@"URL" forKey:PCURL];

  // Document icons
  [self writeInfoEntry:@"NSTypes" forKey:PCDocumentExtensions];

  infoFile = [projectPath stringByAppendingPathComponent:@"Info-gnustep.plist"];

  return [infoDict writeToFile:infoFile atomically:YES];
}

// Overriding
- (BOOL)writeMakefile
{
  PCMakefileFactory *mf = [PCMakefileFactory sharedFactory];
  int               i,j; 
  NSString          *mfl = nil;
  NSData            *mfd = nil;

  // Save Info-gnustep.plist
  [self writeInfoFile];

  // Save the GNUmakefile backup
  [super writeMakefile];

  // Save GNUmakefile.preamble
  [self writeMakefilePreamble];

  // Create the new file
  [mf createMakefileForProject:projectName];

  // Head
  [self appendHead:mf];

  // Application part
  [self appendApplication:mf];

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

      if ([k isEqualToString:PCImages])
	{
	  for (j=0; j<[resources count]; j++)
	    {
	      [resources replaceObjectAtIndex:j 
		withObject:[NSString stringWithFormat:@"Images/%@", 
		[resources objectAtIndex:j]]];
	    }
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
  [mff appendString:
    [NSString stringWithFormat:@"GNUSTEP_INSTALLATION_DIR = %@\n",
     [projectDict objectForKey:PCInstallDir]]];
}

- (void)appendApplication:(PCMakefileFactory *)mff
{
  [mff appendString:@"\n#\n# Application\n#\n"];
  [mff appendString:
    [NSString stringWithFormat:@"PACKAGE_NAME = %@\n",projectName]];
  [mff appendString:
    [NSString stringWithFormat:@"APP_NAME = %@\n",projectName]];
    
  [mff appendString:[NSString stringWithFormat:@"%@_APPLICATION_ICON = %@\n",
                     projectName, [projectDict objectForKey:PCAppIcon]]];

  // TODO: proper support for localisation
  //[self appendString:[NSString stringWithFormat:@"%@_LANGUAGES=English\n",pnme]];
  //[self appendString:[NSString stringWithFormat:@"%@_LOCALIZED_RESOURCE_FILES=Localizable.strings\n",pnme]];
}

- (void)appendTail:(PCMakefileFactory *)mff
{
  [mff appendString:@"\n\n#\n# Makefiles\n#\n"];
  [mff appendString:@"-include GNUmakefile.preamble\n"];
  [mff appendString:@"include $(GNUSTEP_MAKEFILES)/aggregate.make\n"];
  [mff appendString:@"include $(GNUSTEP_MAKEFILES)/application.make\n"];
  [mff appendString:@"-include GNUmakefile.postamble\n"];
}

- (BOOL)writeMakefilePreamble
{
  NSMutableString *mfp = [[NSMutableString alloc] init];
  NSString        *mfl = nil;
  NSArray         *array = nil;

  // Create the new file
  [mfp appendString:@"#\n"];
  [mfp appendString:@"# GNUmakefile.preamble - Generated by ProjectCenter\n"];
  [mfp appendString:@"#\n\n"];

  // Preprocessor flags
  [mfp appendString:@"# Additional flags to pass to the preprocessor\n"];
  [mfp appendString:
    [NSString stringWithFormat:@"ADDITIONAL_CPPFLAGS += %@\n\n", 
     [projectDict objectForKey:PCPreprocessorOptions]]];

  // Objective C compiler flags
  [mfp appendString:@"# Additional flags to pass to Objective C compiler\n"];
  [mfp appendString:
    [NSString stringWithFormat:@"ADDITIONAL_OBJCFLAGS += %@\n\n",
     [projectDict objectForKey:PCObjCCompilerOptions]]];
    
  // C compiler flags
  [mfp appendString:@"# Additional flags to pass to C compiler\n"];
  [mfp appendString:
    [NSString stringWithFormat:@"ADDITIONAL_CFLAGS += %@\n\n",
     [projectDict objectForKey:PCCompilerOptions]]];
		     
  // Linker flags
  [mfp appendString:@"# Additional flags to pass to the linker\n"];
  [mfp appendString:
    [NSString stringWithFormat:@"ADDITIONAL_LDFLAGS += %@\n\n",
     [projectDict objectForKey:PCLinkerOptions]]];

  // Directories where to search headers
  [mfp appendString:
    @"# Additional include directories the compiler should search\n"];
  [mfp appendString:@"ADDITIONAL_INCLUDE_DIRS += "];
  array = [projectDict objectForKey:PCSearchHeaders];
  if (array && [array count])
    {
      NSString     *tmp;
      NSEnumerator *enumerator = [array objectEnumerator];

      while ((tmp = [enumerator nextObject])) 
	{
	  [mfp appendString:[NSString stringWithFormat:@"-I%@ ",tmp]];
	}
      [mfp appendString:@"\n\n"];
    }
  
  // Directories where to search libraries
  [mfp appendString:
    @"# Additional library directories the linker should search\n"];
  [mfp appendString:@"ADDITIONAL_LIB_DIRS += "];
  array = [projectDict objectForKey:PCSearchLibs];
  if (array && [array count])
    {
      NSString     *tmp;
      NSEnumerator *enumerator = [array objectEnumerator];

      while ((tmp = [enumerator nextObject])) 
	{
	  [mfp appendString:[NSString stringWithFormat:@"-L%@ ",tmp]];
	}
      [mfp appendString:@"\n\n"];
    }

//  [mfp appendString:[projectDict objectForKey:PCLibraries]];

  // Write the new file to disc!
  mfl = [projectPath stringByAppendingPathComponent:@"GNUmakefile.preamble"];
  if ([mfp writeToFile:mfl atomically:YES]) 
    {
      return YES;
    }

  return NO;
}

@end
