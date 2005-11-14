/*
   GNUstep ProjectCenter - http://www.gnustep.org

   Copyright (C) 2001-2004 Free Software Foundation

   Authors: Philippe C.D. Robert
            Pierre-Yves Rivaille
            Daniel Luederwald
	    Serg Stoyan
	    
   Description: Creates new project of the type RenaissanceApplication!

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

#include <ProjectCenter/PCFileCreator.h>
#include <ProjectCenter/PCMakefileFactory.h>

#include "PCRenaissanceProj.h"
#include "PCRenaissanceProject.h"

@implementation PCRenaissanceProj

static PCRenaissanceProj *_creator = nil;

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
  return [PCRenaissanceProject class];
}

- (NSString *)projectTypeName
{
  return @"Renaissance Application";
}

- (PCProject *)createProjectAt:(NSString *)path
{
  PCRenaissanceProject *project = nil;
  NSFileManager        *fm = [NSFileManager defaultManager];

  NSAssert(path,@"No valid project path provided!");

  if ([fm createDirectoryAtPath:path attributes:nil])
    {
      NSBundle            *projectBundle = nil;
      NSMutableDictionary *projectDict = nil;
      NSString            *projectName = nil;
      NSString            *_file = nil;
      NSString            *_2file = nil;
//      NSString            *_lresourcePath = nil;
      NSString            *_resourcePath = nil;
      NSDictionary        *infoDict = nil;
      NSString            *mainMarkup = nil;
      PCFileCreator       *fc = [PCFileCreator sharedCreator];

      project = [[[PCRenaissanceProject alloc] init] autorelease];
      projectBundle = [NSBundle bundleForClass:[self class]];

      _file = [projectBundle pathForResource:@"PC" ofType:@"project"];
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
      _file = [projectBundle pathForResource:@"main" ofType:@"m"];
      _2file = [path stringByAppendingPathComponent:@"main.m"];
      [fm copyPath:_file toPath:_2file handler:nil];
      [fc replaceTagsInFileAtPath:_2file withProject:project];

      _file = [projectBundle pathForResource:@"AppController" ofType:@"m"];
      _2file = [path stringByAppendingPathComponent:@"AppController.m"];
      [fm copyPath:_file toPath:_2file handler:nil];
      [fc replaceTagsInFileAtPath:_2file withProject:project];

      _file = [projectBundle pathForResource:@"AppController" ofType:@"h"];
      _2file = [path stringByAppendingPathComponent:@"AppController.h"];
      [fm copyPath:_file toPath:_2file handler:nil];
      [fc replaceTagsInFileAtPath:_2file withProject:project];

      // GNUmakefile.postamble
      [[PCMakefileFactory sharedFactory] createPostambleForProject:project];

      // GNUmakefile.postamble
      [[PCMakefileFactory sharedFactory] createPostambleForProject:project];

      // Resources
/*      _lresourcePath = [path stringByAppendingPathComponent:@"English.lproj"];
      [fm createDirectoryAtPath:_resourcePath attributes:nil];*/
      _resourcePath = [path stringByAppendingPathComponent:@"Resources"];
      [fm createDirectoryAtPath:_resourcePath attributes:nil];

#ifdef GNUSTEP      
      _file = [projectBundle pathForResource:@"MainMenu-GNUstep" 
	                              ofType:@"gsmarkup"];
      _2file = [_resourcePath stringByAppendingPathComponent:
	                                     @"MainMenu-GNUstep.gsmarkup"];
      mainMarkup = [NSString stringWithString:@"MainMenu-GNUstep.gsmarkup"];

      [fm copyPath:_file toPath:_2file handler:nil];
#else
      _file = [projectBundle pathForResource:@"MainMenu-OSX" 
	                              ofType:@"gsmarkup"];
      _2file = [_resourcePath stringByAppendingPathComponent:
                                             @"MainMenu-OSX.gsmarkup"];
      [fm copyPath:_file toPath:_2file handler:nil];

      mainMarkup = [NSString stringWithString:@"MainMenu-OSX.gsmarkup"];
#endif
      [projectDict setObject:mainMarkup forKey:PCMainInterfaceFile];
		      
      _file = [projectBundle pathForResource:@"Main" ofType:@"gsmarkup"];
      _2file = [_resourcePath stringByAppendingPathComponent:@"Main.gsmarkup"];
      [fm copyPath:_file toPath:_2file handler:nil];
      [projectDict setObject:
	[NSArray arrayWithObjects:@"Main.gsmarkup",mainMarkup,nil]
	              forKey:PCInterfaces];


      // Create the Info-gnustep.plist
      infoDict = [NSDictionary dictionaryWithObjectsAndKeys:
	@"Generated by ProjectCenter, do not edit", @"!",
      @"", @"ApplicationDescription",
      @"", @"ApplicationIcon",
      projectName, @"ApplicationName",
      @"0.1", @"ApplicationRelease",
      [NSArray array], @"Authors",
      @"Copyright (C) 200x by ...", @"Copyright",
      @"Released under...", @"CopyrightDescription",
      @"0.1", @"FullVersionID",
      projectName, @"NSExecutable",
      @"", @"NSIcon",
      mainMarkup, @"GSMainMarkupFile",
      [projectDict objectForKey:PCPrincipalClass], @"NSPrincipalClass",
      @"Application", @"NSRole",
      @"", @"URL",
      nil];

      _2file = [_resourcePath 
	stringByAppendingPathComponent:@"Info-gnustep.plist"];
      [infoDict writeToFile:_2file atomically:YES];

      [projectDict 
	setObject:[NSArray arrayWithObjects:@"Info-gnustep.plist",nil] 
	   forKey:PCOtherResources];

      // Set the new dictionary - this causes the GNUmakefile 
      // to be written to disc
      if (![project assignProjectDict:projectDict])
	{
	  NSRunAlertPanel(@"Attention!",
			  @"Could not load %@!",
			  @"OK",nil,nil,path);
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
  NSDictionary         *dict = [NSDictionary dictionaryWithContentsOfFile:path];
  PCRenaissanceProject *project = nil;

  project = [[[PCRenaissanceProject alloc]
    initWithProjectDictionary:dict 
    path:[path stringByDeletingLastPathComponent]] autorelease];

  [project loadInfoFileAtPath:[path stringByDeletingLastPathComponent]];

  return project;

}

@end
