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

#import "PCAppProject.h"
#import "PCAppMakefileFactory.h"

#import <ProjectCenter/ProjectCenter.h>

#if defined(GNUSTEP)
#import <AppKit/IMLoading.h>
#endif

@interface PCAppProject (CreateUI)

- (void)_initUI;

@end

@implementation PCAppProject (CreateUI)

- (void)_initUI
{
  NSTextField *textField;
  NSRect frame = {{84,120}, {80, 80}};
  NSBox *_box;

  [super _initUI];

  textField =[[NSTextField alloc] initWithFrame:NSMakeRect(16,256,64,21)];
  [textField setAlignment: NSRightTextAlignment];
  [textField setBordered: NO];
  [textField setEditable: NO];
  [textField setBezeled: NO];
  [textField setDrawsBackground: NO];
  [textField setStringValue:@"App class:"];
  [projectProjectInspectorView addSubview:[textField autorelease]];

  appClassField =[[NSTextField alloc] initWithFrame:NSMakeRect(84,256,176,21)];
  [appClassField setAlignment: NSLeftTextAlignment];
  [appClassField setBordered: YES];
  [appClassField setEditable: YES];
  [appClassField setBezeled: YES];
  [appClassField setDrawsBackground: YES];
  [appClassField setStringValue:@""];
  [projectProjectInspectorView addSubview:appClassField];

  textField =[[NSTextField alloc] initWithFrame:NSMakeRect(16,204,64,21)];
  [textField setAlignment: NSRightTextAlignment];
  [textField setBordered: NO];
  [textField setEditable: NO];
  [textField setBezeled: NO];
  [textField setDrawsBackground: NO];
  [textField setStringValue:@"App icon:"];
  [projectProjectInspectorView addSubview:[textField autorelease]];

  appImageField =[[NSTextField alloc] initWithFrame:NSMakeRect(84,204,176,21)];
  [appImageField setAlignment: NSLeftTextAlignment];
  [appImageField setBordered: YES];
  [appImageField setEditable: NO];
  [appImageField setBezeled: YES];
  [appImageField setDrawsBackground: YES];
  [appImageField setStringValue:@""];
  [projectProjectInspectorView addSubview:appImageField];

  setAppIconButton =[[NSButton alloc] initWithFrame:NSMakeRect(220,180,40,21)];
  [setAppIconButton setTitle:@"Set"];
  [setAppIconButton setTarget:self];
  [setAppIconButton setAction:@selector(setAppIcon:)];
  [projectProjectInspectorView addSubview:setAppIconButton];

  clearAppIconButton =[[NSButton alloc] initWithFrame:NSMakeRect(180,180,40,21)];
  [clearAppIconButton setTitle:@"Clear"];
  [clearAppIconButton setTarget:self];
  [clearAppIconButton setAction:@selector(clearAppIcon:)];
  [projectProjectInspectorView addSubview:clearAppIconButton];

  _box = [[NSBox alloc] init];
  [_box setFrame:frame];
  [_box setTitlePosition:NSNoTitle];
  [_box setBorderType:NSBezelBorder];
  [projectProjectInspectorView addSubview:_box];
  
  appIconView = [[NSImageView alloc] initWithFrame:frame];
  [_box addSubview:appIconView];

  RELEASE(_box);
  RELEASE(setAppIconButton);
  RELEASE(clearAppIconButton);
  RELEASE(appIconView);
}

@end

@implementation PCAppProject

//----------------------------------------------------------------------------
// Init and free
//----------------------------------------------------------------------------

- (id)init
{
  if ((self = [super init])) {
    rootCategories = [[NSDictionary dictionaryWithObjectsAndKeys:
				      PCGModels,@"Interfaces",
				    PCImages,@"Images",
				    PCOtherResources,@"Other Resources",
				    PCSubprojects,@"Subprojects",
				    PCLibraries,@"Libraries",
				    PCDocuFiles,@"Documentation",
				    PCOtherSources,@"Other Sources",
				    PCHeaders,@"Headers",
				    PCClasses,@"Classes",
				    nil] retain];

    [self _initUI];
  }
  return self;
}

- (void)dealloc
{
  [rootCategories release];
  [appClassField release];
  [appImageField release];

  [super dealloc];
}

//----------------------------------------------------------------------------
// Project
//----------------------------------------------------------------------------

- (BOOL)writeMakefile
{
    NSFileManager *fm = [NSFileManager defaultManager];
    NSString *makefile = [projectPath stringByAppendingPathComponent:@"GNUmakefile"];
    NSData *content;

    if (![super writeMakefile]) {
        NSLog(@"Couldn't update PC.project...");
    }
    
    if (![fm movePath:makefile toPath:[projectPath stringByAppendingPathComponent:@"GNUmakefile~"] handler:nil]) {
        NSLog(@"Couldn't write a backup GNUmakefile...");
    }

    if (!(content = [[PCAppMakefileFactory sharedFactory] makefileForProject:self])) {
        NSLog([NSString stringWithFormat:@"Couldn't build the GNUmakefile %@!",makefile]);
        return NO;
    }

    if (![content writeToFile:makefile atomically:YES]) {
        NSLog([NSString stringWithFormat:@"Couldn't write the GNUmakefile %@!",makefile]);
        return NO;
    }
    return YES;
}

- (BOOL)isValidDictionary:(NSDictionary *)aDict
{
#warning No project check implemented, yet!
    return YES;
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
    return [NSArray arrayWithObjects:PCDocuFiles,PCSupportingFiles,nil];
}

- (NSArray *)buildTargets
{
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
  NSRect frame = {{0,0}, {64, 64}};
  NSImage *image;
  NSString *path = nil;
  NSString *_icon;

  [super updateValuesFromProjectDict];

  [appClassField setStringValue:[projectDict objectForKey:PCAppClass]];
  [appImageField setStringValue:[projectDict objectForKey:PCAppIcon]];

  if ((_icon = [projectDict objectForKey:PCAppIcon])) {
    path = [projectPath stringByAppendingPathComponent:_icon];
  }

  if (path && (image = [[NSImage alloc] initWithContentsOfFile:path])) {
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
  [self writeMakefile];
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

  [self writeMakefile];

  return YES;
}

@end
