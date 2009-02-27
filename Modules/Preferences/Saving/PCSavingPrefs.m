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

#import "PCSavingPrefs.h"

@implementation PCSavingPrefs

// ----------------------------------------------------------------------------
// --- Init and free
// ----------------------------------------------------------------------------

- (id)initWithPrefController:(id <PCPreferences>)aPrefs
{
  self = [super init];

  if ([NSBundle loadNibNamed:@"SavingPrefs" owner:self] == NO)
    {
      NSLog(@"PCSavingPrefs: error loading NIB file!");
    }

  prefs = aPrefs;

  RETAIN(savingView);

  return self;
}

- (void)awakeFromNib
{
  [saveOnQuit setRefusesFirstResponder:YES];
  [keepBackup setRefusesFirstResponder:YES];
}

- (void)setDefaults
{
  [prefs setObject:@"YES" forKey:SaveOnQuit];
  [prefs setObject:@"YES" forKey:KeepBackup];
  [prefs setObject:@"120" forKey:AutoSavePeriod];
}

- (void)readPreferences
{
  NSString *val;
  int      state;

  if (!(val = [prefs objectForKey:AutoSavePeriod]))
    val = @"120";
  [autosaveField setStringValue:val];
  [autosaveSlider setFloatValue:[val floatValue]];

  val = [prefs objectForKey:SaveOnQuit];
  state = [val isEqualToString:@"YES"] ? NSOnState : NSOffState;
  [saveOnQuit setState:state];

  val = [prefs objectForKey:KeepBackup];
  state = [val isEqualToString:@"YES"] ? NSOnState : NSOffState;
  [keepBackup setState:state];
}

- (void)dealloc
{
#ifdef DEBUG
  NSLog (@"PCSavingPrefs: dealloc");
#endif

  [[NSNotificationCenter defaultCenter] removeObserver:self];

  RELEASE(savingView);

  [super dealloc];
}

// Protocol
- (NSView *)view
{
  return savingView;
}

// Actions
- (void)setSaveOnQuit:(id)sender
{
  NSString *state;

  if (saveOnQuit == nil)
    {// HACK!!! need to be fixed in GNUstep
      saveOnQuit = sender;
      return;
    }

  state = ([sender state] == NSOffState) ? @"NO" : @"YES";
  [prefs setObject:state forKey:SaveOnQuit];
}

- (void)setKeepBackup:(id)sender
{
  NSString *state;

  if (keepBackup == nil)
    {// HACK!!! need to be fixed in GNUstep
      keepBackup = sender;
      return;
    }

  state = ([sender state] == NSOffState) ? @"NO" : @"YES";
  [prefs setObject:state forKey:KeepBackup];
}

- (void)setSavePeriod:(id)sender
{
  NSString *periodString = nil;
  
  if (sender == autosaveSlider)
    {
      [autosaveField setIntValue:[sender intValue]];
    }

  periodString = [autosaveField stringValue];
  [prefs setObject:periodString forKey:AutoSavePeriod];

  // TODO: Check if this can be replaced with generic notification
  // posted by PCPrefsController
  [[NSNotificationCenter defaultCenter] 
    postNotificationName:PCSavePeriodDidChangeNotification
                  object:periodString];
}



@end

