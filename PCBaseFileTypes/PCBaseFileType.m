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

#import "PCBaseFileType.h"
#import <ProjectCenter/PCProject.h>

#define ObjCNSViewClass	@"Objective-C NSView Subclass"
#define ObjCClass	@"Objective-C Class"
#define ObjCHeader	@"Objective-C Header"
#define CFile		@"C File"
#define CHeader	        @"C Header"
#define ProtocolFile	@"Objective-C Protocol"
#define GSMarkupFile	@"GSMarkup"

@implementation PCBaseFileType

static PCBaseFileType *_creator = nil;
static NSString *_name = @"BaseFileCreator";
static NSDictionary *dict = nil;

+ (id)sharedCreator
{
  if (!_creator) {
    NSDictionary *nsviewClassDict;
    NSDictionary *classDict;
    NSDictionary *headerDict;
    NSDictionary *ccDict;
    NSDictionary *chDict;
    NSDictionary *protocolDict;
    NSDictionary *gsmarkupDict;
    NSString     *descr;
    
    _creator = [[[self class] alloc] init];
    
    // Setting up the dictionary needed for registration!
    descr = [NSString stringWithString:@"Special Objective-C class.\n\nThis is a subclass of NSView which includes AppKit.h."];
    nsviewClassDict = [NSDictionary dictionaryWithObjectsAndKeys:
				_creator,@"Creator",
			      PCClasses,@"ProjectKey",
			      descr,@"TypeDescription",
			      nil];
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
				   ccDict,CFile,
				 chDict,CHeader,
				 protocolDict,ProtocolFile,
				 headerDict,ObjCHeader,
				 classDict,ObjCClass,
				 nsviewClassDict,ObjCNSViewClass,
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
  
  if ([type isEqualToString:ObjCClass]) 
  {
    _file = [[NSBundle bundleForClass:[self class]] pathForResource:@"class" ofType:@"template"];
    if ([[path pathExtension] isEqual: @"m"] == NO)
      newFile = [path stringByAppendingPathExtension:@"m"];
    [fm copyPath:_file toPath:newFile handler:nil];
    [files setObject:ObjCClass forKey:newFile];
    
    [self replaceTagsInFileAtPath:newFile withProject:aProject type:type];
    
    // Should a header be created as well?
    newFile = [path stringByAppendingPathExtension:@"h"];
    if (NSRunAlertPanel(@"Attention!",
                        @"Should %@ be created and inserted into the project?",
			@"Yes",@"No",nil,[newFile lastPathComponent])) 
    {
      _file = [[NSBundle bundleForClass:[self class]] pathForResource:@"header" ofType:@"template"];
      [fm copyPath:_file toPath:newFile handler:nil];
      
      [self replaceTagsInFileAtPath:newFile withProject:aProject type:ObjCHeader];
      [files setObject:ObjCHeader forKey:newFile];
    }
  }
  
  /*
   *
   */
  
  else if ([type isEqualToString:ObjCNSViewClass]) 
  {
    _file = [[NSBundle bundleForClass:[self class]] pathForResource:@"nsviewclass" ofType:@"template"];
    if ([[path pathExtension] isEqual: @"m"] == NO)
      newFile = [path stringByAppendingPathExtension:@"m"];
    [fm copyPath:_file toPath:newFile handler:nil];
    [files setObject:ObjCNSViewClass forKey:newFile];
    
    [self replaceTagsInFileAtPath:newFile withProject:aProject type:type];
    
    // Should a header be created as well?
    newFile = [path stringByAppendingPathExtension:@"h"];
    if (NSRunAlertPanel(@"Attention!",
                        @"Should %@ be created and inserted into the project?",
			@"Yes",@"No",nil,[newFile lastPathComponent])) 
    {
      _file = [[NSBundle bundleForClass:[self class]] pathForResource:@"nsviewheader" ofType:@"template"];
      [fm copyPath:_file toPath:newFile handler:nil];
      
      [self replaceTagsInFileAtPath:newFile withProject:aProject type:ObjCHeader];
      [files setObject:ObjCHeader forKey:newFile];
    }
  }

  /*
   *
   */
  
  else if ([type isEqualToString:CFile]) 
  {
    _file = [[NSBundle bundleForClass:[self class]] pathForResource:@"cfile" ofType:@"template"];
    if ([[path pathExtension] isEqual: @"c"] == NO)
      newFile = [path stringByAppendingPathExtension:@"c"];
    [fm copyPath:_file toPath:newFile handler:nil];
    [files setObject:CFile forKey:newFile];
    
    [self replaceTagsInFileAtPath:newFile withProject:aProject type:type];
    
    // Should a header be created as well?
    newFile = [path stringByAppendingPathExtension:@"h"];
    if (NSRunAlertPanel(@"Attention!",@"Should %@ be created and inserted in the project as well?",@"Yes",@"No",nil,[newFile lastPathComponent])) {
      _file = [[NSBundle bundleForClass:[self class]] pathForResource:@"cheader" ofType:@"template"];
      [fm copyPath:_file toPath:newFile handler:nil];
      
      [self replaceTagsInFileAtPath:newFile withProject:aProject type:CHeader];
      [files setObject:CHeader forKey:newFile];
    }
  }
  
  /*
   *
   */
  
  else if ([type isEqualToString:ObjCHeader]) 
  {
    _file = [[NSBundle bundleForClass:[self class]] pathForResource:@"header" ofType:@"template"];
    if ([[path pathExtension] isEqual: @"h"] == NO)
      newFile = [path stringByAppendingPathExtension:@"h"];
    [fm copyPath:_file toPath:newFile handler:nil];
    [self replaceTagsInFileAtPath:newFile withProject:aProject type:type];
    [files setObject:ObjCHeader forKey:newFile];
  }
  
 else if ([type isEqualToString:GSMarkupFile])
  {
    _file = [[NSBundle bundleForClass:[self class]] pathForResource:@"gsmarkup" ofType:@"template"];
    if ([[path pathExtension] isEqual: @"gsmarkup"] == NO)
      newFile = [path stringByAppendingPathExtension:@"gsmarkup"];
    [fm copyPath:_file toPath:newFile handler:nil];
    [files setObject:GSMarkupFile forKey:newFile];
  }



  /*
   *
   */
  
  else if ([type isEqualToString:CHeader]) 
  {
    _file = [[NSBundle bundleForClass:[self class]] pathForResource:@"cheader" ofType:@"template"];
    if ([[path pathExtension] isEqual: @"h"] == NO)
      newFile = [path stringByAppendingPathExtension:@"h"];
    [fm copyPath:_file toPath:newFile handler:nil];
    [self replaceTagsInFileAtPath:newFile withProject:aProject type:type];
    [files setObject:CHeader forKey:newFile];
  }

  /*
   *
   */
  
  else if ([type isEqualToString:ProtocolFile]) 
  {
    _file = [[NSBundle bundleForClass:[self class]] pathForResource:@"protocol" ofType:@"template"];
    if ([[path pathExtension] isEqual: @"h"] == NO)
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

    if ([aType isEqualToString:ObjCHeader] || [aType isEqualToString:CHeader]) 
    {
	NSString *nm = [[aFile stringByDeletingPathExtension] uppercaseString];

	[file replaceCharactersInRange:
	    [file rangeOfString:@"$UCFILENAMESANSEXTENSION$"] withString:nm];
	[file replaceCharactersInRange:
	    [file rangeOfString:@"$UCFILENAMESANSEXTENSION$"] withString:nm];
	[file replaceCharactersInRange:
	    [file rangeOfString:@"$UCFILENAMESANSEXTENSION$"] withString:nm];
    }

  if ([aType isEqualToString:ObjCClass] || 
      [aType isEqualToString:CFile] ||
      [aType isEqualToString:ObjCNSViewClass] ||
      [aType isEqualToString:ProtocolFile] ||
      [aType isEqualToString:ObjCHeader]) {
    NSString *name = [aFile stringByDeletingPathExtension];

    [file replaceCharactersInRange:
	    [file rangeOfString:@"$FILENAMESANSEXTENSION$"] withString:name];

    if ([aType isEqualToString:ObjCClass] ||
        [aType isEqualToString:ObjCNSViewClass]) 
    {
      [file replaceCharactersInRange:
	      [file rangeOfString:@"$FILENAMESANSEXTENSION$"] withString:name];
    }
  }

  [file writeToFile:newFile atomically:YES];
  [file autorelease];
}

@end


