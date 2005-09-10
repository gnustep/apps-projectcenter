/*
   GNUstep ProjectCenter - http://www.gnustep.org/experience/ProjectCenter.html

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
#include "ProjectCenter/PCFileManager.h"
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
  PCAppProject        *project = nil;
  PCFileManager       *pcfm = [PCFileManager defaultManager];
  PCFileCreator       *pcfc = [PCFileCreator sharedCreator];
  NSString            *_file = nil;
  NSString            *_2file = nil;
  NSString            *_resourcePath = nil;
  NSString            *projectName = nil;
  NSMutableDictionary *projectDict = nil;
  NSDictionary        *infoDict = nil;
  NSBundle            *projBundle = [NSBundle bundleForClass:[self class]];
  NSString            *mainNibFile = nil;

  NSAssert(path,@"No valid project path provided!");

  project = [[[PCAppProject alloc] init] autorelease];

  // PC.project
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
  _2file = [path stringByAppendingPathComponent:
    [NSString stringWithFormat:@"%@_main.m", projectName]];
  [pcfm copyFile:_file toFile:_2file];
  [pcfc replaceTagsInFileAtPath:_2file withProject:project];
  [projectDict 
    setObject:[NSArray arrayWithObjects:[_2file lastPathComponent],nil]
       forKey:PCOtherSources];

  _file = [projBundle pathForResource:@"AppController" ofType:@"m"];
  _2file = [path stringByAppendingPathComponent:@"AppController.m"];
  [pcfm copyFile:_file toFile:_2file];
  [pcfc replaceTagsInFileAtPath:_2file withProject:project];

  _file = [projBundle pathForResource:@"AppController" ofType:@"h"];
  _2file = [path stringByAppendingPathComponent:@"AppController.h"];
  [pcfm copyFile:_file toFile:_2file];
  [pcfc replaceTagsInFileAtPath:_2file withProject:project];

  // GNUmakefile.postamble
  [[PCMakefileFactory sharedFactory] createPostambleForProject:project];

  // Resources
  // By default resources located at Resources subdir until Info-gnustep.plist
  // will remain not licalisable file. In the future it should be English.lproj.
  _resourcePath = [path stringByAppendingPathComponent:@"Resources"];

  // Main NIB
  _file = [projBundle pathForResource:@"Main" ofType:@"gorm"];
  mainNibFile = [NSString stringWithFormat:@"%@.gorm", projectName];
  mainNibFile = [_resourcePath stringByAppendingPathComponent:mainNibFile];
  [pcfm copyFile:_file toFile:mainNibFile];

  [projectDict setObject:[mainNibFile lastPathComponent]
                  forKey:PCMainInterfaceFile];

  // Renaissance
  _file = [projBundle pathForResource:@"Main" ofType:@"gsmarkup"];
  _2file = [_resourcePath stringByAppendingPathComponent:@"Main.gsmarkup"];
  [pcfm copyFile:_file toFile:_2file];
  _file = [projBundle pathForResource:@"MainMenu-GNUstep" ofType:@"gsmarkup"];
  _2file = [_resourcePath 
    stringByAppendingPathComponent:@"MainMenu-GNUstep.gsmarkup"];
  [pcfm copyFile:_file toFile:_2file];
  _file = [projBundle pathForResource:@"MainMenu-OSX" ofType:@"gsmarkup"];
  _2file = [_resourcePath 
    stringByAppendingPathComponent:@"MainMenu-OSX.gsmarkup"];
  [pcfm copyFile:_file toFile:_2file];

  [projectDict setObject:[NSArray arrayWithObjects:[mainNibFile lastPathComponent], @"Main.gsmarkup", @"MainMenu-GNUstep.gsmarkup", @"MainMenu-OSX.gsmarkup", nil] 
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

  _2file = [_resourcePath stringByAppendingPathComponent:@"Info-gnustep.plist"];
  [infoDict writeToFile:_2file atomically:YES];

  // Add Info-gnustep.plist into OTHER_RESOURCES
  [projectDict setObject:[NSArray arrayWithObjects:@"Info-gnustep.plist",nil] 
                  forKey:PCOtherResources];

  // Set the new dictionary - this causes the GNUmakefile to be written 
  // to disc
  if (![project assignProjectDict:projectDict])
    {
      NSRunAlertPanel(@"Attention!",
		      @"Could not load %@!",
		      @"OK", nil, nil, path);
      return nil;
    }

  [project assignInfoDict:(NSMutableDictionary *)infoDict];

  // Save the project to disc
  [project save];

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
