/*
   GNUstep ProjectCenter - http://www.gnustep.org

   Copyright (C) 2000-2002 Free Software Foundation

   Author: Philippe C.D. Robert <probert@siggraph.org>

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

#include "PCDefines.h"
#include "PCProjectManager.h"
#include "PCProject.h"
#include "PCProjectEditor.h"
#include "PCProjectBuilder.h"
#include "PCProjectLauncher.h"
#include "PCProject+ComponentHandling.h"
#include "PCSplitView.h"
#include "PCButton.h"

#include "PCProjectBrowser.h"
#include "PCProjectHistory.h"
#include "PCProjectInspector.h"

#include "PCProjectWindow.h"

@implementation PCProjectWindow

// ============================================================================
// ==== Intialization & deallocation
// ============================================================================

- (void)_initUI
{
  NSView       *_c_view;
  unsigned int style = NSTitledWindowMask 
                     | NSClosableWindowMask
		     | NSMiniaturizableWindowMask
		     | NSResizableWindowMask;
  NSRect      rect;

  /*
   * Project Window
   */
  rect = NSMakeRect (100,100,560,448);
  projectWindow = [[NSWindow alloc] initWithContentRect: rect
                                              styleMask: style
                                                backing: NSBackingStoreBuffered
                                                  defer: YES];
  [projectWindow setDelegate: self];
  [projectWindow setMinSize: NSMakeSize (560,448)];
  [projectWindow setMiniwindowImage: IMAGE(@"FileProject")];
  _c_view = [projectWindow contentView];

  /*
   * Toolbar
   */
  buildButton = [[PCButton alloc] initWithFrame: NSMakeRect(8,397,43,43)];
  [buildButton setRefusesFirstResponder:YES];
  [buildButton setTitle: @"Build"];
  [buildButton setImage: IMAGE(@"Build")];
  [buildButton setTarget: self];
  [buildButton setAction: @selector(showProjectBuild:)];
  [buildButton setAutoresizingMask: (NSViewMaxXMargin | NSViewMinYMargin)];
  [buildButton setButtonType: NSMomentaryPushButton];
  [_c_view addSubview: buildButton];
  [buildButton setShowTooltip:YES];
  RELEASE (buildButton);
  
  launchButton = [[PCButton alloc] initWithFrame: NSMakeRect(52,397,43,43)];
  [launchButton setRefusesFirstResponder:YES];
  [launchButton setTitle: @"Launch/Debug"];
  [launchButton setImage: IMAGE(@"Run")];
  [launchButton setTarget: self];
  [launchButton setAction: @selector(showProjectLaunch:)];
  [launchButton setAutoresizingMask: (NSViewMaxXMargin | NSViewMinYMargin)];
  [launchButton setButtonType: NSMomentaryPushButton];
  [_c_view addSubview: launchButton];
  [launchButton setShowTooltip:YES];
  RELEASE (launchButton);
  
  editorButton = [[PCButton alloc] initWithFrame: NSMakeRect(96,397,43,43)];
  [editorButton setRefusesFirstResponder:YES];
  [editorButton setTitle: @"Editor"];
  [editorButton setImage: IMAGE(@"Editor")];
  [editorButton setTarget: self];
  [editorButton setAction: @selector(showProjectEditor:)];
  [editorButton setAutoresizingMask: (NSViewMaxXMargin | NSViewMinYMargin)];
  [editorButton setButtonType: NSMomentaryPushButton];
  [_c_view addSubview: editorButton];
  [editorButton setShowTooltip:YES];
  RELEASE (editorButton);

  findButton = [[PCButton alloc] initWithFrame: NSMakeRect(140,397,43,43)];
  [findButton setRefusesFirstResponder:YES];
  [findButton setTitle: @"Find"];
  [findButton setImage: IMAGE(@"Find")];
  [findButton setTarget: project];
  [findButton setAction: @selector(showFindView:)];
  [findButton setAutoresizingMask: (NSViewMaxXMargin | NSViewMinYMargin)];
  [findButton setButtonType: NSMomentaryPushButton];
  [_c_view addSubview: findButton];
  [findButton setShowTooltip:YES];
  RELEASE (findButton);
  
  inspectorButton = [[PCButton alloc] initWithFrame: NSMakeRect(184,397,43,43)];
  [inspectorButton setRefusesFirstResponder:YES];
  [inspectorButton setTitle: @"Inspector"];
  [inspectorButton setImage: IMAGE(@"Inspector")];
  [inspectorButton setTarget: project];
  [inspectorButton setAction: @selector(showInspector:)];
  [inspectorButton setAutoresizingMask:(NSViewMaxXMargin | NSViewMinYMargin)];
  [inspectorButton setButtonType: NSMomentaryPushButton];
  [_c_view addSubview: inspectorButton];
  [inspectorButton setShowTooltip:YES];
  RELEASE (inspectorButton);
  

  /*
   * File icon and title
   */
  fileIcon = [[NSImageView alloc] initWithFrame: NSMakeRect (504,391,48,48)];
  [fileIcon setRefusesFirstResponder:YES];
  [fileIcon setAutoresizingMask: (NSViewMinXMargin | NSViewMinYMargin)];
  [fileIcon setImage: IMAGE (@"projectSuitcase")];
  [_c_view addSubview: fileIcon];
  RELEASE (fileIcon);

  fileIconTitle = [[NSTextField alloc]
    initWithFrame: NSMakeRect (316,395,180,21)];
  [fileIconTitle setAutoresizingMask: (NSViewMinXMargin 
				       | NSViewMinYMargin 
				       | NSViewWidthSizable)];
  [fileIconTitle setEditable:NO];
  [fileIconTitle setSelectable:NO];
  [fileIconTitle setDrawsBackground: NO];
  [fileIconTitle setAlignment:NSRightTextAlignment];
  [fileIconTitle setBezeled:NO];
  [_c_view addSubview: fileIconTitle];
  RELEASE (fileIconTitle);


  /*
   * Hosrizontal split view
   */
  rect = [[projectWindow contentView] frame];
  rect.size.height -= 62;
  rect.size.width -= 16;
  rect.origin.x += 8;
  rect.origin.y = -2;
  h_split = [[PCSplitView alloc] initWithFrame:rect];
  [h_split setAutoresizingMask: (NSViewWidthSizable | NSViewHeightSizable)];

  rect = [[projectWindow contentView] frame];
  rect.size.height = 130;
  v_split = [[PCSplitView alloc] initWithFrame: rect];
  [v_split setAutoresizingMask: (NSViewWidthSizable | NSViewHeightSizable)];
  [v_split setVertical: YES];

  /*
   * File Browser
   */
  [v_split addSubview: [[project projectBrowser] view]];
  
  /*
   * History
   * If it's separate panel nothing happened
   */
  [self showProjectHistory:self];

  [v_split adjustSubviews];
  [h_split addSubview:v_split];
  RELEASE(v_split);

  /*
   * Custom view
   * View where non-separated Builder, Debugger, Editor goes.
   */ 
  customView = [[NSBox alloc] initWithFrame: NSMakeRect (-1,-1,562,252)];
  [customView setTitlePosition: NSNoTitle];
  [customView setBorderType: NSNoBorder];
  [customView setContentViewMargins: NSMakeSize(0.0,0.0)];
  [customView setAutoresizingMask: NSViewWidthSizable | NSViewHeightSizable];

  // Editor in the Box
  [customView setContentView:[[project projectEditor] componentView]];

  [h_split addSubview:customView];
  RELEASE(customView);
  [h_split adjustSubviews];
  [_c_view addSubview:h_split];
  RELEASE(h_split);
}

- (id)initWithProject:(PCProject *)owner 
{
  if ((self = [super init]))
    {
      NSDictionary *pcWindows;
      NSString     *windowFrame;

      project = owner;

      [self _initUI];
      [projectWindow setFrameAutosaveName: @"ProjectWindow"];

      pcWindows = [[project projectDict] objectForKey:@"PC_WINDOWS"];
      windowFrame = [pcWindows objectForKey:@"ProjectWindow"];
      NSLog(@"PCProjectWindow: window frame %@", windowFrame);
      if (windowFrame != nil)
	{
	  NSLog(@"PCProjectWindow: set frame from project");
	  [projectWindow setFrameFromString:windowFrame];
	}
      else if (![projectWindow setFrameUsingName: @"ProjectWindow"])
	{
	  [projectWindow center];
	}

      // Browser
      [[NSNotificationCenter defaultCenter] 
	addObserver:self
           selector:@selector (setFileIcon:)
               name:PCBrowserDidSetPathNotification
             object:[project projectBrowser]];

      // Project dictionary
      [[NSNotificationCenter defaultCenter] 
	addObserver:self
	   selector:@selector(projectDictDidChange:)
	       name:PCProjectDictDidChangeNotification
	     object:nil];

      [[NSNotificationCenter defaultCenter] 
	addObserver:self
	   selector:@selector(projectDictDidSave:)
	       name:PCProjectDictDidSaveNotification
	     object:nil];

      // Active project changing
      [[NSNotificationCenter defaultCenter] 
	addObserver:self
	   selector:@selector(activeProjectDidChange:)
	       name:PCActiveProjectDidChangeNotification
	     object:nil];
    }
  
  return self;
}

- (void)dealloc
{
  NSLog (@"PCProjectWindow: dealloc");

  [[NSNotificationCenter defaultCenter] removeObserver:self];

  [super dealloc];
}

// ============================================================================
// ==== Accessory methods
// ============================================================================

- (NSImage *)fileIconImage
{
  return [fileIcon image];
}

- (void)setFileIconImage:(NSImage *)image 
{
  [fileIcon setImage:image];
}

- (void)setFileIcon:(NSNotification *)notification
{
  id       object = [notification object];
  NSString *path = nil;
  NSArray  *pathComponents = nil;
  NSString *lastComponent = nil;
  NSString *fileExtension = nil;
  NSString *iconName = nil;
  NSImage  *icon = nil;

  path = [object pathOfSelectedFile];
  pathComponents = [path pathComponents];
  lastComponent = [path lastPathComponent];
  fileExtension = [[lastComponent componentsSeparatedByString:@"."] lastObject];
  
  // Should be provided by PC*Proj bundles
  if ([[object selectedFiles] count] > 1 && [pathComponents count] > 2)
    {
      iconName = [[NSString alloc] initWithString:@"MultiFiles"];
    }
  else if ([lastComponent isEqualToString: @"/"])
    {
      iconName = [[NSString alloc] initWithString:@"projectSuitcase"];
    }
  else if ([lastComponent isEqualToString: @"Classes"])
    {
      iconName = [[NSString alloc] initWithString:@"classSuitcase"];
    }
  else if ([lastComponent isEqualToString: @"Headers"])
    {
      iconName = [[NSString alloc] initWithString:@"headerSuitcase"];
    }
  else if ([lastComponent isEqualToString: @"Other Sources"])
    {
      iconName = [[NSString alloc] initWithString:@"genericSuitcase"];
    }
  else if ([lastComponent isEqualToString: @"Interfaces"])
    {
      iconName = [[NSString alloc] initWithString:@"nibSuitcase"];
    }
  else if ([lastComponent isEqualToString: @"Images"])
    {
      iconName = [[NSString alloc] initWithString:@"iconSuitcase"];
    }
  else if ([lastComponent isEqualToString: @"Other Resources"])
    {
      iconName = [[NSString alloc] initWithString:@"otherSuitcase"];
    }
  else if ([lastComponent isEqualToString: @"Subprojects"])
    {
      iconName = [[NSString alloc] initWithString:@"subprojectSuitcase"];
    }
  else if ([lastComponent isEqualToString: @"Documentation"])
    {
      iconName = [[NSString alloc] initWithString:@"helpSuitcase"];
    }
  else if ([lastComponent isEqualToString: @"Supporting Files"])
    {
      iconName = [[NSString alloc] initWithString:@"genericSuitcase"];
    }
  else if ([lastComponent isEqualToString: @"Libraries"])
    {
      iconName = [[NSString alloc] initWithString:@"librarySuitcase"];
    }
  else if ([lastComponent isEqualToString: @"Non Project Files"])
    {
      iconName = [[NSString alloc] initWithString:@"projectSuitcase"];
    }
    
  if (iconName != nil)
    {
      icon = IMAGE(iconName);
      RELEASE(iconName);
    }
  else if (fileExtension != nil && ![fileExtension isEqualToString:@""])
    {
      icon = [[NSWorkspace sharedWorkspace] iconForFile:lastComponent];
    }

  // Set icon to Project Window and Project Inspector
  if (icon != nil)
    {
      [fileIcon setImage:icon];
    }

  // Set title
  if ([[object selectedFiles] count] > 1 && [pathComponents count] > 2)
    {
      [fileIconTitle setStringValue:
	[NSString stringWithFormat: 
	@"%i files", [[object selectedFiles] count]]];
    }
  else
    {
      [fileIconTitle setStringValue:lastComponent];
    }

  // Project Inspector
  [[[project projectManager] projectInspector] 
    setFANameAndIcon:[project projectBrowser]];
}

- (NSString *)fileIconTitle
{
  return [fileIconTitle stringValue];
}

- (void)setFileIconTitle:(NSString *)title 
{
  [fileIconTitle setStringValue:title];
}

- (NSView *)customContentView
{
  return [customView contentView];
}

- (void)setCustomContentView:(NSView *)subview
{
  if (!customView)
    {
      return;
    }

  [customView setContentView:subview];
  [customView display];
}

// ============================================================================
// ==== Actions
// ============================================================================

- (void)showProjectHistory:(id)sender
{
  if ([[[[NSUserDefaults standardUserDefaults] dictionaryRepresentation]
              objectForKey: SeparateHistory] isEqualToString: @"NO"])
    {
      [v_split addSubview: [[project projectHistory] componentView]];
    }
}

- (void)showProjectBuild:(id)sender
{
  BOOL    separate = NO;
  NSView  *view = nil;
  NSPanel *buildPanel = nil;
  
  if ([[[[NSUserDefaults standardUserDefaults] dictionaryRepresentation]
              objectForKey: SeparateBuilder] isEqualToString: @"YES"])
    {
      separate = YES;
    }

  view = [[project projectBuilder] componentView];
  buildPanel = [[project projectManager] buildPanel];

  if (separate)
    {
      if ([customView contentView] == view)
	{
	  [self showProjectEditor:self];
	}
      [buildPanel orderFront:nil];
    }
  else
    {
      if (buildPanel)
	{
	  [buildPanel close];
	}
      [self setCustomContentView:view];
    }
  [[project projectBuilder] setTooltips];
}

- (void)showProjectLaunch:(id)sender
{
  BOOL    separate = NO;
  NSView  *view = nil;
  NSPanel *launchPanel = nil;

  if ([project isExecutable] == NO)
  {
    NSRunAlertPanel(@"Attention!",
                    @"This project is not executable!",
                    @"OK",nil,nil);
    return;
  }
  
  if ([[[[NSUserDefaults standardUserDefaults] dictionaryRepresentation]
              objectForKey: SeparateLauncher] isEqualToString: @"YES"])
    {
      separate = YES;
    }

  view = [[project projectLauncher] componentView];
  launchPanel = [[project projectManager] launchPanel];

  if (separate)
    {
      if ([customView contentView] == view)
	{
	  [self showProjectEditor:self];
	}
      [launchPanel orderFront: nil];
    }
  else
    {
      if (launchPanel)
	{
	  [launchPanel close];
	}
      [self setCustomContentView:view];
    }
  [[project projectLauncher] setTooltips];
}

- (void)showProjectEditor:(id)sender
{
  [self setCustomContentView:[[project projectEditor] componentView]];
  [self makeFirstResponder:firstResponder];
}

// ============================================================================
// ==== Notifications
// ============================================================================

- (void)projectDictDidChange:(NSNotification *)aNotif
{
  NSArray *sps = [project loadedSubprojects];

  if ([aNotif object] != project
      && ![sps containsObject:[aNotif object]])
    {
      return;
    }

  [projectWindow setTitle: [NSString stringWithFormat: @"%@ - %@", 
  [project projectName],
  [[project projectPath] stringByAbbreviatingWithTildeInPath]]];

  // TODO: if window isn't visible and "edited" attribute set, after ordering
  // out window doesn't show broken close button. Fix it in GNUstep.
  // Workaround is in windowDidBecomeKey.
  [projectWindow setDocumentEdited:YES];
}

- (void)projectDictDidSave:(NSNotification *)aNotif
{
  if ([aNotif object] != project
      && ![[project loadedSubprojects] containsObject:[aNotif object]])
    {
      return;
    }

  [projectWindow setDocumentEdited:NO];
}

- (void)activeProjectDidChange:(NSNotification *)aNotif 
{
  if ([aNotif object] != project
      && ![[project loadedSubprojects] containsObject:[aNotif object]])
    {
      return;
    }

  [self makeKeyWindow];
}

// ============================================================================
// ==== Window delegate
// ============================================================================

- (NSString *)stringWithSavedFrame
{
  return [projectWindow stringWithSavedFrame];
}

- (void)makeKeyAndOrderFront:(id)sender
{
  NSLog(@"PCPW: makeKeyAndOrderFront sender: %@", [sender className]);
  [projectWindow makeKeyAndOrderFront:nil];
}

- (void)makeKeyWindow
{
  [projectWindow makeKeyWindow];
}

- (void)orderFront:(id)sender
{
  if (projectWindow)
    {
      [projectWindow orderFront:sender];
    }
}

- (void)center
{
  [projectWindow center];
}

// [NSWindow close] doesn't send windowShouldClose
- (void)close
{
  [projectWindow close];
}

- (void)performClose:(id)sender
{
  [projectWindow performClose:sender];
}

- (BOOL)isDocumentEdited 
{
  return [projectWindow isDocumentEdited];
}

- (BOOL)isKeyWindow
{
  return [projectWindow isKeyWindow];
}

- (BOOL)makeFirstResponder:(NSResponder *)aResponder
{
  firstResponder = aResponder;
  [projectWindow makeFirstResponder:firstResponder];
  if (![projectWindow isKeyWindow])
    {
      [self makeKeyWindow];
    }

  return YES;
}

- (void)windowDidBecomeKey:(NSNotification *)aNotification
{
  [projectWindow makeMainWindow];
  [projectWindow makeFirstResponder:(NSResponder *)firstResponder];

  if ([project activeSubproject] != nil)
    {
      [[project projectManager] setActiveProject:[project activeSubproject]];
    }
  else
    {
      [[project projectManager] setActiveProject:project];
    }

  // Workaround
  if ([projectWindow isDocumentEdited])
    {
      [projectWindow setDocumentEdited:NO];
      [projectWindow setDocumentEdited:YES];
    }
}

- (void)windowDidResignKey:(NSNotification *)aNotification
{
  [projectWindow makeFirstResponder:nil];
}

- (void)windowDidBecomeMain:(NSNotification *)aNotification
{
}

- (BOOL)windowShouldClose:(id)sender
{
  return [project close:self];
}

- (void)windowWillClose:(NSNotification *)aNotification
{
/*  [project close];
  if ([aNotification object] == projectWindow) 
    {
      if ([projectWindow isDocumentEdited]) 
	{
	  if (NSRunAlertPanel(@"Close Project",
			      @"The project %@ has been edited!\nShould it be saved before closing?",
			      @"Yes",@"No",nil,[project projectName])) 
	    {
	      [project save];
	    }
	}
      [project close];
    }*/
}

@end

