/*
   GNUstep ProjectCenter - http://www.gnustep.org

   Copyright (C) 2001-2004 Free Software Foundation

   Authors: Philippe C.D. Robert
            Serg Stoyan
	    
   Description: PCAppProj creates new project of the type Application!

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

#include "ProjectCenter/PCFileCreator.h"
#include "ProjectCenter/PCMakefileFactory.h"

#include "PCAppProj.h"
#include "PCAppProject.h"

@implementation PCAppProj

static PCAppProj *_creator = nil;

//----------------------------------------------------------------------------
// ProjectType
//----------------------------------------------------------------------------

+ (id)sharedCreator
{
  if (!_creator)
    {
      _creator = [[[self class] alloc] init];
    }

  return _creator;
}

- (Class)projectClass
{
  return [PCAppProject class];
}

- (NSString *)projectTypeName
{
  return @"Application";
}

- (PCProject *)createProjectAt:(NSString *)path
{
  PCAppProject  *project = nil;
  NSFileManager *fm = [NSFileManager defaultManager];

  NSAssert(path,@"No valid project path provided!");

  if ([fm createDirectoryAtPath: path attributes: nil]) 
    {
      NSString            *_file = nil;
      NSString            *_2file = nil;
      NSString            *_resourcePath = nil;
//      NSString            *_lresourcePath = nil;
      NSString            *projectName = nil;
      NSMutableDictionary *projectDict = nil;
      NSDictionary        *infoDict = nil;
      NSBundle            *projBundle = [NSBundle bundleForClass:[self class]];
      NSString            *mainNibFile = nil;
      PCFileCreator       *fc = [PCFileCreator sharedCreator];

      project = [[[PCAppProject alloc] init] autorelease];

      _file = [projBundle pathForResource:@"PC" ofType:@"project"];
      projectDict = [NSMutableDictionary dictionaryWithContentsOfFile:_file];

      // Customise the project
      projectName = [path lastPathComponent];
      if ([[projectName pathExtension] isEqualToString:@"subproj"])
	{
	  projectName = [projectName stringByDeletingPathExtension];
	}
      [projectDict setObject:projectName forKey:PCProjectName];
      [projectDict setObject:[self projectTypeName] forKey:PCProjectType];
      [projectDict setObject:[[NSCalendarDate date] description]
	              forKey:PCCreationDate];
      [projectDict setObject:NSFullUserName() forKey:PCProjectCreator];
      [projectDict setObject:NSFullUserName() forKey:PCProjectMaintainer];
      // The path cannot be in the PC.project file!
      [project setProjectPath:path];
      [project setProjectName:projectName];

      // Copy the project files to the provided path
      _file = [projBundle pathForResource:@"main" ofType:@"m"];
      _2file = [path stringByAppendingPathComponent:@"main.m"];
      [fm copyPath:_file toPath:_2file handler:nil];
      [fc replaceTagsInFileAtPath:_2file withProject:project];

      _file = [projBundle pathForResource:@"AppController" ofType:@"m"];
      _2file = [path stringByAppendingPathComponent:@"AppController.m"];
      [fm copyPath:_file toPath:_2file handler:nil];
      [fc replaceTagsInFileAtPath:_2file withProject:project];

      _file = [projBundle pathForResource:@"AppController" ofType:@"h"];
      _2file = [path stringByAppendingPathComponent:@"AppController.h"];
      [fm copyPath:_file toPath:_2file handler:nil];
      [fc replaceTagsInFileAtPath:_2file withProject:project];

      // GNUmakefile.postamble
      [[PCMakefileFactory sharedFactory] createPostambleForProject:project];

      // Resources
/*      _lresourcePath = [path stringByAppendingPathComponent:@"English.lproj"];
      [fm createDirectoryAtPath:_resourcePath attributes:nil];*/
      
      _resourcePath = [path stringByAppendingPathComponent:@"Resources"];
      [fm createDirectoryAtPath:_resourcePath attributes:nil];

      // Main NIB
      mainNibFile = [_resourcePath stringByAppendingPathComponent:
	[NSString stringWithFormat:@"%@.gorm", projectName]];

      _file = [projBundle pathForResource:@"Main" ofType:@"gorm"];
      [fm copyPath:_file toPath:mainNibFile handler:nil];
      [projectDict setObject:[mainNibFile lastPathComponent]
	              forKey:PCMainInterfaceFile];
      [projectDict 
	setObject:[NSArray arrayWithObject:[mainNibFile lastPathComponent]]
	   forKey:PCInterfaces];

      // Create the Info-gnutstep.plist
      infoDict = [NSDictionary dictionaryWithObjectsAndKeys:
	@"Generated by ProjectCenter, do not edit", @"!",
        @"No description avaliable!", @"ApplicationDescription",
	projectName, @"ApplicationName",
	@"0.1", @"ApplicationRelease",
	[NSArray array], @"Authors",
	@"Copyright (C) 200x by ...", @"Copyright",
	@"Released under...", @"CopyrightDescription",
	@"0.1", @"FullVersionID",
	projectName, @"NSExecutable",
	[mainNibFile lastPathComponent], @"NSMainNibFile",
	[projectDict objectForKey:PCPrincipalClass], @"NSPrincipalClass",
	@"Application", @"NSRole",
	nil];

      _2file = [_resourcePath 
	stringByAppendingPathComponent:@"Info-gnustep.plist"];
      [infoDict writeToFile:_2file atomically:YES];

      // Add Info-gnustep.plist into OTHER_RESOURCES
      [projectDict
	setObject:[NSArray arrayWithObjects:@"Info-gnustep.plist",nil] 
    	   forKey:PCOtherResources];

      // Set the new dictionary - this causes the GNUmakefile to be written 
      // to disc
      if(![project assignProjectDict:projectDict])
	{
	  NSRunAlertPanel(@"Attention!",
			  @"Could not load %@!",
			  @"OK", nil, nil, path);
	  return nil;
	}

      [project assignInfoDict:(NSMutableDictionary *)infoDict];

      // Save the project to disc
      [project save];
    }

  return project;
}

- (PCProject *)openProjectAt:(NSString *)path
{
  NSDictionary *dict = [NSDictionary dictionaryWithContentsOfFile:path];
  PCAppProject *project = nil;

  project = [[[PCAppProject alloc]
    initWithProjectDictionary:dict 
    path:[path stringByDeletingLastPathComponent]] autorelease];

  [project loadInfoFileAtPath:[path stringByDeletingLastPathComponent]];

  return project;
}

@end
