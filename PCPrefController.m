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
      // Clean preferences
      [NSUserDefaults resetStandardUserDefaults];
      [self setString:@"0.5" forKey:@"Version" notify:NO];
    }

  [self loadPrefsSections];

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
- (NSString *)stringForKey:(NSString *)key
{
  return [self stringForKey:key defaultValue:nil];
}

- (NSString *)stringForKey:(NSString *)key
	      defaultValue:(NSString *)defaultValue
{
  NSString *stringValue = [userDefaults objectForKey:key];

  if (stringValue)
    {
      return stringValue;
    }
  else
    {
      [self setString:defaultValue forKey:key notify:NO];
      return defaultValue;
    }
}

- (BOOL)boolForKey:(NSString *)key
{
  return [self boolForKey:key defaultValue:-1];
}

- (BOOL)boolForKey:(NSString *)key
      defaultValue:(BOOL)defaultValue
{
  NSString *stringValue = [userDefaults objectForKey:key];

  if (stringValue)
    {
      return [stringValue boolValue];
    }
  else
    {
      [self setBool:defaultValue forKey:key notify:NO];
      return defaultValue;
    }
}

- (float)floatForKey:(NSString *)key
{
  return [self floatForKey:key defaultValue:0.0];
}

- (float)floatForKey:(NSString *)key defaultValue:(float)defaultValue
{
  NSString *stringValue = [userDefaults objectForKey:key];

  if (stringValue)
    {
      return [stringValue floatValue];
    }
  else
    {
      [self setFloat:defaultValue forKey:key notify:NO];
      return defaultValue;
    }
}

- (void)setString:(NSString *)stringValue 
	   forKey:(NSString *)aKey
	   notify:(BOOL)notify
{
  [userDefaults setObject:stringValue forKey:aKey];
  [userDefaults synchronize];

  if (notify)
    {
      [[NSNotificationCenter defaultCenter] 
	postNotificationName:PCPreferencesDidChangeNotification
		      object:self];
    }
}

- (void)setBool:(BOOL)boolValue
	 forKey:(NSString *)aKey
	 notify:(BOOL)notify
{
  NSString *stringValue = boolValue ? @"YES" : @"NO";

  [userDefaults setObject:stringValue forKey:aKey];
  [userDefaults synchronize];

  if (notify)
    {
      [[NSNotificationCenter defaultCenter] 
	postNotificationName:PCPreferencesDidChangeNotification
		      object:self];
    }
}

- (void)setFloat:(float)floatValue
	  forKey:(NSString *)aKey
	  notify:(BOOL)notify
{
  NSString *stringValue = [NSString stringWithFormat:@"%0.1f", floatValue];

  [userDefaults setObject:stringValue forKey:aKey];
  [userDefaults synchronize];

  if (notify)
    {
      [[NSNotificationCenter defaultCenter] 
	postNotificationName:PCPreferencesDidChangeNotification
		      object:self];
    }
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

  [userDefaults synchronize];
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

- (void)changeFont:(id)sender
{
  NSLog(@"PCPrefController: changeFont");
}

@end
