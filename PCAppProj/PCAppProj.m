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

static NSString *_projTypeName = @"Application";
static PCAppProj *_creator = nil;

//----------------------------------------------------------------------------
// ProjectType
//----------------------------------------------------------------------------

+ (id)sharedCreator
{
    if (!_creator) {
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
    return _projTypeName;
}

- (NSDictionary *)typeTable
{
    NSString *_path = [[NSBundle bundleForClass:[self class]] pathForResource:@"Info" ofType:@"table"];

    return [NSDictionary dictionaryWithContentsOfFile:_path];
}

- (PCProject *)createProjectAt:(NSString *)path
{
    PCAppProject *project = nil;
    NSFileManager *fm = [NSFileManager defaultManager];

    NSAssert(path,@"No valid project path provided!");

    if ([fm createDirectoryAtPath:path attributes:nil]) 
    {
        NSString *_file;
        NSString *_resourcePath;
        NSMutableDictionary *dict;
        NSDictionary *infoDict;
	NSString *plistFileName;
	NSString *projectFile;

        project = [[[PCAppProject alloc] init] autorelease];

        _file = [[NSBundle bundleForClass:[self class]] pathForResource:@"PC" 
	                                                        ofType:@"proj"];
        dict = [NSMutableDictionary dictionaryWithContentsOfFile:_file];
                
        // Customise the project
        [dict setObject:[path lastPathComponent] forKey:PCProjectName];
#ifndef GNUSTEP_BASE_VERSION
        [dict setObject:[[project principalClass] description] forKey:PCProjType];
#else
        [dict setObject:[project principalClass] forKey:PCProjType];
#endif
	// Create the AppNameInfo.plist
	infoDict = [NSDictionary dictionaryWithObjectsAndKeys:
				   @"Automatically generated!",@"NOTE",
				   [path lastPathComponent],@"ApplicationName",
				   @"",@"ApplicationDescription",
				   @"",@"ApplicationIcon",
				   @"0.1",@"ApplicationRelease",
				   @"0.1",@"FullVersionID",
				   @"",@"Authors",
				   @"",@"URL",
				   @"Copyright (C) 200x by ...",@"Copyright",
				   @"Released under...",@"CopyrightDescription",
				   nil];
	plistFileName = [NSString stringWithFormat:@"%@Info.plist",
	                                           [path lastPathComponent]];
	[infoDict writeToFile:[path stringByAppendingPathComponent:plistFileName] atomically:YES];

        [dict setObject:[NSArray arrayWithObjects:plistFileName,nil] 
	         forKey:PCOtherResources];

        // Save the project to disc
	//projectFile = [NSString stringWithString:@"PC.project"];
	projectFile = [NSString stringWithString:[path lastPathComponent]];
	projectFile = [projectFile stringByAppendingPathExtension:@"pcproj"];
        
        [dict writeToFile:[path stringByAppendingPathComponent:projectFile] 
	       atomically:YES];

	/*
	 * Copy the project files to the provided path
	 *
	 */
        
        _file = [[NSBundle bundleForClass:[self class]] pathForResource:@"GNUmakefile" ofType:@"postamble"];
        [fm copyPath:_file toPath:[path stringByAppendingPathComponent:@"GNUmakefile.postamble"] handler:nil];
        
        _file = [[NSBundle bundleForClass:[self class]] pathForResource:@"GNUmakefile" ofType:@"preamble"];
        [fm copyPath:_file toPath:[path stringByAppendingPathComponent:@"GNUmakefile.preamble"] handler:nil];

        _file = [[NSBundle bundleForClass:[self class]] pathForResource:@"main" ofType:@"m"];
        [fm copyPath:_file toPath:[path stringByAppendingPathComponent:@"main.m"] handler:nil];

        _file = [[NSBundle bundleForClass:[self class]] pathForResource:@"AppController" ofType:@"m"];
        [fm copyPath:_file toPath:[path stringByAppendingPathComponent:@"AppController.m"] handler:nil];

        _file = [[NSBundle bundleForClass:[self class]] pathForResource:@"AppController" ofType:@"h"];
        [fm copyPath:_file toPath:[path stringByAppendingPathComponent:@"AppController.h"] handler:nil];

        // Resources
        _resourcePath = [path stringByAppendingPathComponent:@"English.lproj"];
        [fm createDirectoryAtPath:_resourcePath attributes:nil];
        [fm createDirectoryAtPath:[path stringByAppendingPathComponent:@"Images"] attributes:nil];
        [fm createDirectoryAtPath:[path stringByAppendingPathComponent:@"Documentation"] attributes:nil];

        // The path cannot be in the PC.project file!
        [project setProjectPath:path];

        // Set the new dictionary - this causes the GNUmakefile to be written to disc
        if(![project assignProjectDict:dict]) {
            NSRunAlertPanel(@"Attention!",@"Could not load %@!",@"OK",nil,nil,path);
            return nil;
        }
    }
    return project;
}

- (PCProject *)openProjectAt:(NSString *)path
{
    NSDictionary *dict = [NSDictionary dictionaryWithContentsOfFile:path];
    id obj;

    NSLog(@"<%@ %x>: opening project at %@",[self class],self,path);

    obj = [dict objectForKey:PCProjectBuilderClass];    
    if ([obj isEqualToString:@"PCAppProj"]) {
      return [[[PCAppProject alloc] initWithProjectDictionary:dict path:[path stringByDeletingLastPathComponent]] autorelease];
    }
    return nil;
}

@end
