/*
   GNUstep ProjectCenter - http://www.gnustep.org

   Copyright (C) 2001 Free Software Foundation

   Author: Philippe C.D. Robert <phr@3dkit.org>

   Description: creates new project of the type Bundle!

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

#include <Foundation/NSString.h>
#include <ProjectCenter/PCFileCreator.h>

#include "PCBundleProj.h"
#include "PCBundleProject.h"

@implementation PCBundleProj

static PCBundleProj *_creator = nil;

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
  return [PCBundleProject class];
}

- (NSString *)projectTypeName
{
  return @"Bundle";
}

- (PCProject *)createProjectAt:(NSString *)path
{
  PCBundleProject *project = nil;
  NSFileManager   *fm = [NSFileManager defaultManager];

  NSAssert(path,@"No valid project path provided!");

  if ([fm createDirectoryAtPath:path attributes:nil])
    {
      NSBundle            *projectBundle;
      NSString            *_file;
      NSString            *_2file;
//      NSString            *_resourcePath;
      NSMutableDictionary *projectDict;
      PCFileCreator       *pcfc = [PCFileCreator sharedCreator];

      project = [[[PCBundleProject alloc] init] autorelease];

      projectBundle = [NSBundle bundleForClass:[self class]];

      _file = [projectBundle pathForResource:@"PC" ofType:@"project"];
      projectDict = [NSMutableDictionary dictionaryWithContentsOfFile:_file];

      // Customise the project
      [project setProjectName:[path lastPathComponent]];
      [projectDict setObject:[path lastPathComponent] forKey:PCProjectName];
      [projectDict setObject:[self projectTypeName] forKey:PCProjectType];
      [projectDict setObject:[path lastPathComponent] forKey:PCPrincipalClass];

      // Copy the project files to the provided path
      _file = [projectBundle pathForResource:@"GNUmakefile" 
                                      ofType:@"postamble"];
      _2file = [path stringByAppendingPathComponent:@"GNUmakefile.postamble"];
      [fm copyPath:_file toPath:_2file handler:nil];

      _file = [projectBundle pathForResource:@"GNUmakefile" ofType:@"preamble"];
      _2file = [path stringByAppendingPathComponent:@"GNUmakefile.preamble"];
      [fm copyPath:_file toPath:_2file handler:nil];
      
      // $PROJECTNAME$.m
      _file = [NSString stringWithFormat:@"%@", [path lastPathComponent]];
      _2file = [NSString stringWithFormat:@"%@.m", [path lastPathComponent]];
      [pcfc createFileOfType:ObjCClass 
	                path:[path stringByAppendingPathComponent:_file]
		     project:project];
      [projectDict setObject:[NSArray arrayWithObjects:_2file,nil]
	              forKey:PCClasses];

      // $PROJECTNAME$.h already created by creating $PROJECTNAME$.m
      _file = [NSString stringWithFormat:@"%@.h", [path lastPathComponent]];
      [projectDict setObject:[NSArray arrayWithObjects:_file,nil]
	              forKey:PCHeaders];

      // Resources
/*      _resourcePath = [path stringByAppendingPathComponent:@"English.lproj"];
      [fm createDirectoryAtPath:_resourcePath attributes:nil];*/
      [fm createDirectoryAtPath:
	[path stringByAppendingPathComponent:@"Images"]
	             attributes:nil];
      [fm createDirectoryAtPath:
	[path stringByAppendingPathComponent:@"Documentation"]
	             attributes:nil];

      // The path cannot be in the PC.project file!
      [project setProjectPath:path];

      // Set the new dictionary - this causes the GNUmakefile to be written
      if (![project assignProjectDict:projectDict])
	{
	  NSRunAlertPanel(@"Attention!",
			  @"Could not load %@!",
			  @"OK",nil,nil,path);
	  return nil;
	}

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

  return [[[PCBundleProject alloc] initWithProjectDictionary:dict
    path:[path stringByDeletingLastPathComponent]] autorelease];
}

@end
