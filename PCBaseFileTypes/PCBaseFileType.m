/*
   GNUstep ProjectCenter - http://www.projectcenter.ch

   Copyright (C) 2000 Philippe C.D. Robert

   Author: Philippe C.D. Robert <phr@projectcenter.ch>

   This file is part of ProjectCenter.

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

#import "PCBaseFileType.h"
#import <ProjectCenter/PCProject.h>

#define ObjCClass	@"ObjC Class"
#define ObjCHeader	@"ObjC Header"
#define CFile		@"C File"
#define CHeaderFile	@"C Header"
#define ProtocolFile	@"ObjC Protocol"

@implementation PCBaseFileType

static PCBaseFileType *_creator = nil;
static NSString *_name = @"BaseFileCreator";
static NSDictionary *dict = nil;

+ (id)sharedCreator
{
  if (!_creator) {
    NSDictionary *classDict;
    NSDictionary *headerDict;
    NSDictionary *ccDict;
    NSDictionary *chDict;
    NSDictionary *protocolDict;
    
    _creator = [[[self class] alloc] init];
    
    // Setting up the dictionary needed for registration!
    classDict = [NSDictionary dictionaryWithObjectsAndKeys:
				_creator,@"Creator",
			      PCClasses,@"ProjectKey",
			      nil];
    headerDict =[NSDictionary dictionaryWithObjectsAndKeys:
				_creator,@"Creator",
			      PCHeaders,@"ProjectKey",
			      nil];
    ccDict = [NSDictionary dictionaryWithObjectsAndKeys:
			     _creator,@"Creator",
			   PCOtherSources,@"ProjectKey",
			   nil];
    chDict = [NSDictionary dictionaryWithObjectsAndKeys:
			     _creator,@"Creator",
			   PCHeaders,@"ProjectKey",
			   nil];
    protocolDict = [NSDictionary dictionaryWithObjectsAndKeys:
				   _creator,@"Creator",
				 PCHeaders,@"ProjectKey",
				 nil];
    
    dict = [[NSDictionary alloc] initWithObjectsAndKeys:
				   ccDict,CFile,
				 chDict,CHeaderFile,
				 protocolDict,ProtocolFile,
				 headerDict,ObjCHeader,
				 classDict,ObjCClass,
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

- (NSDictionary *)createFileOfType:(NSString *)type path:(NSString *)path project:(PCProject *)aProject
{
  NSFileManager *fm = [NSFileManager defaultManager];
  NSString *_file;
  NSString *newFile = nil;
  NSMutableDictionary *files;
  
  // A class and possibly a header
  files = [NSMutableDictionary dictionaryWithCapacity:2];
  
  NSLog(@"<%@ %x>: create %@ at %@",[self class],self,type,path);
  
  /*
   *
   */
  
  if ([type isEqualToString:ObjCClass]) {
    _file = [[NSBundle bundleForClass:[self class]] pathForResource:@"class" ofType:@"template"];
    newFile = [path stringByAppendingPathExtension:@"m"];
    [fm copyPath:_file toPath:newFile handler:nil];
    [files setObject:ObjCClass forKey:newFile];
    
    [self replaceTagsInFileAtPath:newFile withProject:aProject type:type];
    
    // Should a header be created as well?
    newFile = [path stringByAppendingPathExtension:@"h"];
    if (NSRunAlertPanel(@"Attention!",@"Should %@ be created and inserted in the project as well?",@"Yes",@"No",nil,[newFile lastPathComponent])) {
      _file = [[NSBundle bundleForClass:[self class]] pathForResource:@"header" ofType:@"template"];
      [fm copyPath:_file toPath:newFile handler:nil];
      
      [self replaceTagsInFileAtPath:newFile withProject:aProject type:ObjCHeader];
      [files setObject:ObjCHeader forKey:newFile];
    }        
  }
  
  /*
   *
   */
  
  else if ([type isEqualToString:CFile]) {
    _file = [[NSBundle bundleForClass:[self class]] pathForResource:@"cfile" ofType:@"template"];
    newFile = [path stringByAppendingPathExtension:@"c"];
    [fm copyPath:_file toPath:newFile handler:nil];
    [files setObject:CFile forKey:newFile];
    
    [self replaceTagsInFileAtPath:newFile withProject:aProject type:type];
    
    // Should a header be created as well?
    newFile = [path stringByAppendingPathExtension:@"h"];
    if (NSRunAlertPanel(@"Attention!",@"Should %@ be created and inserted in the project as well?",@"Yes",@"No",nil,[newFile lastPathComponent])) {
      _file = [[NSBundle bundleForClass:[self class]] pathForResource:@"cheader" ofType:@"template"];
      [fm copyPath:_file toPath:newFile handler:nil];
      
      [self replaceTagsInFileAtPath:newFile withProject:aProject type:CHeaderFile];
      [files setObject:CHeaderFile forKey:newFile];
    }
  }
  
  /*
   *
   */
  
  else if ([type isEqualToString:ObjCHeader]) {
    _file = [[NSBundle bundleForClass:[self class]] pathForResource:@"header" ofType:@"template"];
    newFile = [path stringByAppendingPathExtension:@"h"];
    [fm copyPath:_file toPath:newFile handler:nil];
    [self replaceTagsInFileAtPath:newFile withProject:aProject type:type];
    [files setObject:ObjCHeader forKey:newFile];
  }
  
  /*
   *
   */
  
  else if ([type isEqualToString:CHeaderFile]) {
    _file = [[NSBundle bundleForClass:[self class]] pathForResource:@"cheader" ofType:@"template"];
    newFile = [path stringByAppendingPathExtension:@"h"];
    [fm copyPath:_file toPath:newFile handler:nil];
    [self replaceTagsInFileAtPath:newFile withProject:aProject type:type];
    [files setObject:CHeaderFile forKey:newFile];
  }

  /*
   *
   */
  
  else if ([type isEqualToString:ProtocolFile]) {
    _file = [[NSBundle bundleForClass:[self class]] pathForResource:@"protocol" ofType:@"template"];
    newFile = [path stringByAppendingPathExtension:@"h"];
    [fm copyPath:_file toPath:newFile handler:nil];
    [self replaceTagsInFileAtPath:newFile withProject:aProject type:type];
    [files setObject:ProtocolFile forKey:newFile];
  }
  
  /*
   * Notify the browser!
   */
  
  [[NSNotificationCenter defaultCenter] postNotificationName:@"ProjectDictDidChangeNotification" object:self];
  
  return files;
}

- (void)replaceTagsInFileAtPath:(NSString *)newFile withProject:(PCProject *)aProject type:(NSString *)aType
{
  NSString *user = NSUserName();
  NSString *pname = [aProject projectName];
  NSString *date = [[NSCalendarDate calendarDate] description];
  NSString *aFile = [newFile lastPathComponent];
  
  file = [[NSMutableString stringWithContentsOfFile:newFile] retain];

  [file replaceCharactersInRange:
	  [file rangeOfString:@"$FILENAME$"] withString:aFile];

  [file replaceCharactersInRange:
	  [file rangeOfString:@"$USERNAME$"] withString:user];

  [file replaceCharactersInRange:
	  [file rangeOfString:@"$PROJECTNAME$"] withString:pname];

  [file replaceCharactersInRange:
	  [file rangeOfString:@"$DATE$"] withString:date];

  if ([aType isEqualToString:ObjCClass] || 
      [aType isEqualToString:CFile] ||
      [aType isEqualToString:ProtocolFile] ||
      [aType isEqualToString:ObjCHeader]) {
    NSString *name = [aFile stringByDeletingPathExtension];

    [file replaceCharactersInRange:
	    [file rangeOfString:@"$FILENAMESANSEXTENSION$"] withString:name];

    if ([aType isEqualToString:ObjCHeader] || 
        [aType isEqualToString:CHeaderFile]) {
	[file replaceCharactersInRange:
	    [file rangeOfString:@"$UCFILENAMESANSEXTENSION$"] withString:name];
	[file replaceCharactersInRange:
	    [file rangeOfString:@"$UCFILENAMESANSEXTENSION$"] withString:name];
	[file replaceCharactersInRange:
	    [file rangeOfString:@"$UCFILENAMESANSEXTENSION$"] withString:name];
    }

    if ([aType isEqualToString:ObjCClass]) {
      [file replaceCharactersInRange:
	      [file rangeOfString:@"$FILENAMESANSEXTENSION$"] withString:name];
    }
  }

  [file writeToFile:newFile atomically:YES];
  [file autorelease];
}

@end


