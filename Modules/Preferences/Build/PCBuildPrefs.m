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

- (id)init
{
  self = [super init];

  if ([NSBundle loadNibNamed:@"BuildPrefs" owner:self] == NO)
    {
      NSLog(@"PCBuildPrefs: error loading NIB file!");
    }
  RETAIN(buildingView);

  return self;
}

- (void)awakeFromNib
{
  [setSuccessButton setRefusesFirstResponder:YES];
  [setFailureButton setRefusesFirstResponder:YES];

  [setRootBuildDirButton setRefusesFirstResponder:YES];
  [setBuildToolButton setRefusesFirstResponder:YES];

  [promptOnClean setRefusesFirstResponder:YES];
}

- (void)setPrefController:(id <PCPreferences>)aPrefs
{
  NSString *val;
  int      state;

  prefs = aPrefs;

  // Building
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

  val = [prefs objectForKey:PromptOnClean];
  state = [val isEqualToString:@"YES"] ? NSOnState : NSOffState;
  [promptOnClean setState:state];
}

- (void)loadDefaults
{
  [prefs setObject:@"" forKey:SuccessSound];
  [prefs setObject:@"" forKey:FailureSound];
  [prefs setObject:@"" forKey:RootBuildDirectory];
  [prefs setObject:PCDefaultBuildTool forKey:BuildTool];
  [prefs setObject:@"YES" forKey:PromptOnClean];
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

  files = [[PCFileManager defaultManager] filesOfTypes:types
					     operation:PCOpenFileOperation
					      multiple:NO
						 title:@"Set Success Sound"
					       accView:nil];
  if ((path = [files objectAtIndex:0]))
    {
      [successField setStringValue:path];
      [prefs setObject:path forKey:SuccessSound];
    }
}

- (void)setFailureSound:(id)sender
{
  NSArray  *types = [NSArray arrayWithObjects:@"snd",@"au",@"wav",nil];
  NSArray  *files;
  NSString *path;

  files = [[PCFileManager defaultManager] filesOfTypes:types
					     operation:PCOpenFileOperation
					      multiple:NO
						 title:@"Set Failure Sound"
					       accView:nil];

  if ((path = [files objectAtIndex:0]))
    {
      [failureField setStringValue:path];
      [prefs setObject:path forKey:FailureSound];
    }
}

- (void)setRootBuildDir:(id)sender
{
  NSArray  *files;
  NSString *path;

  files = [[PCFileManager defaultManager] filesOfTypes:nil
					     operation:PCOpenProjectOperation
					      multiple:NO
						 title:@"Set Build Directory"
					       accView:nil];

  if ((path = [files objectAtIndex:0]))
    {
      [rootBuildDirField setStringValue:path];
      [prefs setObject:path forKey:RootBuildDirectory];
    }
}

- (void)setBuildTool:(id)sender
{
  NSArray  *files;
  NSString *path;

  files = [[PCFileManager defaultManager] filesOfTypes:nil
					     operation:PCOpenFileOperation
					      multiple:NO
						 title:@"Set Build Tool"
					       accView:nil];

  if ((path = [files objectAtIndex:0]))
    {
      [buildToolField setStringValue:path];
      [prefs setObject:path forKey:BuildTool];
    }
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
  [prefs setObject:state forKey:PromptOnClean];
}

@end

