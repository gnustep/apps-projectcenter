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

#include <ProjectCenter/ProjectCenter.h>
#include <ProjectCenter/PCProjectBrowser.h>

#include "PCAppProject.h"
#include "PCAppProj.h"

@implementation PCAppProject

// ----------------------------------------------------------------------------
// --- Init and free
// ----------------------------------------------------------------------------

- (id)init
{

  if ((self = [super init]))
    {
      rootObjects = [[NSArray arrayWithObjects: PCClasses,
						PCHeaders,
						PCOtherSources,
						PCInterfaces,
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

- (void)assignInfoDict:(NSMutableDictionary *)dict
{
  infoDict = [dict mutableCopy];
}

- (void)loadInfoFileAtPath:(NSString *)path
{
  NSString *infoFile = nil;

  infoFile = [path stringByAppendingPathComponent:@"Info-gnustep.plist"];
  infoDict = [[NSMutableDictionary alloc] initWithContentsOfFile:infoFile];
}

- (void)dealloc
{
  NSLog (@"PCAppProject: dealloc");

  RELEASE(infoDict);
  RELEASE(buildAttributesView);
  RELEASE(projectAttributesView);
  RELEASE(fileAttributesView);

  RELEASE(rootCategories);
  RELEASE(rootObjects);
  RELEASE(rootKeys);

  [super dealloc];
}

// ----------------------------------------------------------------------------
// --- User Interface
// ----------------------------------------------------------------------------

- (void)createInspectors
{
  NSTextField *textField = nil;
  NSBox       *_iconViewBox = nil;
  NSBox       *_appIconBox = nil;
  NSBox       *line = nil;

  if (buildAttributesView && projectAttributesView && fileAttributesView)
    {
      return;
    }

  /*
   * "Build Attributes" View
   */
  buildAttributesView = [[NSBox alloc] init];
  [buildAttributesView setFrame:NSMakeRect(0,0,295,364)];
  [buildAttributesView setTitlePosition:NSNoTitle];
  [buildAttributesView 
    setAutoresizingMask:(NSViewWidthSizable | NSViewHeightSizable)];
  [buildAttributesView setContentViewMargins:NSMakeSize(0.0, 0.0)];

  // Compiler Flags -- ADDITIONAL_OBJCFLAGS(?), ADDITIONAL_CFLAGS
  textField =[[NSTextField alloc] initWithFrame:NSMakeRect(4,323,104,21)];
  [textField setAlignment: NSRightTextAlignment];
  [textField setBordered: NO];
  [textField setEditable: NO];
  [textField setBezeled: NO];
  [textField setDrawsBackground: NO];
  [textField setStringValue:@"Compiler Flags:"];
  [buildAttributesView addSubview:textField];
  RELEASE(textField);

  ccOptField =[[NSTextField alloc] initWithFrame:NSMakeRect(111,323,165,21)];
  [ccOptField setAlignment: NSLeftTextAlignment];
  [ccOptField setBordered: YES];
  [ccOptField setEditable: YES];
  [ccOptField setBezeled: YES];
  [ccOptField setDrawsBackground: YES];
  [ccOptField setStringValue:@""];
  [ccOptField setAction:@selector(changeCommonProjectEntry:)];
  [ccOptField setTarget:self];
  [buildAttributesView addSubview:ccOptField];
  RELEASE(ccOptField);

  // Linker Flags -- ADDITIONAL_LDFLAGS
  textField =[[NSTextField alloc] initWithFrame:NSMakeRect(4,298,104,21)];
  [textField setAlignment: NSRightTextAlignment];
  [textField setBordered: NO];
  [textField setEditable: NO];
  [textField setBezeled: NO];
  [textField setDrawsBackground: NO];
  [textField setStringValue:@"Linker Flags:"];
  [buildAttributesView addSubview:textField];
  RELEASE(textField);

  ldOptField =[[NSTextField alloc] initWithFrame:NSMakeRect(111,298,165,21)];
  [ldOptField setAlignment: NSLeftTextAlignment];
  [ldOptField setBordered: YES];
  [ldOptField setEditable: YES];
  [ldOptField setBezeled: YES];
  [ldOptField setDrawsBackground: YES];
  [ldOptField setStringValue:@""];
  [ldOptField setAction:@selector(changeCommonProjectEntry:)];
  [ldOptField setTarget:self];
  [buildAttributesView addSubview:ldOptField];
  RELEASE(ldOptField);

  // Install In
  textField =[[NSTextField alloc] initWithFrame:NSMakeRect(4,273,104,21)];
  [textField setAlignment: NSRightTextAlignment];
  [textField setBordered: NO];
  [textField setEditable: NO];
  [textField setBezeled: NO];
  [textField setDrawsBackground: NO];
  [textField setStringValue:@"Install In:"];
  [buildAttributesView addSubview:textField];
  RELEASE(textField);

  installPathField =[[NSTextField alloc] 
    initWithFrame:NSMakeRect(111,273,165,21)];
  [installPathField setAlignment: NSLeftTextAlignment];
  [installPathField setBordered: YES];
  [installPathField setEditable: YES];
  [installPathField setBezeled: YES];
  [installPathField setDrawsBackground: YES];
  [installPathField setStringValue:@""];
  [installPathField setAction:@selector(changeCommonProjectEntry:)];
  [installPathField setTarget:self];
  [buildAttributesView addSubview:installPathField];
  RELEASE(installPathField);

  // Build Tool
  textField =[[NSTextField alloc] initWithFrame:NSMakeRect(4,248,104,21)];
  [textField setAlignment: NSRightTextAlignment];
  [textField setBordered: NO];
  [textField setEditable: NO];
  [textField setBezeled: NO];
  [textField setDrawsBackground: NO];
  [textField setStringValue:@"Build Tool:"];
  [buildAttributesView addSubview:textField];
  RELEASE(textField);

  toolField =[[NSTextField alloc] initWithFrame:NSMakeRect(111,248,165,21)];
  [toolField setAlignment: NSLeftTextAlignment];
  [toolField setBordered: YES];
  [toolField setEditable: YES];
  [toolField setBezeled: YES];
  [toolField setDrawsBackground: YES];
  [toolField setStringValue:@""];
  [toolField setAction:@selector(changeCommonProjectEntry:)];
  [toolField setTarget:self];
  [buildAttributesView addSubview:toolField];
  RELEASE(toolField);

  // Public Headers In -- ADDITIONAL_INCLUDE_DIRS
  textField =[[NSTextField alloc] initWithFrame:NSMakeRect(4,223,104,21)];
  [textField setAlignment: NSRightTextAlignment];
  [textField setBordered: NO];
  [textField setEditable: NO];
  [textField setBezeled: NO];
  [textField setDrawsBackground: NO];
  [textField setStringValue:@"Public Headers In:"];
  [buildAttributesView addSubview:textField];
  RELEASE(textField);

  headersField =[[NSTextField alloc] initWithFrame:NSMakeRect(111,223,165,21)];
  [headersField setAlignment: NSLeftTextAlignment];
  [headersField setBordered: YES];
  [headersField setEditable: YES];
  [headersField setBezeled: YES];
  [headersField setDrawsBackground: YES];
  [headersField setStringValue:@""];
  [headersField setAction:@selector(changeCommonProjectEntry:)];
  [headersField setTarget:self];
  [buildAttributesView addSubview:headersField];
  RELEASE(headersField);

  // Public Libraries In -- ADDITIONAL_TOOL_LIBS
  textField =[[NSTextField alloc] initWithFrame:NSMakeRect(4,198,104,21)];
  [textField setAlignment: NSRightTextAlignment];
  [textField setBordered: NO];
  [textField setEditable: NO];
  [textField setBezeled: NO];
  [textField setDrawsBackground: NO];
  [textField setStringValue:@"Public Libraries In:"];
  [buildAttributesView addSubview:textField];
  RELEASE(textField);

  libsField =[[NSTextField alloc] initWithFrame:NSMakeRect(111,198,165,21)];
  [libsField setAlignment: NSLeftTextAlignment];
  [libsField setBordered: YES];
  [libsField setEditable: YES];
  [libsField setBezeled: YES];
  [libsField setDrawsBackground: YES];
  [libsField setStringValue:@""];
  [libsField setAction:@selector(changeCommonProjectEntry:)];
  [libsField setTarget:self];
  [buildAttributesView addSubview:libsField];
  RELEASE(libsField);


  /*
   * "Project Attributes" View
   */
  projectAttributesView = [[NSBox alloc] init];
  [projectAttributesView setFrame:NSMakeRect(0,0,295,364)];
  [projectAttributesView setTitlePosition:NSNoTitle];
  [projectAttributesView 
    setAutoresizingMask:(NSViewWidthSizable | NSViewHeightSizable)];
  [projectAttributesView setContentViewMargins:NSMakeSize(0.0, 0.0)];

  // Project Type
  textField = [[NSTextField alloc] initWithFrame:NSMakeRect(4,323,104,21)];
  [textField setAlignment: NSRightTextAlignment];
  [textField setBordered: NO];
  [textField setEditable: NO];
  [textField setBezeled: NO];
  [textField setDrawsBackground: NO];
  [textField setStringValue:@"Project Type:"];
  [projectAttributesView addSubview:textField];
  RELEASE(textField);

  projectTypeField = [[NSTextField alloc] initWithFrame:
    NSMakeRect(111,323,165,21)];
  [projectTypeField setAlignment: NSLeftTextAlignment];
  [projectTypeField setBordered: NO];
  [projectTypeField setEditable: NO];
  [projectTypeField setSelectable: NO];
  [projectTypeField setBezeled: NO];
  [projectTypeField setDrawsBackground: NO];
  [projectTypeField setFont:[NSFont boldSystemFontOfSize: 12.0]];
  [projectTypeField setStringValue:@""];
  [projectAttributesView addSubview:projectTypeField];
  RELEASE(projectTypeField);

  // Project Name
  textField = [[NSTextField alloc] initWithFrame:NSMakeRect(4,298,104,21)];
  [textField setAlignment: NSRightTextAlignment];
  [textField setBordered: NO];
  [textField setEditable: NO];
  [textField setBezeled: NO];
  [textField setDrawsBackground: NO];
  [textField setStringValue:@"Project Name:"];
  [projectAttributesView addSubview:textField];
  RELEASE(textField);

  projectNameField = [[NSTextField alloc] initWithFrame:
    NSMakeRect(111,298,165,21)];
  [projectNameField setAlignment: NSLeftTextAlignment];
  [projectNameField setBordered: NO];
  [projectNameField setEditable: NO];
  [projectNameField setBezeled: YES];
  [projectNameField setDrawsBackground: YES];
  [projectNameField setStringValue:@""];
  [projectAttributesView addSubview:projectNameField];
  RELEASE(projectNameField);

  // Project Language
  textField = [[NSTextField alloc] initWithFrame:NSMakeRect(4,273,104,21)];
  [textField setAlignment: NSRightTextAlignment];
  [textField setBordered: NO];
  [textField setEditable: NO];
  [textField setBezeled: NO];
  [textField setDrawsBackground: NO];
  [textField setStringValue:@"Language:"];
  [projectAttributesView addSubview:textField];
  RELEASE(textField);

  projectLanguageField = [[NSTextField alloc] initWithFrame:
    NSMakeRect(111,273,165,21)];
  [projectLanguageField setAlignment: NSLeftTextAlignment];
  [projectLanguageField setBordered: NO];
  [projectLanguageField setEditable: NO];
  [projectLanguageField setBezeled: YES];
  [projectLanguageField setDrawsBackground: YES];
  [projectLanguageField setStringValue:@""];
  [projectAttributesView addSubview:projectLanguageField];
  RELEASE(projectLanguageField);

  // Application Class
  textField = [[NSTextField alloc] initWithFrame:NSMakeRect(4,248,104,21)];
  [textField setAlignment: NSRightTextAlignment];
  [textField setBordered: NO];
  [textField setEditable: NO];
  [textField setBezeled: NO];
  [textField setDrawsBackground: NO];
  [textField setStringValue:@"Application Class:"];
  [projectAttributesView addSubview:textField];
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
  [projectAttributesView addSubview:appClassField];
  RELEASE(appClassField);

  // Application Icon
  _appIconBox = [[NSBox alloc] init];
  [_appIconBox setFrame:NSMakeRect(6,154,270,84)];
  [_appIconBox setContentViewMargins:NSMakeSize(4.0, 6.0)];
  [_appIconBox setTitle:@"Application Icon"];
  [projectAttributesView addSubview:_appIconBox];
  
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

  _iconViewBox = [[NSBox alloc] initWithFrame:NSMakeRect(200,0,56,56)];
  [_iconViewBox setTitlePosition:NSNoTitle];
  [_iconViewBox setBorderType:NSBezelBorder];
  [_iconViewBox setContentViewMargins:NSMakeSize(2.0, 2.0)];
  [_appIconBox addSubview:_iconViewBox];
  RELEASE(_iconViewBox);
  
  appIconView = [[NSImageView alloc] initWithFrame:NSMakeRect(200,0,56,56)];
  [_iconViewBox addSubview:appIconView];
  RELEASE(appIconView);

  RELEASE(_appIconBox);

  /*
   * "File Attributes" View
   */
  fileAttributesView = [[NSBox alloc] init];
  [fileAttributesView setFrame:NSMakeRect(0,0,295,364)];
  [fileAttributesView setTitlePosition:NSNoTitle];
  [fileAttributesView setAutoresizingMask:
    (NSViewWidthSizable | NSViewHeightSizable)];
  [fileAttributesView setContentViewMargins:NSMakeSize(0.0, 0.0)];

  fileIconView = [[NSImageView alloc] initWithFrame:NSMakeRect(8,290,48,48)];
  [fileIconView setImage:nil];
  [fileAttributesView addSubview:fileIconView];
  RELEASE(fileIconView);

  fileNameField =[[NSTextField alloc] initWithFrame:NSMakeRect(60,290,216,48)];
  [fileNameField setAlignment: NSLeftTextAlignment];
  [fileNameField setBordered: NO];
  [fileNameField setEditable: NO];
  [fileNameField setSelectable: NO];
  [fileNameField setBezeled: NO];
  [fileNameField setDrawsBackground: NO];
  [fileNameField setFont:[NSFont systemFontOfSize:20.0]];
  [fileNameField setStringValue:@"No files selected"];
  [fileAttributesView addSubview:fileNameField];
  RELEASE(fileNameField);

  line = [[NSBox alloc] initWithFrame:NSMakeRect(0,278,295,2)];
  [line setTitlePosition:NSNoTitle];
  [fileAttributesView addSubview:line];
  RELEASE(line);

  [[NSNotificationCenter defaultCenter] 
    addObserver:self
       selector:@selector(browserDidSetPath:)
           name:PCBrowserDidSetPathNotification
         object:[self projectBrowser]];

  [self updateInspectorValues:nil];
}

- (NSView *)buildAttributesView
{
  if (!buildAttributesView)
    {
      [self createInspectors];
    }

  return buildAttributesView;
}

- (NSView *)projectAttributesView
{
  if (!projectAttributesView)
    {
      [self createInspectors];
    }
  return projectAttributesView;
}

- (NSView *)fileAttributesView
{
  if (!fileAttributesView)
    {
      [self createInspectors];
    }
  return fileAttributesView;
}

// ----------------------------------------------------------------------------
// --- Actions
// ----------------------------------------------------------------------------

- (void)changeCommonProjectEntry:(id)sender
{
  NSString *newEntry = [sender stringValue];

  if (sender == installPathField)
    {
      [projectDict setObject:newEntry forKey:PCInstallDir];
    }
  else if ( sender == toolField )
    {
      [projectDict setObject:newEntry forKey:PCBuildTool];

      if( ![[NSFileManager defaultManager] isExecutableFileAtPath:newEntry] )
	{
	  NSRunAlertPanel(@"Build Tool Error!",
			  @"No valid executable found at '%@'!",
			  @"OK",nil,nil,newEntry);
	}
    }
  else if ( sender == ccOptField )
    {
      [projectDict setObject:newEntry forKey:PCCompilerOptions];
    }
  else if ( sender == ldOptField )
    {
      [projectDict setObject:newEntry forKey:PCLinkerOptions];
    }

  [[NSNotificationCenter defaultCenter] 
    postNotificationName:ProjectDictDidChangeNotification
                  object:self];
}

- (void)setAppClass:(id)sender
{
  [projectDict setObject:[appClassField stringValue] forKey:PCAppClass];

  [[NSNotificationCenter defaultCenter] 
    postNotificationName:ProjectDictDidChangeNotification
                  object:self];
}

- (void)setAppIcon:(id)sender
{
  int         result;  
  NSArray     *fileTypes = [NSImage imageFileTypes];
  NSOpenPanel *openPanel = [NSOpenPanel openPanel];
  NSString    *dir = nil;

  [openPanel setAllowsMultipleSelection:NO];
  
  dir = [[NSUserDefaults standardUserDefaults]
    objectForKey:@"LastOpenDirectory"];
  result = [openPanel runModalForDirectory:dir
                                      file:nil 
                                     types:fileTypes];

  if (result == NSOKButton)
    {
      NSString *imageFilePath = [[openPanel filenames] objectAtIndex:0];

      if (![self setAppIconWithImageAtPath:imageFilePath])
	{
	  NSRunAlertPanel(@"Error while opening file!", 
			  @"Couldn't open %@", @"OK", nil, nil,imageFilePath);
	}
    }  
}

- (BOOL)setAppIconWithImageAtPath:(NSString *)path
{
  NSRect   frame = {{0,0}, {64, 64}};
  NSImage  *image = nil;
  NSString *imageName = nil;

  if (!(image = [[NSImage alloc] initWithContentsOfFile:path]))
    {
      return NO;
    }

  imageName = [path lastPathComponent];

  [self addAndCopyFiles:[NSArray arrayWithObject:path] forKey:PCImages];
  
  [projectDict setObject:imageName forKey:PCAppIcon];

  [infoDict setObject:imageName forKey:@"NSIcon"];
  [infoDict setObject:imageName forKey:@"ApplicationIcon"];

  [appImageField setStringValue:imageName];

  [appIconView setImage:nil];
  [appIconView display];

  frame.size = [image size];
  [appIconView setFrame:frame];
  [appIconView setImage:image];
  [appIconView display];
  RELEASE(image);

  [[NSNotificationCenter defaultCenter] 
    postNotificationName:ProjectDictDidChangeNotification
                  object:self];

  return YES;
}

- (void)clearAppIcon:(id)sender
{
  [projectDict setObject:@"" forKey:PCAppIcon];
  [infoDict setObject:@"" forKey:@"NSIcon"];
  [infoDict setObject:@"" forKey:@"ApplicationIcon"];
  [appImageField setStringValue:@""];
  [appIconView setImage:nil];
  [appIconView display];

  [[NSNotificationCenter defaultCenter] 
    postNotificationName:ProjectDictDidChangeNotification
                  object:self];
}

// ----------------------------------------------------------------------------
// --- Notifications
// ----------------------------------------------------------------------------

- (void)updateInspectorValues:(NSNotification *)aNotif
{
  NSRect   frame = {{0,0}, {48,48}};
  NSImage  *image = nil;
  NSString *path = nil;
  NSString *_icon = nil;

  NSLog (@"PCAppProject: updateInspectorValues");

  // Build Attributes view
  [installPathField setStringValue:[projectDict objectForKey:PCInstallDir]];
  [toolField setStringValue:[projectDict objectForKey:PCBuildTool]];
  [ccOptField setStringValue:[projectDict objectForKey:PCCompilerOptions]];
  [ldOptField setStringValue:[projectDict objectForKey:PCLinkerOptions]];

  // Project Attributes view
  [projectTypeField setStringValue:[projectDict objectForKey:PCProjType]];
  [projectNameField setStringValue:[projectDict objectForKey:PCProjectName]];
  [projectLanguageField setStringValue:[projectDict objectForKey:@"LANGUAGE"]];
  [appClassField setStringValue:[projectDict objectForKey:PCAppClass]];
  [appImageField setStringValue:[projectDict objectForKey:PCAppIcon]];

  _icon = [projectDict objectForKey:PCAppIcon];
  if (_icon && ![_icon isEqualToString:@""])
    {
      path = [self dirForCategory:PCImages];
      path = [path stringByAppendingPathComponent:_icon];
    }

  if (path && (image = [[NSImage alloc] initWithContentsOfFile:path]))
    {
      frame.size = [image size];
      [appIconView setFrame:frame];
      [appIconView setImage:image];
      [appIconView display];
      RELEASE(image);
    }

  // File Attributes view
}

- (void)browserDidSetPath:(NSNotification *)aNotif
{
  NSString *fileName = [[aNotif object] nameOfSelectedFile];

  if (fileName)
    {
      [fileNameField setStringValue:fileName];
    }
  else
    {
      [fileNameField setStringValue:@"No files selected"];
    }
}

// ----------------------------------------------------------------------------
// --- Project
// ----------------------------------------------------------------------------

- (Class)builderClass
{
  return [PCAppProj class];
}

- (BOOL)writeMakefile
{
  NSData   *mfd;
  NSString *mfl = [projectPath stringByAppendingPathComponent:@"GNUmakefile"];
  int i,j; 
  PCMakefileFactory *mf = [PCMakefileFactory sharedFactory];
  NSDictionary      *dict = [self projectDict];
  NSString          *infoFile = nil;

  // Save the project file
  [super writeMakefile];

  // Save Info-gnustep.plist
  infoFile = [projectPath stringByAppendingPathComponent:@"Info-gnustep.plist"];
  [infoDict writeToFile:infoFile atomically:YES];

  // Create the new file
  [mf createMakefileForProject:[self projectName]];

  [mf appendString:@"include $(GNUSTEP_MAKEFILES)/common.make\n"];

  [mf appendSubprojects:[dict objectForKey:PCSubprojects]];

  [mf appendApplication];
  [mf appendAppIcon:[dict objectForKey:PCAppIcon]];
  [mf appendGuiLibraries:[dict objectForKey:PCLibraries]];

  [mf appendResources];
  for (i=0; i<[[self resourceFileKeys] count]; i++)
    {
      NSString       *k = [[self resourceFileKeys] objectAtIndex:i];
      NSMutableArray *resources = [[dict objectForKey:k] mutableCopy];

      if ([k isEqualToString:PCImages])
	{
	  for (j=0; j<[resources count]; j++)
	    {
	      [resources replaceObjectAtIndex:j 
		withObject:[NSString stringWithFormat:@"Images/%@", 
		[resources objectAtIndex:j]]];
	    }
	}

      [mf appendResourceItems:resources];
      [resources release];
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

- (NSArray *)fileTypesForCategory:(NSString *)category
{
  NSLog(@"Category: %@", category);

  if ([category isEqualToString:PCClasses])
    {
      return [NSArray arrayWithObjects:@"m",nil];
    }
  else if ([category isEqualToString:PCHeaders])
    {
      return [NSArray arrayWithObjects:@"h",nil];
    }
  else if ([category isEqualToString:PCOtherSources])
    {
      return [NSArray arrayWithObjects:@"c",@"C",nil];
    }
  else if ([category isEqualToString:PCInterfaces])
    {
      return [NSArray arrayWithObjects:@"gmodel",@"gorm",nil];
    }
  else if ([category isEqualToString:PCImages])
    {
      return [NSImage imageFileTypes];
    }
  else if ([category isEqualToString:PCSubprojects])
    {
      return [NSArray arrayWithObjects:@"subproj",nil];
    }
  else if ([category isEqualToString:PCLibraries])
    {
      return [NSArray arrayWithObjects:@"so",@"a",@"lib",nil];
    }

  return nil;
}

- (NSString *)dirForCategory:(NSString *)category
{
  if ([category isEqualToString:PCImages])
    {
      return [projectPath stringByAppendingPathComponent:@"Images"];
    }
  else if ([category isEqualToString:PCDocuFiles])
    {
      return [projectPath stringByAppendingPathComponent:@"Documentation"];
    }

  return projectPath;
}

- (NSArray *)sourceFileKeys
{
  return [NSArray arrayWithObjects:
    PCClasses, PCOtherSources, nil];
}

- (NSArray *)resourceFileKeys
{
  return [NSArray arrayWithObjects:
    PCInterfaces, PCOtherResources, PCImages, nil];
}

- (NSArray *)otherKeys
{
  return [NSArray arrayWithObjects:
    PCDocuFiles, PCSupportingFiles, PCNonProject, nil];
}

- (NSArray *)buildTargets
{
  return [NSArray arrayWithObjects: @"app", @"debug", @"profile", nil];
}

- (NSString *)projectDescription
{
  return @"Project that handles GNUstep/ObjC based applications.";
}

- (BOOL)isExecutable
{
  return YES;
}

@end
