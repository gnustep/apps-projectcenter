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

#include "PCProject+UInterface.h"
#include "PCAppProject.h"
#include "PCAppProj.h"

#include <ProjectCenter/ProjectCenter.h>

@interface PCAppProject (CreateUI)

- (void)_initUI;

@end

@implementation PCAppProject (CreateUI)

- (void)_initUI
{
  NSTextField *textField;
  NSRect      frame;
  NSBox       *_iconViewBox;
  NSBox       *_appIconBox;

  [super _initUI];

  // Application Class
  textField = [[NSTextField alloc] initWithFrame:NSMakeRect(4,248,104,21)];
  [textField setAlignment: NSRightTextAlignment];
  [textField setBordered: NO];
  [textField setEditable: NO];
  [textField setBezeled: NO];
  [textField setDrawsBackground: NO];
  [textField setStringValue:@"Application Class:"];
  [projectProjectInspectorView addSubview:textField];
  RELEASE(textField);

  appClassField = [[NSTextField alloc] initWithFrame:
    NSMakeRect(111,248,165,21)];
  [appClassField setAlignment: NSLeftTextAlignment];
  [appClassField setBordered: YES];
  [appClassField setEditable: YES];
  [appClassField setBezeled: YES];
  [appClassField setDrawsBackground: YES];
  [appClassField setStringValue:@""];
  [appClassField setTarget:self];
  [appClassField setAction:@selector(setAppClass:)];
  [projectProjectInspectorView addSubview:appClassField];
  RELEASE(appClassField);

  // Application Icon
  _appIconBox = [[NSBox alloc] init];
  [_appIconBox setFrame:NSMakeRect(6,154,270,84)];
  [_appIconBox setContentViewMargins:NSMakeSize(4.0, 6.0)];
  [_appIconBox setTitle:@"Application Icon"];
  [projectProjectInspectorView addSubview:_appIconBox];
  RELEASE(_appIconBox);
  
  appImageField = [[NSTextField alloc] initWithFrame:NSMakeRect(0,34,195,21)];
  [appImageField setAlignment: NSLeftTextAlignment];
  [appImageField setBordered: YES];
  [appImageField setEditable: YES];
  [appImageField setBezeled: YES];
  [appImageField setDrawsBackground: YES];
  [appImageField setStringValue:@""];
  [_appIconBox addSubview:appImageField];
  RELEASE(appImageField);

  setAppIconButton = [[NSButton alloc] initWithFrame:NSMakeRect(147,0,48,21)];
  [setAppIconButton setTitle:@"Set..."];
  [setAppIconButton setTarget:self];
  [setAppIconButton setAction:@selector(setAppIcon:)];
  [_appIconBox addSubview:setAppIconButton];
  RELEASE(setAppIconButton);

  clearAppIconButton = [[NSButton alloc] initWithFrame:NSMakeRect(95,0,48,21)];
  [clearAppIconButton setTitle:@"Clear"];
  [clearAppIconButton setTarget:self];
  [clearAppIconButton setAction:@selector(clearAppIcon:)];
  [_appIconBox addSubview:clearAppIconButton];
  RELEASE(clearAppIconButton);

  frame = NSMakeRect(200,0,56,56);
  _iconViewBox = [[NSBox alloc] init];
  [_iconViewBox setFrame:frame];
  [_iconViewBox setTitlePosition:NSNoTitle];
  [_iconViewBox setBorderType:NSBezelBorder];
  [_appIconBox addSubview:_iconViewBox];
  RELEASE(_iconViewBox);
  
  appIconView = [[NSImageView alloc] initWithFrame:frame];
  [_iconViewBox addSubview:appIconView];
  RELEASE(appIconView);
}

@end

@implementation PCAppProject

//----------------------------------------------------------------------------
// Init and free
//----------------------------------------------------------------------------

- (id)init
{
  if ((self = [super init]))
    {
      rootObjects = [[NSArray arrayWithObjects: PCClasses,
						PCHeaders,
						PCOtherSources,
						PCGModels,
						PCImages,
						PCOtherResources,
						PCSubprojects,
						PCDocuFiles,
						PCSupportingFiles,
						PCLibraries,
						PCNonProject,
						nil] retain];

      rootKeys = [[NSArray arrayWithObjects: @"Classes",
					     @"Headers",
					     @"Other Sources",
					     @"Interfaces",
					     @"Images",
					     @"Other Resources",
					     @"Subprojects",
					     @"Documentation",
//					     @"Context Help",
					     @"Supporting Files",
//					     @"Frameworks",
					     @"Libraries",
					     @"Non Project Files",
					     nil] retain];

      rootCategories = [[NSDictionary 
	dictionaryWithObjects:rootObjects forKeys:rootKeys] retain];

    }
  return self;
}

- (void)dealloc
{
  [rootCategories release];
  [rootObjects release];
  [rootKeys release];

  [super dealloc];
}

//----------------------------------------------------------------------------
// Project
//----------------------------------------------------------------------------

- (Class)builderClass
{
    return [PCAppProj class];
}

- (BOOL)writeMakefile
{
    NSData   *mfd;
    NSString *mfl = [projectPath stringByAppendingPathComponent:@"GNUmakefile"];
    int i; 
    PCMakefileFactory *mf = [PCMakefileFactory sharedFactory];
    NSDictionary      *dict = [self projectDict];

    // Save the project file
    [super writeMakefile];
    
    // Create the new file
    [mf createMakefileForProject:[self projectName]];

    [mf appendString:@"include $(GNUSTEP_MAKEFILES)/common.make\n"];
    
    [mf appendSubprojects:[dict objectForKey:PCSubprojects]];

    [mf appendApplication];
    [mf appendAppIcon:[dict objectForKey:PCAppIcon]];
    [mf appendGuiLibraries:[dict objectForKey:PCLibraries]];

    [mf appendResources];
    for (i=0;i<[[self resourceFileKeys] count];i++)
    {
        NSString *k = [[self resourceFileKeys] objectAtIndex:i];
        [mf appendResourceItems:[dict objectForKey:k]];
    }

    [mf appendHeaders:[dict objectForKey:PCHeaders]];
    [mf appendClasses:[dict objectForKey:PCClasses]];
    [mf appendOtherSources:[dict objectForKey:PCOtherSources]];

    [mf appendTailForApp];

    // Write the new file to disc!
    if ((mfd = [mf encodedMakefile])) 
    {
        if ([mfd writeToFile:mfl atomically:YES]) 
        {
            return YES;
        }
    }

    return NO;
}

- (NSArray *)sourceFileKeys
{
    return [NSArray arrayWithObjects:PCClasses,PCOtherSources,nil];
}

- (NSArray *)resourceFileKeys
{
    return [NSArray arrayWithObjects:PCGModels,PCOtherResources,PCImages,nil];
}

- (NSArray *)otherKeys
{
    return [NSArray arrayWithObjects:PCDocuFiles,PCSupportingFiles, 
    PCNonProject,nil];
}

- (NSArray *)buildTargets
{
  return nil;
}

- (NSString *)projectDescription
{
    return @"Project that handles GNUstep/ObjC based applications.";
}

- (BOOL)isExecutable
{
  return YES;
}

- (void)updateValuesFromProjectDict
{
  NSRect   frame = {{0,0}, {48,48}};
  NSImage  *image = nil;
  NSString *path = nil;
  NSString *_icon = nil;

  [super updateValuesFromProjectDict];

  [appClassField setStringValue:[projectDict objectForKey:PCAppClass]];
  [appImageField setStringValue:[projectDict objectForKey:PCAppIcon]];

  _icon = [projectDict objectForKey:PCAppIcon];
  if (_icon && ![_icon isEqualToString:@""])
    {
      path = [projectPath stringByAppendingPathComponent:_icon];
    }

  if (path && (image = [[NSImage alloc] initWithContentsOfFile:path]))
    {
      frame.size = [image size];
      [appIconView setFrame:frame];
      [appIconView setImage:image];
      [appIconView display];
      RELEASE(image);
    }
}

- (void)clearAppIcon:(id)sender
{
    [projectDict setObject:@"" forKey:PCAppIcon];
    [appImageField setStringValue:@"No Icon!"];
    [appIconView setImage:nil];
    [appIconView display];

    [projectWindow setDocumentEdited:YES];
}

- (void)setAppIcon:(id)sender
{
  int result;  
  NSArray *fileTypes = [NSImage imageFileTypes];
  NSOpenPanel *openPanel = [NSOpenPanel openPanel];

  [openPanel setAllowsMultipleSelection:NO];
  result = [openPanel runModalForDirectory:NSHomeDirectory()
		      file:nil 
		      types:fileTypes];
  
  if (result == NSOKButton) {
    NSArray *files = [openPanel filenames];
    NSString *imageFilePath = [files objectAtIndex:0];      

    if (![self setAppIconWithImageAtPath:imageFilePath]) {
      NSRunAlertPanel(@"Error while opening file!", 
		      @"Couldn't open %@", @"OK", nil, nil,imageFilePath);
    }
  }  
}

- (BOOL)setAppIconWithImageAtPath:(NSString *)path
{
    NSRect frame = {{0,0}, {64, 64}};
    NSImage *image;

    if (!(image = [[NSImage alloc] initWithContentsOfFile:path])) {
	return NO;
    }

    [self addFile:path forKey:PCImages copy:YES];
    [projectDict setObject:[path lastPathComponent] forKey:PCAppIcon];

    [appImageField setStringValue:[path lastPathComponent]];

    frame.size = [image size];
    [appIconView setFrame:frame];
    [appIconView setImage:image];
    [appIconView display];
    RELEASE(image);

    [projectWindow setDocumentEdited:YES];

    return YES;
}

- (void)setAppClass:(id)sender
{
    [projectDict setObject:[appClassField stringValue] forKey:PCAppClass];

    [projectWindow setDocumentEdited:YES];
}

@end
