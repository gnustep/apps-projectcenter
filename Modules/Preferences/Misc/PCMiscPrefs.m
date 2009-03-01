// 
// GNUstep ProjectCenter - http://www.gnustep.org/experience/ProjectCenter.html
//
// Copyright (C) 2001-2009 Free Software Foundation
//
// Authors: Sergii Stoian
//
// Description: 
//
// This file is part of GNUstep.
//
// This application is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License as published 
// by the Free Software Foundation; either version 2 of the License, or 
// (at your option) any later version.
//
// This application is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
// Library General Public License for more details.
//
// You should have received a copy of the GNU General Public
// License along with this library; if not, write to the Free Software 
// Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111 USA.

#import <ProjectCenter/PCDefines.h>
#import <ProjectCenter/PCFileManager.h>

#import "PCMiscPrefs.h"

@implementation PCMiscPrefs

// ----------------------------------------------------------------------------
// --- Init and free
// ----------------------------------------------------------------------------

- (id)initWithPrefController:(id <PCPreferences>)aPrefs
{
  self = [super init];

  if ([NSBundle loadNibNamed:@"MiscPrefs" owner:self] == NO)
    {
      NSLog(@"PCMiscPrefs: error loading NIB file!");
    }

  prefs = aPrefs;

  RETAIN(miscView);

  return self;
}

- (void)awakeFromNib
{
  [promptWhenQuit setRefusesFirstResponder:YES];
  [fullPathInFilePanels setRefusesFirstResponder:YES];
  [rememberWindows setRefusesFirstResponder:YES];
  [displayLog setRefusesFirstResponder:YES];

  [debuggerButton setRefusesFirstResponder:YES];
  [editorButton setRefusesFirstResponder:YES];
}

- (void)dealloc
{
#ifdef DEBUG
  NSLog (@"PCMiscPrefs: dealloc");
#endif

  [[NSNotificationCenter defaultCenter] removeObserver:self];

  RELEASE(miscView);

  [super dealloc];
}

// Protocol
- (void)setDefaults
{
  [prefs setObject:@"YES" forKey:PromptOnQuit];
  [prefs setObject:@"YES" forKey:FullPathInFilePanels];
  [prefs setObject:@"YES" forKey:RememberWindows];
  [prefs setObject:@"NO" forKey:DisplayLog];

  [prefs setObject:@"/usr/bin/gdb" forKey:Debugger];
  [prefs setObject:@"ProjectCenter" forKey:Editor];
}

- (void)readPreferences
{
  NSString *val;
  int      state;

  val = [prefs objectForKey:PromptOnQuit];
  state = [val isEqualToString:@"YES"] ? NSOnState : NSOffState;
  [promptWhenQuit setState:state];

  val = [prefs objectForKey:FullPathInFilePanels];
  state = [val isEqualToString:@"YES"] ? NSOnState : NSOffState;
  [fullPathInFilePanels setState:state];

  val = [prefs objectForKey:RememberWindows];
  state = [val isEqualToString:@"YES"] ? NSOnState : NSOffState;
  [rememberWindows setState:state];
     
  val = [prefs objectForKey:DisplayLog];
  state = [val isEqualToString:@"YES"] ? NSOnState : NSOffState;
  [displayLog setState:state];

  if (!(val = [prefs objectForKey:Debugger]))
    val = PCDefaultDebugger;
  [debuggerField setStringValue:val];

  if (!(val = [prefs objectForKey:Editor]))
    val = @"ProjectCenter";
  [editorField setStringValue:val];
}

- (NSView *)view
{
  return miscView;
}

// Actions
- (void)setPromptWhenQuit:(id)sender
{
  NSString *state;

  if (promptWhenQuit == nil)
    {// HACK!!! need to be fixed in GNUstep
      promptWhenQuit = sender;
      return;
    }

  state = ([sender state] == NSOffState) ? @"NO" : @"YES";
  [prefs setObject:state forKey:PromptOnQuit];
}

- (void)setFullPathInFilePanels:(id)sender
{
  NSString *state;

  if (fullPathInFilePanels == nil)
    {// HACK!!! need to be fixed in GNUstep
      fullPathInFilePanels = sender;
      return;
    }

  state = ([sender state] == NSOffState) ? @"NO" : @"YES";
  [prefs setObject:state forKey:FullPathInFilePanels];
}

- (void)setRememberWindows:(id)sender
{
  NSString *state;

  if (rememberWindows == nil)
    {
      rememberWindows = sender;
      return;
    }

  state = ([sender state] == NSOffState) ? @"NO" : @"YES";
  [prefs setObject:state forKey:RememberWindows];
}

- (void)setDisplayLog:(id)sender
{
  NSString *state;

  if (displayLog == nil)
    {
      displayLog = sender;
      return;
    }

  state = ([sender state] == NSOffState) ? @"NO" : @"YES";
  [prefs setObject:state forKey:DisplayLog];
}

- (void)setDebugger:(id)sender
{
  NSArray       *files;
  NSString      *path;
  NSFileManager *fm = [NSFileManager defaultManager];

  // Choose
  if ((sender == debuggerField))
    {
      path = [debuggerField stringValue];
    }
  else
    {
      files = [[PCFileManager defaultManager] 
	filesOfTypes:nil
	   operation:PCOpenFileOperation
	    multiple:NO
	       title:@"Choose Debugger Tool"
	     accView:nil];
      path = [files objectAtIndex:0];
    }

  [[miscView window] makeFirstResponder:debuggerField];
  if (!path)
    {
      return;
    }

  // Check
  if (path && ![fm fileExistsAtPath:path])
    {
      NSRunAlertPanel(@"Set Debugger Tool",
		      @"File %@ doesn't exist!\n"
		      "Setting field to default value.",
      		      @"Close", nil, nil, path);
      path = @"";
    } 
  else if (path && ![fm isExecutableFileAtPath:path])
    {
      NSRunAlertPanel(@"Set Debugger Tool",
		      @"File %@ exists but is not executable!\n"
		      "Setting field to default value.",
		      @"Close", nil, nil, path);
      path = @"";
    }

  if ([path isEqualToString:@""])
    {
      path = PCDefaultDebugger;
    }

  // Set
  [debuggerField setStringValue:path];
  [prefs setObject:path forKey:Debugger];
}

- (void)setEditor:(id)sender
{
  NSArray       *files;
  NSString      *path;
  NSString      *editorPath;
  NSFileManager *fm = [NSFileManager defaultManager];

  // Choose
  if ((sender == debuggerField))
    {
      path = [debuggerField stringValue];
    }
  else
    {
      files = [[PCFileManager defaultManager] 
	filesOfTypes:nil
	   operation:PCOpenFileOperation
	    multiple:NO
	       title:@"Choose Editor"
	     accView:nil];
      path = [files objectAtIndex:0];
    }
  
//  [separateEditor setEnabled:YES];
//  [self setEditorSizeEnabled:YES];

  [[miscView window] makeFirstResponder:editorField];
  if (!path)
    {
      return;
    }

  // Check
  if (path && ![path isEqualToString:@"ProjectCenter"])
    {
      editorPath = [[path componentsSeparatedByString:@" "] objectAtIndex:0];
      if (![fm fileExistsAtPath:editorPath])
	{
	  [editorField selectText:self];
	  NSRunAlertPanel(@"Set Editor",
	    		  @"File %@ doesn't exist!\n"
			  "Setting field to default value.",
	    		  @"Close", nil, nil, path);
	  path = @"";
	}
      else if (path && ![fm isExecutableFileAtPath:editorPath])
	{
	  [editorField selectText:self];
	  NSRunAlertPanel(@"Set Editor",
	    		  @"File %@ exists but is not executable!\n"
			  "Setting field to default value.",
	    		  @"Close", nil, nil, path);
	  path = @"";
	}
//      [separateEditor setEnabled:NO];
//      [self setEditorSizeEnabled:NO];
    }
  
  if ([path isEqualToString:@""] || !path)
    {
      path = @"ProjectCenter";
    }

  // Set
  [editorField setStringValue:path];
  [prefs setObject:path forKey:Editor];
}

@end

