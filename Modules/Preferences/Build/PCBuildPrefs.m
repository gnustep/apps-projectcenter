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

#import "PCBuildPrefs.h"

@implementation PCBuildPrefs

// ----------------------------------------------------------------------------
// --- Init and free
// ----------------------------------------------------------------------------

- (id)initWithPrefController:(id <PCPreferences>)aPrefs
{
  self = [super init];

  if ([NSBundle loadNibNamed:@"BuildPrefs" owner:self] == NO)
    {
      NSLog(@"PCBuildPrefs: error loading NIB file!");
    }

  prefs = aPrefs;

  RETAIN(buildingView);

  return self;
}

- (void)awakeFromNib
{
  [setSuccessButton setRefusesFirstResponder:YES];
  [setFailureButton setRefusesFirstResponder:YES];

  [setRootBuildDirButton setRefusesFirstResponder:YES];
  [setBuildToolButton setRefusesFirstResponder:YES];

  [deleteCache setRefusesFirstResponder:YES];
  [promptOnClean setRefusesFirstResponder:YES];
}

- (void)dealloc
{
#ifdef DEBUG
  NSLog (@"PCBuildPrefs: dealloc");
#endif

  [[NSNotificationCenter defaultCenter] removeObserver:self];

  RELEASE(buildingView);

  [super dealloc];
}

// Protocol
- (void)setDefaults
{
  [prefs setObject:@"" forKey:SuccessSound];
  [prefs setObject:@"" forKey:FailureSound];
  [prefs setObject:@"" forKey:RootBuildDirectory];
  [prefs setObject:PCDefaultBuildTool forKey:BuildTool];
  [prefs setObject:@"YES" forKey:DeleteCacheWhenQuitting];
  [prefs setObject:@"YES" forKey:PromptOnClean];
}

- (void)readPreferences
{
  NSString *val;
  int      state;

  if (!(val = [prefs objectForKey:SuccessSound]))
    val = @"";
  [successField setStringValue:val];
  if (!(val = [prefs objectForKey:FailureSound]))
    val = @"";
  [failureField setStringValue:val];

  if (!(val = [prefs objectForKey:RootBuildDirectory]))
    val = @"";
  [rootBuildDirField setStringValue:val];

  if (!(val = [prefs objectForKey:BuildTool]))
    val = PCDefaultBuildTool;
  [buildToolField setStringValue:val];

  val = [prefs objectForKey:DeleteCacheWhenQuitting];
  state = [val isEqualToString:@"YES"] ? NSOnState : NSOffState;
  [deleteCache setState:state];

  val = [prefs objectForKey:PromptOnClean];
  state = [val isEqualToString:@"YES"] ? NSOnState : NSOffState;
  [promptOnClean setState:state];
}

- (NSView *)view
{
  return buildingView;
}

// Actions
- (void)setSuccessSound:(id)sender
{
  NSArray  *types = [NSArray arrayWithObjects:@"snd",@"au",@"wav",nil];
  NSArray  *files;
  NSString *path;

  if ((sender == successField))
    {
      path = [successField stringValue];
    }
  else
    {
      files = [[PCFileManager defaultManager] 
	filesOfTypes:types
	   operation:PCOpenFileOperation
	    multiple:NO
	       title:@"Choose Success Sound"
	     accView:nil];
      path = [files objectAtIndex:0];
    }

/*    {
      NSSound *sound;

      sound = [[NSSound alloc] initWithContentsOfFile:path byReference:YES];
      [sound play];
      RELEASE(sound);
    }*/

  if (path)
    {
      [successField setStringValue:path];
      [prefs setObject:path forKey:SuccessSound];
    }

  [[buildingView window] makeFirstResponder:successField];
}

- (void)setFailureSound:(id)sender
{
  NSArray  *types = [NSArray arrayWithObjects:@"snd",@"au",@"wav",nil];
  NSArray  *files;
  NSString *path;

  if ((sender == failureField))
    {
      path = [failureField stringValue];
    }
  else
    {
      files = [[PCFileManager defaultManager] 
	filesOfTypes:types
	   operation:PCOpenFileOperation
	    multiple:NO
	       title:@"Choose Failure Sound"
	     accView:nil];
      path = [files objectAtIndex:0];
    }

  if (path)
    {
      [failureField setStringValue:path];
      [prefs setObject:path forKey:FailureSound];
    }

  [[buildingView window] makeFirstResponder:failureField];
}

- (void)setRootBuildDir:(id)sender
{
  NSArray  *files;
  NSString *path;

  if ((sender == rootBuildDirField))
    {
      path = [rootBuildDirField stringValue];
    }
  else
    {
      files = [[PCFileManager defaultManager] 
	filesOfTypes:nil
	   operation:PCOpenDirectoryOperation
	    multiple:NO
	       title:@"Choose Build Directory"
	     accView:nil];
      path = [files objectAtIndex:0];
    }

  if (path)
    {
      [rootBuildDirField setStringValue:path];
      [prefs setObject:path forKey:RootBuildDirectory];
    }

  [[buildingView window] makeFirstResponder:rootBuildDirField];
}

- (void)setBuildTool:(id)sender
{
  NSArray  *files;
  NSString *path;

  if ((sender == buildToolField))
    {
      path = [buildToolField stringValue];
    }
  else
    {
      files = [[PCFileManager defaultManager] 
	filesOfTypes:nil
	   operation:PCOpenFileOperation
	    multiple:NO
	       title:@"Choose Build Tool"
	     accView:nil];
      path = [files objectAtIndex:0];
    }

  if (path)
    {
      [buildToolField setStringValue:path];
      [prefs setObject:path forKey:BuildTool];
    }

  [[buildingView window] makeFirstResponder:buildToolField];
}

- (void)setDeleteCache:(id)sender
{
  NSString *state;

  if (deleteCache == nil)
    {// HACK!!! need to be fixed in GNUstep
      deleteCache = sender;
      return;
    }

  state = ([sender state] == NSOffState) ? @"NO" : @"YES";
  [prefs setObject:state forKey:DeleteCacheWhenQuitting];
}

- (void)setPromptOnClean:(id)sender
{
  NSString *state;

  if (promptOnClean == nil)
    {// HACK!!! need to be fixed in GNUstep
      promptOnClean = sender;
      return;
    }

  state = ([sender state] == NSOffState) ? @"NO" : @"YES";
  NSLog(@"Set PromptOnClean to %@", state);
  [prefs setObject:state forKey:PromptOnClean];
}

@end

