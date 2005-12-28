/*
   GNUstep ProjectCenter - http://www.gnustep.org/experience/ProjectCenter.html

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

#include <ProjectCenter/PCDefines.h>
#include <ProjectCenter/PCProject.h>
#include <ProjectCenter/PCFileManager.h>
#include <ProjectCenter/PCFileCreator.h>

#include <ProjectCenter/PCLogController.h>

@implementation PCFileCreator

static PCFileCreator *_creator = nil;
static NSString      *_name = @"FileCreator";
static NSDictionary  *dict = nil;

+ (id)sharedCreator
{
  if (_creator == nil)
    {
      NSDictionary *classDict;
      NSDictionary *headerDict;
      NSDictionary *ccDict;
      NSDictionary *chDict;
      NSDictionary *protocolDict;
      NSDictionary *gsmarkupDict;
      NSString     *descr;

      _creator = [[[self class] alloc] init];

      // Setting up the dictionary needed for registration!
      descr = [NSString stringWithString:@"Generic Objective-C class.\n\nThis is a plain subclass of NSObject which includes only Foundation.h."];
      classDict = [NSDictionary dictionaryWithObjectsAndKeys:
	_creator,@"Creator",
        PCClasses,@"ProjectKey",
        descr,@"TypeDescription",
        nil];

      descr = [NSString stringWithString:@"Generic Objective-C header.\n\nThis is a plain interface subclassing NSObject. The file includes Foundation.h"];
      headerDict =[NSDictionary dictionaryWithObjectsAndKeys:
	_creator,@"Creator",
        PCHeaders,@"ProjectKey",
        descr,@"TypeDescription",
        nil];

      descr = [NSString stringWithString:@"Generic ANSI-C implementation file.\n\nThis file contains no Objective-C dependency in any form."];
      ccDict = [NSDictionary dictionaryWithObjectsAndKeys:
	_creator,@"Creator",
        PCOtherSources,@"ProjectKey",
        descr,@"TypeDescription",
        nil];

      descr = [NSString stringWithString:@"Generic ANSI-C header.\n\nThis file contains no Objective-C dependency in any form."];
      chDict = [NSDictionary dictionaryWithObjectsAndKeys:
	_creator,@"Creator",
        PCHeaders,@"ProjectKey",
        descr,@"TypeDescription",
        nil];

      descr = [NSString stringWithString:@"Generic Objective-C protocol.\n\nThis is common Objective-C protocol, comparable i.e. to a Java interface."];
      protocolDict = [NSDictionary dictionaryWithObjectsAndKeys:
	_creator,@"Creator",
        PCHeaders,@"ProjectKey",
        descr,@"TypeDescription",
        nil];

      descr = [NSString stringWithString:@"Generic GSMarkup File.\n\nThis is the interface description of GNUstep Renaissance."];
      gsmarkupDict =[NSDictionary dictionaryWithObjectsAndKeys:
	_creator,@"Creator",
        PCGSMarkupFiles,@"ProjectKey",
        descr,@"TypeDescription",
        nil];


      dict = [[NSDictionary alloc] initWithObjectsAndKeys:
	ccDict, CFile,
        chDict, CHeader,
        protocolDict, ProtocolFile,
        headerDict, ObjCHeader,
        classDict, ObjCClass,
        gsmarkupDict, GSMarkupFile,
	nil];
    }

  return _creator;
}

- (NSString *)name
{
  return _name;
}

- (NSDictionary *)creatorDictionary
{
  return dict;
}

- (NSDictionary *)createFileOfType:(NSString *)type 
                              path:(NSString *)path 
		           project:(PCProject *)aProject
{
  PCFileManager       *pcfm = [PCFileManager defaultManager];
  NSString            *_file = nil;
  NSString            *newFile = nil;
  NSMutableDictionary *files = nil;
  NSBundle            *bundle = nil;

  // A class and possibly a header
  files = [NSMutableDictionary dictionaryWithCapacity:2];

  PCLogStatus(self, @"create %@ at %@", type, path);

  bundle = [NSBundle bundleForClass:[self class]];
  newFile = [path copy];

  // Remove file extension from "path"
  if (![[path pathExtension] isEqualToString: @""])
    {
      path = [path stringByDeletingPathExtension];
    }
  
  /*
   * Objective-C Class
   */
  if ([type isEqualToString:ObjCClass]) 
    {
      _file = [bundle pathForResource:@"class" ofType:@"template"];
      newFile = [path stringByAppendingPathExtension:@"m"];
      [pcfm copyFile:_file toFile:newFile];
      [self replaceTagsInFileAtPath:newFile withProject:aProject];
      [files setObject:ObjCClass forKey:newFile];
    }

  /*
   * Objective-C Header
   * When creating Objective C Class file also create Objective C Header file
   */
  if ([type isEqualToString:ObjCHeader] ||
      [type isEqualToString:ObjCClass])
    {
      _file = [bundle pathForResource:@"header" ofType:@"template"];
      newFile = [path stringByAppendingPathExtension:@"h"];
      [pcfm copyFile:_file toFile:newFile];
      [self replaceTagsInFileAtPath:newFile withProject:aProject];
      [files setObject:ObjCHeader forKey:newFile];
    }

  /*
   * C File
   */
  if ([type isEqualToString:CFile]) 
    {
      _file = [bundle pathForResource:@"cfile" ofType:@"template"];
      newFile = [path stringByAppendingPathExtension:@"c"];
      [pcfm copyFile:_file toFile:newFile];
      [self replaceTagsInFileAtPath:newFile withProject:aProject];
      [files setObject:CFile forKey:newFile];
    }

  /*
   * C Header
   * When creating C file also create C Header file
   */
  if ([type isEqualToString:CHeader] ||
      [type isEqualToString:CFile]) 
    {
      _file = [bundle pathForResource:@"cheader" ofType:@"template"];
      newFile = [path stringByAppendingPathExtension:@"h"];
      [pcfm copyFile:_file toFile:newFile];
      [self replaceTagsInFileAtPath:newFile withProject:aProject];
      [files setObject:CHeader forKey:newFile];
    }
  /*
   * GSMarkup
   */
  else if ([type isEqualToString:GSMarkupFile])
    {
      _file = [bundle pathForResource:@"gsmarkup" ofType:@"template"];
      newFile = [path stringByAppendingPathExtension:@"gsmarkup"];
      [pcfm copyFile:_file toFile:newFile];
      [files setObject:GSMarkupFile forKey:newFile];
    }
  /*
   * Objective-C Protocol
   */
  else if ([type isEqualToString:ProtocolFile]) 
    {
      _file = [bundle pathForResource:@"protocol" ofType:@"template"];
      newFile = [path stringByAppendingPathExtension:@"h"];
      [pcfm copyFile:_file toFile:newFile];
      [self replaceTagsInFileAtPath:newFile withProject:aProject];
      [files setObject:ProtocolFile forKey:newFile];
    }

  /*
   * Notify the browser!
   */
  [[NSNotificationCenter defaultCenter] 
    postNotificationName:@"ProjectDictDidChangeNotification"
                  object:self];

  return files;
}

- (void)replaceTagsInFileAtPath:(NSString *)newFile
                    withProject:(PCProject *)aProject
{
  NSString *projectName = [aProject projectName];
  NSString *date = [[NSCalendarDate calendarDate] description];
  int      year = [[NSCalendarDate calendarDate] yearOfCommonEra];
  NSString *aFile = [newFile lastPathComponent];
  NSString *UCfn = [[aFile stringByDeletingPathExtension] uppercaseString];
  NSString *fn = [aFile stringByDeletingPathExtension];
  NSRange  subRange;

  file = [[NSMutableString stringWithContentsOfFile:newFile] retain];

  while ((subRange = [file rangeOfString:@"$FULLFILENAME$"]).length)
    {
      [file replaceCharactersInRange:subRange withString:aFile];
    }
    
  while ((subRange = [file rangeOfString:@"$FILENAME$"]).length)
    {
      [file replaceCharactersInRange:subRange withString:fn];
    }

  while ((subRange = [file rangeOfString:@"$UCFILENAME$"]).length)
    {
      [file replaceCharactersInRange:subRange withString:UCfn];
    }

  while ((subRange = [file rangeOfString:@"$USERNAME$"]).length)
    {
      [file replaceCharactersInRange:subRange withString:NSUserName()];
    }
    
  while ((subRange = [file rangeOfString:@"$FULLUSERNAME$"]).length)
    {
      [file replaceCharactersInRange:subRange withString:NSFullUserName()];
    }

  while ((subRange = [file rangeOfString:@"$PROJECTNAME$"]).length)
    {
      [file replaceCharactersInRange:subRange withString:projectName];
    }

  while ((subRange = [file rangeOfString:@"$DATE$"]).length)
    {
      [file replaceCharactersInRange:subRange withString:date];
    }
    
  while ((subRange = [file rangeOfString:@"$YEAR$"]).length)
    {
      [file replaceCharactersInRange:subRange 
	withString:[[NSNumber numberWithInt:year] stringValue]];
    }

  [file writeToFile:newFile atomically:YES];
  [file autorelease];
}

@end


