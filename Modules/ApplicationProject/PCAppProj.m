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

/*
 Description:

 PCAppProj creates new project of the type Application!
*/

#include "PCAppProj.h"
#include "PCAppProject.h"

@implementation PCAppProj

//static NSString  *_projTypeName = @"Application";
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

- (NSDictionary *)typeTable
{
  NSString *_path;
  
  _path = [[NSBundle bundleForClass:[self class]] pathForResource:@"Info"
                                                           ofType:@"table"];

  return [NSDictionary dictionaryWithContentsOfFile:_path];
}

- (PCProject *)createProjectAt:(NSString *)path
{
  PCAppProject  *project = nil;
  NSFileManager *fm = [NSFileManager defaultManager];

  NSAssert(path,@"No valid project path provided!");

  if ([fm createDirectoryAtPath: path attributes: nil]) 
    {
      NSString            *_file = nil;
//      NSString            *_resourcePath = nil;
      NSMutableDictionary *projectDict = nil;
      NSDictionary        *infoDict = nil;
      NSBundle            *projBundle = [NSBundle bundleForClass:[self class]];
      NSString            *mainNibFile = nil;

      project = [[[PCAppProject alloc] init] autorelease];

      _file = [projBundle pathForResource:@"PC" ofType:@"project"];
      projectDict = [NSMutableDictionary dictionaryWithContentsOfFile:_file];

      // Customise the project
      [projectDict setObject:[path lastPathComponent] forKey:PCProjectName];
      [projectDict setObject:[self projectTypeName] forKey:PCProjectType];
      [projectDict setObject:[[NSCalendarDate date] description]
	              forKey:PCCreationDate];
      [projectDict setObject:NSFullUserName() forKey:PCProjectCreator];
      [projectDict setObject:NSFullUserName() forKey:PCProjectMaintainer];

      // Copy the project files to the provided path
      _file = [projBundle pathForResource:@"GNUmakefile" ofType:@"postamble"];
      [fm copyPath:_file 
            toPath:[path stringByAppendingPathComponent:@"GNUmakefile.postamble"]
	   handler:nil];

      _file = [projBundle pathForResource:@"GNUmakefile" ofType:@"preamble"];
      [fm copyPath:_file 
            toPath:[path stringByAppendingPathComponent:@"GNUmakefile.preamble"] 
	   handler:nil];

      _file = [projBundle pathForResource:@"main" ofType:@"m"];
      [fm copyPath:_file
            toPath:[path stringByAppendingPathComponent:@"main.m"]
           handler:nil];

      _file = [projBundle pathForResource:@"AppController" ofType:@"m"];
      [fm copyPath:_file 
            toPath:[path stringByAppendingPathComponent:@"AppController.m"]
           handler:nil];

      _file = [projBundle pathForResource:@"AppController" ofType:@"h"];
      [fm copyPath:_file
            toPath:[path stringByAppendingPathComponent:@"AppController.h"]
	   handler:nil];

      // Resources
/*      _resourcePath = [path stringByAppendingPathComponent:@"English.lproj"];
      [fm createDirectoryAtPath:_resourcePath
                     attributes:nil];*/
      [fm createDirectoryAtPath:[path stringByAppendingPathComponent:@"Images"]
                     attributes:nil];
      [fm createDirectoryAtPath:[path stringByAppendingPathComponent:@"Documentation"]
	             attributes:nil];

      // Gorm files
      mainNibFile = [path stringByAppendingPathComponent:
	[NSString stringWithFormat:@"%@.gorm", [path lastPathComponent]]];
      [fm createDirectoryAtPath:mainNibFile attributes:nil];

      _file = [projBundle pathForResource:@"objects" ofType:@"gorm"];
      [fm copyPath:_file
            toPath:[mainNibFile stringByAppendingPathComponent:@"objects.gorm"]
	   handler:nil];
      _file = [projBundle pathForResource:@"data" ofType:@"classes"];
      [fm copyPath:_file
            toPath:[mainNibFile stringByAppendingPathComponent:@"data.classes"]
	   handler:nil];
      [projectDict setObject:[mainNibFile lastPathComponent]
	              forKey:PCMainInterfaceFile];
      
      [projectDict 
	setObject:[NSArray arrayWithObject:[mainNibFile lastPathComponent]]
	   forKey:PCInterfaces];

      // Create the Info-gnutstep.plist
      infoDict = [NSDictionary dictionaryWithObjectsAndKeys:
	@"Generated by ProjectCenter, do not edit", @"!",
//        @"", @"ApplicationDescription",
//	@"", @"ApplicationIcon",
	[path lastPathComponent], @"ApplicationName",
	@"0.1", @"ApplicationRelease",
	[NSArray array], @"Authors",
	@"Copyright (C) 200x by ...", @"Copyright",
	@"Released under...", @"CopyrightDescription",
	@"0.1", @"FullVersionID",
	[path lastPathComponent], @"NSExecutable",
//	@"", @"NSIcon",
	[mainNibFile lastPathComponent], @"NSMainNibFile",
	[projectDict objectForKey:PCPrincipalClass], @"NSPrincipalClass",
	@"Application", @"NSRole",
//	@"", @"URL",
	nil];

      [infoDict 
	writeToFile:[path stringByAppendingPathComponent:@"Info-gnustep.plist"]
	 atomically:YES];

      // Add Info-gnustep.plist into OTHER_RESOURCES
      [projectDict
	setObject:[NSArray arrayWithObjects:@"Info-gnustep.plist",nil] 
    	   forKey:PCOtherResources];

      // The path cannot be in the PC.project file!
      [project setProjectPath:path];

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
      [projectDict
	writeToFile:[path stringByAppendingPathComponent:@"PC.project"] 
	 atomically:YES];

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
