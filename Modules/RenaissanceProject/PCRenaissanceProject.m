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

#include <ProjectCenter/ProjectCenter.h>
#include <ProjectCenter/PCProjectBrowser.h>

#include "PCRenaissanceProject.h"
#include "PCRenaissanceProject+Inspector.h"
#include "PCRenaissanceProj.h"

@implementation PCRenaissanceProject

// ----------------------------------------------------------------------------
// --- Init and free
// ----------------------------------------------------------------------------

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
//      @"Context Help",
      @"Supporting Files",
//      @"Frameworks",
      @"Libraries",
      @"Non Project Files",
      nil] retain];
      
      rootEntries = [[NSDictionary 
	dictionaryWithObjects:rootCategories forKeys:rootKeys] retain];
	
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
  if ([[NSFileManager defaultManager] fileExistsAtPath:infoFile])
    {
      infoDict = [[NSMutableDictionary alloc] initWithContentsOfFile:infoFile];
    }
  else
    {
      infoDict = [[NSMutableDictionary alloc] init];
    }
}

- (void)dealloc
{
  NSLog (@"PCRenaissanceProject: dealloc");

  [[NSNotificationCenter defaultCenter] removeObserver:self];

  RELEASE(infoDict);
  RELEASE(projectAttributesView);

  RELEASE(rootCategories);
  RELEASE(rootKeys);
  RELEASE(rootEntries);

  [super dealloc];
}

// ----------------------------------------------------------------------------
// --- PCProject overridings
// ----------------------------------------------------------------------------

- (Class)builderClass
{
  return [PCRenaissanceProj class];
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
    @"Aggregate", @"Bundle", @"Tool", @"Library", nil];
}

- (NSArray *)localizableKeys
{
  return [NSArray arrayWithObjects: 
    PCInterfaces, PCImages, PCOtherResources, PCDocuFiles, nil];
}

- (BOOL)isEditableCategory:(NSString *)category
{
  NSString *key = [self keyForCategory:category];
   
  if ([super isEditableCategory:category] 
      || [key isEqualToString:PCInterfaces])
    {
      return YES;
    }
   
  return NO;
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

- (BOOL)renameFile:(NSString *)fromFile toFile:(NSString *)toFile
{
  NSString *mainNibFile = [projectDict objectForKey:PCMainInterfaceFile];
  NSString *appIcon = [projectDict objectForKey:PCAppIcon];
  NSString *categoryKey = nil;
  NSString *ff = [fromFile copy];
  NSString *tf = [toFile copy];
  BOOL     success = NO;

  categoryKey = [self 
    keyForCategory:[projectBrowser nameOfSelectedRootCategory]];

  // Check for main NIB file
  if ([categoryKey isEqualToString:PCInterfaces] 
      && [fromFile isEqualToString:mainNibFile])
    {
      [self clearMainNib:self];
      if ([super renameFile:ff toFile:tf] == YES)
	{
	  [self setMainNibWithFileAtPath:
	    [[self dirForCategoryKey:categoryKey]
	      stringByAppendingPathComponent:tf]];
	  success = YES;
	}
    }
  // Check for application icon files
  else if ([categoryKey isEqualToString:PCImages] 
	   && [fromFile isEqualToString:appIcon])
    {
      [self clearAppIcon:self];
      if ([super renameFile:ff toFile:tf] == YES)
	{
	  [self setAppIconWithImageAtPath:
	    [[self dirForCategoryKey:categoryKey]
	      stringByAppendingPathComponent:tf]];
	  success = YES;
	}
    }
  else if ([super renameFile:ff toFile:tf] == YES)
    {
      success = YES;
    }
    
  [ff release];
  [tf release];

  return success;
}

@end

@implementation PCRenaissanceProject (GeneratedFiles)

- (void)writeInfoEntry:(NSString *)name forKey:(NSString *)key
{
  id entry = [projectDict objectForKey:key];

  if (entry == nil)
    {
      return;
    }

  if ([entry isKindOfClass:[NSString class]] && [entry isEqualToString:@""])
    {
      [infoDict removeObjectForKey:name];
      return;
    }

  if ([entry isKindOfClass:[NSArray class]] && [entry count] <= 0)
    {
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
  [self writeInfoEntry:@"GSMainMarkupFile" forKey:PCMainInterfaceFile];
  [self writeInfoEntry:@"NSPrincipalClass" forKey:PCPrincipalClass];
  [infoDict setObject:@"Application" forKey:@"NSRole"];
  [infoDict setObject:[self convertExtensions] forKey:@"NSTypes"];
  [self writeInfoEntry:@"URL" forKey:PCURL];

  infoFile = [self dirForCategoryKey:PCOtherResources];
  infoFile = [infoFile stringByAppendingPathComponent:@"Info-gnustep.plist"];

  return [infoDict writeToFile:infoFile atomically:YES];
}

- (NSArray *)convertExtensions
{
  NSMutableArray *icons = [NSMutableArray arrayWithCapacity:1];
  NSMutableArray *extensions = [NSMutableArray arrayWithCapacity:1];
  NSArray        *docIE = [projectDict objectForKey:PCDocumentExtensions];
  NSEnumerator   *enumerator = [docIE objectEnumerator];
  NSDictionary   *anObject;

  NSMutableArray      *resArray = [[NSMutableArray alloc] init];
  NSMutableDictionary *tmpDict = [NSMutableDictionary dictionaryWithCapacity:1];
  NSString            *ic;
  NSArray             *ex;

  while ((anObject = [enumerator nextObject]))
    {
      [icons addObject:[anObject objectForKey:@"Icon"]];
      [extensions addObject:[anObject objectForKey:@"Extension"]];
    }

  // At this point we have 2 arrays; 1 list of icons and 2 list of extensions.
  // So go group it!
  while ([icons count] && [extensions count])
    {
      int                 i;
      BOOL                loaded = NO;
      NSMutableDictionary *tdict;
      NSString            *tic;

      ic = [icons objectAtIndex:0];
      ex = [NSMutableArray arrayWithObject:[extensions objectAtIndex:0]];

      for (i = 0; i < [resArray count]; i++)
	{
	  tdict = [resArray objectAtIndex:i];
	  tic = [tdict objectForKey:@"NSIcon"];

	  if([tic isEqualToString:ic])
	    {
	      [[tdict objectForKey:@"NSUnixExtensions"] 
		addObject:[ex objectAtIndex:0]];
	      loaded = YES;
	      continue;
	    }
	}

      if (!loaded)
	{
	  [tmpDict setObject:ic forKey:@"NSIcon"];
	  [tmpDict setObject:ex forKey:@"NSUnixExtensions"];
      
	  [resArray addObject:[tmpDict copy]];
	}

      [tmpDict removeAllObjects];
      [icons removeObjectAtIndex:0];
      [extensions removeObjectAtIndex:0];
    }

  return resArray;
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
  [mf createPreambleForProject:self];

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
}

- (void)appendTail:(PCMakefileFactory *)mff
{
  [mff appendString:@"\n\n#\n# Makefiles\n#\n"];
  [mff appendString:@"-include GNUmakefile.preamble\n"];
  [mff appendString:@"include $(GNUSTEP_MAKEFILES)/aggregate.make\n"];
  [mff appendString:@"include $(GNUSTEP_MAKEFILES)/application.make\n"];
  [mff appendString:@"-include GNUmakefile.postamble\n"];
}

@end
