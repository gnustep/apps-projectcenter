/*
   GNUstep ProjectCenter - http://www.gnustep.org/experience/ProjectCenter.html

   Copyright (C) 2001-2008 Free Software Foundation

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

#import <ProjectCenter/PCDefines.h>
#import <ProjectCenter/PCLogController.h>
#import <ProjectCenter/PCBundleManager.h>

#import "PCPrefController.h"
#import <Protocols/Preferences.h>

// TODO: rewrite it as PCPreferences, use +sharedPreferences instead of
// [NSUserDefaults standardUserDefaults] in every part of ProjectCenter

@implementation PCPrefController

// ===========================================================================
// ==== Class methods
// ===========================================================================

static PCPrefController *_prefCtrllr = nil;
  
+ (PCPrefController *)sharedPCPreferences
{
  if (!_prefCtrllr)
    {
      _prefCtrllr = [[PCPrefController alloc] init];
    }
  
  return _prefCtrllr;
}

//
- (id)init
{
  if (!(self = [super init]))
    {
      return nil;
    }
    
  // The prefs from the defaults
  userDefaults = [NSUserDefaults standardUserDefaults];
  RETAIN(userDefaults);

  if ([userDefaults objectForKey:@"Version"] == nil)
    {
      PCLogInfo(self, @"setDefaultValues");

      [self loadPrefsSections];

      // Clean preferences
      [NSUserDefaults resetStandardUserDefaults];
      [self setObject:@"0.5" forKey:@"Version"];

      // Make preferences modules load default values
      [[sectionsDict allValues] 
	makeObjectsPerformSelector:@selector(setDefaults)];

      [userDefaults synchronize];
    }

  return self;
}

- (void)dealloc
{
#ifdef DEVELOPMENT
  NSLog(@"PCPrefController: dealloc");
#endif
  
  RELEASE(panel);

  [[NSUserDefaults standardUserDefaults] synchronize];

  [super dealloc];
}

- (void)awakeFromNib
{
}

// Accessory
- (id)objectForKey:(NSString *)key
{
  return [userDefaults objectForKey:key];
}

- (void)setObject:(id)anObject forKey:(NSString *)aKey
{
  [userDefaults setObject:anObject forKey:aKey];
  [userDefaults synchronize];

  [[NSNotificationCenter defaultCenter] 
    postNotificationName:PCPreferencesDidChangeNotification
                  object:self];
}

- (void)loadPrefsSections
{
  PCBundleManager    *bundleManager = [[PCBundleManager alloc] init];
  NSDictionary       *bundlesInfo;
  NSEnumerator       *enumerator;
  NSString           *bundlePath;
  NSString           *sectionName;
  id<PCPrefsSection> section;

  sectionsDict = [[NSMutableDictionary alloc] init];

  bundlesInfo = [bundleManager infoForBundlesType:@"preferences"];
  enumerator = [[bundlesInfo allKeys] objectEnumerator];
  while ((bundlePath = [enumerator nextObject]))
    {
      sectionName = [[bundlesInfo objectForKey:bundlePath] 
				  objectForKey:@"Name"];
      section = [bundleManager 
	objectForBundleWithName:sectionName
			   type:@"preferences"
		       protocol:@protocol(PCPrefsSection)];
      [section initWithPrefController:self];
      [section readPreferences];
      [sectionsDict setObject:section forKey:sectionName];
    }
}

- (void)showPanel:(id)sender
{
  if (panel == nil 
      && [NSBundle loadNibNamed:@"Preferences" owner:self] == NO)
    {
      PCLogError(self, @"error loading NIB file!");
      return;
    }

  [panel setFrameAutosaveName:@"Preferences"];
  if (![panel setFrameUsingName: @"Preferences"])
    {
      [panel center];
    }

  [self loadPrefsSections];

  // The popup and selected view
  [popupButton removeAllItems];
  [popupButton addItemsWithTitles:[[sectionsDict allKeys] 
   	 sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)]];
  [popupButton selectItemAtIndex:0];
  [self popupChanged:popupButton];

  [panel makeKeyAndOrderFront:self];
}

// Actions
- (void)popupChanged:(id)sender
{
  id<PCPrefsSection> section;
  NSView             *view;

  section = [sectionsDict objectForKey:[sender titleOfSelectedItem]];
  view = [section view];

  [sectionsView setContentView:view];
//  [sectionsView display];
}

@end
