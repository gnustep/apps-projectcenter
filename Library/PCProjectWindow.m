/*
   GNUstep ProjectCenter - http://www.gnustep.org

   Copyright (C) 2000-2004 Free Software Foundation

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

#include "PCDefines.h"
#include "PCSplitView.h"
#include "PCButton.h"

#include "PCProjectManager.h"
#include "PCProject.h"

#include "PCProjectWindow.h"
#include "PCProjectBrowser.h"
#include "PCProjectEditor.h"
#include "PCProjectBuilder.h"
#include "PCProjectLauncher.h"
#include "PCProjectLoadedFiles.h"
#include "PCProjectInspector.h"

#include "PCPrefController.h"
#include "PCLogController.h"

@implementation PCProjectWindow

// ============================================================================
// ==== Intialization & deallocation
// ============================================================================

- (void)_createCustomView
{
  customView = [[NSBox alloc] initWithFrame:NSMakeRect(-1,-1,562,252)];
  [customView setTitlePosition:NSNoTitle];
  [customView setBorderType:NSNoBorder];
  [customView setContentViewMargins:NSMakeSize(0.0,0.0)];
  [customView setAutoresizingMask: NSViewWidthSizable | NSViewHeightSizable];

  // Editor in the Box
  [customView setContentView:[[project projectEditor] componentView]];

  [h_split addSubview:customView];
  RELEASE(customView);
  [h_split adjustSubviews];
}

- (void)_initUI
{
  NSView       *_c_view;
  unsigned int style = NSTitledWindowMask 
                     | NSClosableWindowMask
		     | NSMiniaturizableWindowMask
		     | NSResizableWindowMask;
  NSRect       rect;
  NSRect       tmpRect;
  NSView       *browserView = nil;

  /*
   * Project Window
   */
  rect = NSMakeRect (100,100,560,448);
  projectWindow = [[NSWindow alloc] initWithContentRect: rect
                                              styleMask: style
                                                backing: NSBackingStoreBuffered
                                                  defer: YES];
  [projectWindow setDelegate: self];
  [projectWindow setMinSize: NSMakeSize (560,290)];
  [projectWindow setMiniwindowImage: IMAGE(@"FileProject")];
  _c_view = [projectWindow contentView];

  /*
   * Toolbar
   */
  tmpRect = rect;
  rect.size.width -= 16;
  rect.size.height = 48;
  rect.origin.x = 8;
  rect.origin.y = 391;
  toolbarView = [[NSBox alloc] initWithFrame:rect];
  [toolbarView setTitlePosition:NSNoTitle];
  [toolbarView setBorderType:NSNoBorder];
  [toolbarView setAutoresizingMask:NSViewWidthSizable | NSViewMinYMargin];
  [toolbarView setContentViewMargins: NSMakeSize(0.0,0.0)];
  [_c_view addSubview:toolbarView];
  RELEASE(toolbarView);
  
  buildButton = [[PCButton alloc] initWithFrame: NSMakeRect(0,5,43,43)];
  [buildButton setRefusesFirstResponder:YES];
  [buildButton setTitle: @"Build"];
  [buildButton setImage: IMAGE(@"Build")];
  [buildButton setTarget: self];
  [buildButton setAction: @selector(showProjectBuild:)];
  [buildButton setAutoresizingMask: (NSViewMaxXMargin | NSViewMinYMargin)];
  [buildButton setButtonType: NSMomentaryPushButton];
  [toolbarView addSubview: buildButton];
//  [buildButton setShowTooltip:YES];
  RELEASE (buildButton);
  
  launchButton = [[PCButton alloc] initWithFrame: NSMakeRect(44,5,43,43)];
  [launchButton setRefusesFirstResponder:YES];
  [launchButton setTitle: @"Launch/Debug"];
  [launchButton setImage: IMAGE(@"Run")];
  [launchButton setTarget: self];
  [launchButton setAction: @selector(showProjectLaunch:)];
  [launchButton setAutoresizingMask: (NSViewMaxXMargin | NSViewMinYMargin)];
  [launchButton setButtonType: NSMomentaryPushButton];
  [toolbarView addSubview: launchButton];
//  [launchButton setShowTooltip:YES];
  RELEASE (launchButton);
  
  editorButton = [[PCButton alloc] initWithFrame: NSMakeRect(88,5,43,43)];
  [editorButton setRefusesFirstResponder:YES];
  [editorButton setTitle: @"Editor"];
  [editorButton setImage: IMAGE(@"Editor")];
  [editorButton setTarget: self];
  [editorButton setAction: @selector(showProjectEditor:)];
  [editorButton setAutoresizingMask: (NSViewMaxXMargin | NSViewMinYMargin)];
  [editorButton setButtonType: NSMomentaryPushButton];
  [toolbarView addSubview: editorButton];
//  [editorButton setShowTooltip:YES];
  RELEASE (editorButton);

  findButton = [[PCButton alloc] initWithFrame: NSMakeRect(132,5,43,43)];
  [findButton setRefusesFirstResponder:YES];
  [findButton setTitle: @"Find"];
  [findButton setImage: IMAGE(@"Find")];
  [findButton setTarget: project];
  [findButton setAction: @selector(showFindView:)];
  [findButton setAutoresizingMask: (NSViewMaxXMargin | NSViewMinYMargin)];
  [findButton setButtonType: NSMomentaryPushButton];
  [toolbarView addSubview: findButton];
//  [findButton setShowTooltip:YES];
  RELEASE (findButton);
  
  inspectorButton = [[PCButton alloc] initWithFrame: NSMakeRect(176,5,43,43)];
  [inspectorButton setRefusesFirstResponder:YES];
  [inspectorButton setTitle: @"Inspector"];
  [inspectorButton setImage: IMAGE(@"Inspector")];
  [inspectorButton setTarget: [project projectManager]];
  [inspectorButton setAction: @selector(showProjectInspector:)];
  [inspectorButton setAutoresizingMask:(NSViewMaxXMargin | NSViewMinYMargin)];
  [inspectorButton setButtonType: NSMomentaryPushButton];
  [toolbarView addSubview: inspectorButton];
//  [inspectorButton setShowTooltip:YES];
  RELEASE (inspectorButton);
  

  /*
   * File icon and title
   */
  fileIcon = [[NSImageView alloc] initWithFrame: NSMakeRect (496,0,48,48)];
  [fileIcon setRefusesFirstResponder:YES];
  [fileIcon setEditable:NO];
  [fileIcon setAutoresizingMask: (NSViewMinXMargin | NSViewMinYMargin)];
  [fileIcon setImage: IMAGE (@"projectSuitcase")];
  [toolbarView addSubview: fileIcon];
  RELEASE (fileIcon);

  fileIconTitle = [[NSTextField alloc]
    initWithFrame: NSMakeRect (308,4,180,21)];
  [fileIconTitle setAutoresizingMask: (NSViewMinXMargin 
				       | NSViewMinYMargin 
				       | NSViewWidthSizable)];
  [fileIconTitle setEditable:NO];
  [fileIconTitle setSelectable:NO];
  [fileIconTitle setDrawsBackground: NO];
  [fileIconTitle setAlignment:NSRightTextAlignment];
  [fileIconTitle setBezeled:NO];
  [toolbarView addSubview: fileIconTitle];
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

  /*
   * Vertical split view
   */
  rect = [[projectWindow contentView] frame];
  if (h_split)
    {
      rect.size.height = 130;
    }
/*  else
    {
      rect.size.height -= 64;
      rect.size.width -= 16;
      rect.origin.x += 8;
      rect.origin.y = 0;
    }*/
  v_split = [[PCSplitView alloc] initWithFrame:rect];
  [v_split setAutoresizingMask:(NSViewWidthSizable | NSViewHeightSizable)];
  [v_split setVertical:YES];

  /*
   * File Browser
   */
  browserView = [[project projectBrowser] view];
  [v_split addSubview:browserView];
  
  /*
   * LoadedFiles
   */
  if ([self hasLoadedFilesView])
    {
      [self showProjectLoadedFiles:self];
    }

  [h_split addSubview:v_split];
  RELEASE(v_split);

  /*
   * Custom view
   * View where non-separated Builder, Launcher, Editor goes.
   */ 
  if ([self hasCustomView])
    {
      [self _createCustomView];
    }

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
      _isToolbarVisible = YES;

      [self _initUI];
      
      // Window
      [projectWindow setFrameAutosaveName: @"ProjectWindow"];

      pcWindows = [[project projectDict] objectForKey:@"PC_WINDOWS"];
      windowFrame = [pcWindows objectForKey:@"ProjectWindow"];
      PCLogInfo(self, @"window frame %@", windowFrame);
      if (windowFrame != nil)
	{
	  PCLogStatus(self, @"PCProjectWindow: set frame from project");
	  [projectWindow setFrameFromString:windowFrame];
	}
      else if (![projectWindow setFrameUsingName: @"ProjectWindow"])
	{
	  [projectWindow center];
	}
	
      // Toolbar
      if ([[pcWindows objectForKey:@"ShowToolbar"] isEqualToString:@"NO"])
	{
	  [self toggleToolbar];
	}

      [self setTitle];

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
	     
      // ProjectCenter preferences
      [[NSNotificationCenter defaultCenter] 
	addObserver:self
	   selector:@selector(preferencesDidChange:)
	       name:PCPreferencesDidChangeNotification
	     object:nil];
    }
  
  return self;
}

- (void)setTitle
{
  [projectWindow setTitle: [NSString stringWithFormat: @"%@ - %@", 
  [project projectName],
  [[project projectPath] stringByAbbreviatingWithTildeInPath]]];
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
  NSString *categoryName = nil;
  NSString *fileName = nil;
  NSString *fileExtension = nil;
  NSString *iconName = nil;
  NSImage  *icon = nil;

  fileName = [object nameOfSelectedFile];
  if (fileName)
    {
      fileExtension = [fileName pathExtension];
    }
  else
    {
      categoryName = [object nameOfSelectedCategory];
    }

  PCLogInfo(self,@"{setFileIcon} file %@ category %@", 
	    fileName, categoryName);
  
  // Should be provided by PC*Proj bundles
  if ([[object selectedFiles] count] > 1)
    {
      iconName = [[NSString alloc] initWithString:@"MultiFiles"];
    }
  else if (!categoryName && !fileName) // Nothing selected
    {
      iconName = [[NSString alloc] initWithString:@"projectSuitcase"];
    }
  else if ([categoryName isEqualToString: @"Classes"])
    {
      iconName = [[NSString alloc] initWithString:@"classSuitcase"];
    }
  else if ([categoryName isEqualToString: @"Headers"])
    {
      iconName = [[NSString alloc] initWithString:@"headerSuitcase"];
    }
  else if ([categoryName isEqualToString: @"Other Sources"])
    {
      iconName = [[NSString alloc] initWithString:@"genericSuitcase"];
    }
  else if ([categoryName isEqualToString: @"Interfaces"])
    {
      iconName = [[NSString alloc] initWithString:@"nibSuitcase"];
    }
  else if ([categoryName isEqualToString: @"Images"])
    {
      iconName = [[NSString alloc] initWithString:@"iconSuitcase"];
    }
  else if ([categoryName isEqualToString: @"Other Resources"])
    {
      iconName = [[NSString alloc] initWithString:@"otherSuitcase"];
    }
  else if ([categoryName isEqualToString: @"Subprojects"])
    {
      iconName = [[NSString alloc] initWithString:@"subprojectSuitcase"];
    }
  else if ([categoryName isEqualToString: @"Documentation"])
    {
      iconName = [[NSString alloc] initWithString:@"helpSuitcase"];
    }
  else if ([categoryName isEqualToString: @"Supporting Files"])
    {
      iconName = [[NSString alloc] initWithString:@"genericSuitcase"];
    }
  else if ([categoryName isEqualToString: @"Libraries"])
    {
      iconName = [[NSString alloc] initWithString:@"librarySuitcase"];
    }
  else if ([categoryName isEqualToString: @"Non Project Files"])
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
      icon = [[NSWorkspace sharedWorkspace] iconForFile:fileName];
    }

  // Set icon to Project Window and Project Inspector
  if (icon != nil)
    {
      [fileIcon setImage:icon];
    }

  // Set title
  if ([[object selectedFiles] count] > 1)
    {
      [fileIconTitle setStringValue:
	[NSString stringWithFormat: 
	@"%i files", [[object selectedFiles] count]]];
    }
  else if (fileName)
    {
      [fileIconTitle setStringValue:fileName];
    }
  else if (categoryName)
    {
      [fileIconTitle setStringValue:categoryName];
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

- (BOOL)hasCustomView
{
  NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];

  _hasCustomView = NO;
  
  if (![[ud objectForKey:SeparateEditor] isEqualToString:@"YES"]
      && [[ud objectForKey:Editor] isEqualToString:@"ProjectCenter"])
    {
      _hasCustomView = YES;
    }
  if (![[ud objectForKey:SeparateBuilder] isEqualToString:@"YES"])
    {
      _hasCustomView = YES;
    }
  if (![[ud objectForKey:SeparateLauncher] isEqualToString:@"YES"])
    {
      _hasCustomView = YES;
    }

  return _hasCustomView;
}

- (BOOL)hasLoadedFilesView
{
  NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];

  if (![[ud objectForKey:SeparateLoadedFiles] isEqualToString:@"YES"])
    {
      _hasLoadedFilesView = YES;
    }
  else
    {
      _hasLoadedFilesView = NO;
    }

  return _hasLoadedFilesView;
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

- (void)showProjectLoadedFiles:(id)sender
{
  NSPanel       *panel = [[project projectManager] loadedFilesPanel];
  NSScrollView  *componentView = [[project projectLoadedFiles] componentView];
      
  PCLogInfo(self, @"showProjectLoadedFiles");

  if ([self hasLoadedFilesView])
    {
      if (panel && [panel isVisible])
	{
	  [panel close];
	}

      [componentView setBorderType:NSBezelBorder];
      [v_split addSubview:[[project projectLoadedFiles] componentView]];
      [v_split adjustSubviews];
    }
  else
    {
      [componentView setBorderType:NSNoBorder];
      [panel orderFront:nil];
      [v_split adjustSubviews];
    }
}

- (void)showProjectBuild:(id)sender
{
  NSView  *view = [[project projectBuilder] componentView];
  NSPanel *buildPanel = [[project projectManager] buildPanel];
  
  if ([[[PCPrefController sharedPCPreferences] objectForKey:SeparateBuilder]
      isEqualToString: @"YES"])
    {
      if ([customView contentView] == view)
	{
	  [self showProjectEditor:self];
	}
      [buildPanel orderFront:nil];
    }
  else
    {
      if ([buildPanel isVisible])
	{
	  [buildPanel close];
	}
      [self setCustomContentView:view];
    }

  [[project projectBuilder] setTooltips];
}

- (void)showProjectLaunch:(id)sender
{
  NSView  *view = nil;
  NSPanel *launchPanel = nil;

  if ([project isExecutable] == NO)
    {
      NSRunAlertPanel(@"Attention!",
		      @"This project is not executable!",
		      @"OK",nil,nil);
      return;
    }
  
  view = [[project projectLauncher] componentView];
  launchPanel = [[project projectManager] launchPanel];

  if ([[[[NSUserDefaults standardUserDefaults] dictionaryRepresentation]
           objectForKey: SeparateLauncher] isEqualToString: @"YES"])
    {
      if ([customView contentView] == view)
	{
	  [self showProjectEditor:self];
	}
      [launchPanel orderFront: nil];
    }
  else
    {
      if ([launchPanel isVisible])
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

- (BOOL)isToolbarVisible
{
  return _isToolbarVisible;
}

- (void)toggleToolbar
{
  NSRect rect;
  NSView *cView = [projectWindow contentView];
      

  if (_isToolbarVisible)
    {
      RETAIN(toolbarView);
      [toolbarView removeFromSuperview];
      if (h_split)
	{
	  rect = [h_split frame];
	  rect.size.height += 48;

	  // Hack. NSBrowser resizes incorrectly without removing/adding
	  // from/to superview
	  RETAIN(h_split);
	  [h_split removeFromSuperview];
	  [h_split setFrame:rect];
	  [cView addSubview:h_split];
	  RELEASE(h_split);
	}
      else if (v_split)
	{
	  rect = [v_split frame];
	  rect.size.height += 48;

	  // Hack. See above
	  RETAIN(v_split);
	  [v_split removeFromSuperview];
	  [v_split setFrame:rect];
	  [cView addSubview:v_split];
	  RELEASE(v_split);
	}
      _isToolbarVisible = NO;
    }
  else
    {
      rect = [cView frame];
      rect.origin.x = 8;
      rect.origin.y = rect.size.height - 57;
      rect.size.width -= 16;
      rect.size.height = 48;
      [toolbarView setFrame:rect];

      [cView addSubview:toolbarView];
      RELEASE(toolbarView);
      if (h_split)
	{
	  rect = [h_split frame];
	  rect.size.height -= 48;

	  // Hack. See above
	  RETAIN(h_split);
	  [h_split removeFromSuperview];
	  [h_split setFrame:rect];
	  [cView addSubview:h_split];
	  RELEASE(h_split);
	}
      else if (v_split)
	{
	  rect = [v_split frame];
	  rect.size.height -= 48;

	  // Hack. See above
	  RETAIN(v_split);
	  [v_split removeFromSuperview];
	  [v_split setFrame:rect];
	  [cView addSubview:v_split];
	  RELEASE(v_split);
	}
      _isToolbarVisible = YES;
    }
}

// ============================================================================
// ==== Notifications
// ============================================================================

- (void)projectDictDidChange:(NSNotification *)aNotif
{
  PCProject *changedProject = [aNotif object];

  if (changedProject != project
      && changedProject != [project activeSubproject])
    {
      return;
    }

  [self setTitle];

  // TODO: if window isn't visible and "edited" attribute set, after ordering
  // front window doesn't show broken close button. Fix it in GNUstep.
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

- (void)preferencesDidChange:(NSNotification *)aNotif
{
  NSDictionary *prefsDict = [[aNotif object] preferencesDict];
 
  PCLogStatus(self, @"Preferences did change");
 
  //--- Add Custom view
  if ([self hasCustomView] && customView == nil)
    {
      [self _createCustomView];
    }

  // Project Builder
  if ([[prefsDict objectForKey:@"SeparateBuilder"] isEqualToString:@"YES"])
    {
      if ([[[project projectBuilder] componentView] superview])
	{
	  [self showProjectBuild:self];
	}
    }
  else
    {
      NSPanel *buildPanel = [[project projectManager] buildPanel];
      
      if ([buildPanel isVisible] == YES)
	{
	  [self showProjectBuild:self];
	}
    }

  // Project Launcher
  if ([[prefsDict objectForKey:@"SeparateLauncher"] isEqualToString:@"YES"])
    {
      if ([[[project projectLauncher] componentView] superview])
	{
	  [self showProjectLaunch:self];
	}
    }
  else
    {
      NSPanel *launchPanel = [[project projectManager] launchPanel];
      
      if ([launchPanel isVisible] == YES)
	{
	  [self showProjectLaunch:self];
	}
    }

  //--- Remove Custom view
  if (![self hasCustomView] && customView != nil)
    {
      [customView removeFromSuperview];
      [h_split adjustSubviews];
      customView = nil;
    }

  // Loaded Files view
  if ([self hasLoadedFilesView] && [[v_split subviews] count] == 1)
    {
      [self showProjectLoadedFiles:self];
    }
  else if (![self hasLoadedFilesView] && [[v_split subviews] count] == 2)
    {
      [self showProjectLoadedFiles:self];
    }
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
  PCLogInfo(self, @"makeKeyAndOrderFront sender: %@", [sender className]);
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

  return YES;
}

- (void)windowDidBecomeKey:(NSNotification *)aNotification
{
  [projectWindow makeMainWindow];
//  [projectWindow makeFirstResponder:(NSResponder *)firstResponder];

  PCLogInfo(self, @"windowDidBecomeKey: activeSubproject %@",
	    [[project activeSubproject] projectName]);

  if ([[project projectManager] rootActiveProject] != project)
    {
      if ([project activeSubproject] != nil)
	{
	  [[project projectManager] 
	    setActiveProject:[project activeSubproject]];
	}
      else
	{
	  [[project projectManager] setActiveProject:project];
	}
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
//  [projectWindow makeFirstResponder:nil];
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
}

@end

