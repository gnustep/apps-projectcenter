/*
   GNUstep ProjectCenter - http://www.gnustep.org

   Copyright (C) 2001 Free Software Foundation

   Authors: Philippe C.D. Robert <probert@siggraph.org>
            Serg Stoyan <stoyan@on.com.ua>

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

#include "PCPrefController.h"
#include <ProjectCenter/ProjectCenter.h>

#include "PCLogController.h"

NSString *SavePeriodDidChangeNotification = @"SavePeriodDidChangeNotification";

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
  NSDictionary *prefs = nil;

  if (!(self = [super init]))
    {
      return nil;
    }
    
  // The prefs from the defaults
  prefs = [[NSUserDefaults standardUserDefaults] dictionaryRepresentation];
  preferencesDict = [[NSMutableDictionary alloc] initWithDictionary:prefs];

  return self;
}

- (void)dealloc
{
  NSLog(@"PCPrefController: dealloc");
  
  RELEASE(preferencesDict);
  
  RELEASE(panel);

  RELEASE(buildingView);
  RELEASE(savingView);
  RELEASE(keyBindingsView);
  RELEASE(miscView);

  [[NSUserDefaults standardUserDefaults] synchronize];

  [super dealloc];
}

- (void)loadPrefernces
{
  NSDictionary *prefs = nil;
  NSString     *val = nil;

  prefs = [[NSUserDefaults standardUserDefaults] dictionaryRepresentation];
  [preferencesDict addEntriesFromDictionary: prefs];
  
  // Fill in the defaults

  // Building
  [successField setStringValue: 
    (val = [preferencesDict objectForKey: SuccessSound]) ? val : @""];

  [failureField setStringValue: 
    (val = [preferencesDict objectForKey: FailureSound]) ? val : @""];

  [promptOnClean setState:
    ([[preferencesDict objectForKey: PromptOnClean] 
     isEqualToString: @"YES"]) ? NSOnState : NSOffState];

  // Saving
  [saveOnQuit setState:
    ([[preferencesDict objectForKey: SaveOnQuit] 
     isEqualToString: @"YES"]) ? NSOnState : NSOffState];
     
  [saveAutomatically setState:
    ([[preferencesDict objectForKey: AutoSave] 
     isEqualToString: @"YES"]) ? NSOnState : NSOffState];

  [keepBackup setState:
    ([[preferencesDict objectForKey: KeepBackup] 
     isEqualToString: @"YES"]) ? NSOnState : NSOffState];

  [autosaveField setStringValue:
    (val = [preferencesDict objectForKey: AutoSavePeriod]) ? val : @"120"];
  [autosaveSlider setFloatValue:[[autosaveField stringValue] floatValue]];

  // Editing

  // Miscellaneous
  [debuggerField setStringValue:
    (val = [preferencesDict objectForKey: PDebugger]) ? val : @"/usr/bin/gdb"];
  [editorField setStringValue:
    (val = [preferencesDict objectForKey: Editor]) ? val : @"ProjectCenter"];
  
  // Misc
  [separateBuilder setState:
    ([[preferencesDict objectForKey: SeparateBuilder] 
     isEqualToString:@"YES"]) ? NSOnState : NSOffState];
  [separateLauncher setState:
    ([[preferencesDict objectForKey: SeparateLauncher] 
     isEqualToString:@"YES"]) ? NSOnState : NSOffState];
  [separateEditor setState:
    ([[preferencesDict objectForKey: SeparateEditor] 
     isEqualToString:@"YES"]) ? NSOnState : NSOffState];
  [separateLoadedFiles setState:
    ([[preferencesDict objectForKey: SeparateLoadedFiles] 
     isEqualToString:@"YES"]) ? NSOnState : NSOffState];

  [promptWhenQuit setState:
    ([[preferencesDict objectForKey: PromptOnQuit] 
     isEqualToString:@"YES"]) ? NSOnState : NSOffState];

  // Bundles
/*  [bundlePathField setStringValue:
    (val = [preferencesDict objectForKey: BundlePaths]) ? val : @""];*/
}

- (void)awakeFromNib
{
  [promptOnClean setRefusesFirstResponder:YES];
  [saveOnQuit setRefusesFirstResponder:YES];
  [saveAutomatically setRefusesFirstResponder:YES];
  [keepBackup setRefusesFirstResponder:YES];
  [separateBuilder setRefusesFirstResponder:YES];
  [separateLauncher setRefusesFirstResponder:YES];
  [separateEditor setRefusesFirstResponder:YES];
  [separateLoadedFiles setRefusesFirstResponder:YES];
  [promptWhenQuit setRefusesFirstResponder:YES];
}

// Accessory
- (NSDictionary *)preferencesDict
{
  return preferencesDict;
}

- (NSString *)selectFileWithTypes:(NSArray *)types
{
  NSUserDefaults   *def = [NSUserDefaults standardUserDefaults];
  NSString 	   *file = nil;
  NSOpenPanel	   *openPanel;
  int		    retval;

  openPanel = [NSOpenPanel openPanel];
  [openPanel setAllowsMultipleSelection:NO];
  [openPanel setCanChooseDirectories:YES];
  [openPanel setCanChooseFiles:YES];

  retval = [openPanel 
    runModalForDirectory:[def objectForKey:@"LastOpenDirectory"]
                    file:nil
		   types:types];

  if (retval == NSOKButton) 
    {
      [def setObject:[openPanel directory] forKey:@"LastOpenDirectory"];
      file = [[openPanel filenames] objectAtIndex:0];

    }

  return file;
}

- (void)showPanel:(id)sender
{
  if (panel == nil 
      && [NSBundle loadNibNamed:@"Preferences" owner:self] == NO)
    {
      PCLogError(self, @"error loading NIB file!");
      return;
    }

  [panel setFrameAutosaveName:@"PreferencesPanel"];
  if (![panel setFrameUsingName: @"PreferencesPanel"])
    {
      [panel center];
    }
  RETAIN(buildingView);
  RETAIN(savingView);
  RETAIN(keyBindingsView);
  RETAIN(miscView);

  // The popup and selected view
  [popupButton removeAllItems];
  [popupButton addItemWithTitle:@"Building"];
  [popupButton addItemWithTitle:@"Saving"];
  [popupButton addItemWithTitle:@"Key Bindings"];
  [popupButton addItemWithTitle:@"Miscellaneous"];

  [popupButton selectItemWithTitle:@"Building"];
  [self popupChanged:popupButton];

  // Load saved prefs
  [self loadPrefernces];

  [panel orderFront:self];
}

- (void)popupChanged:(id)sender
{
  NSView *view = nil;

  switch ([sender indexOfSelectedItem]) 
    {
    case 0:
      view = buildingView;
      break;
    case 1:
      view = savingView;
      break;
    case 2:
      view = keyBindingsView;
      break;
    case 3:
      view = miscView;
      break;
    }

  [sectionsView setContentView:view];
  [sectionsView display];
}

// Building
- (void)setSuccessSound:(id)sender
{
  NSArray *types = [NSArray arrayWithObjects:@"snd",@"au",@"wav",nil];
  NSString *path = [self selectFileWithTypes:types];

  if (path)
    {
      [successField setStringValue: path];

      [[NSUserDefaults standardUserDefaults] setObject:path
	                                        forKey:SuccessSound];
      [preferencesDict setObject:path forKey:SuccessSound];
    }
}

- (void)setFailureSound:(id)sender
{
  NSArray  *types = [NSArray arrayWithObjects:@"snd",@"au",@"wav",nil];
  NSString *path = [self selectFileWithTypes:types];

  if (path)
    {
      [failureField setStringValue:path];

      [[NSUserDefaults standardUserDefaults] setObject:path
	                                        forKey:FailureSound];
      [preferencesDict setObject:path forKey:FailureSound];
    }
}

- (void)setPromptOnClean:(id)sender
{
  NSUserDefaults *def = nil;

  if (promptOnClean == nil)
    {// HACK!!! need to be fixed in GNUstep
      promptOnClean = sender;
      return;
    }

  def = [NSUserDefaults standardUserDefaults];
  switch ([sender state])
    {
    case NSOffState:
      [def setObject:@"NO" forKey:PromptOnClean];
      break;
    case NSOnState:
      [def setObject:@"YES" forKey:PromptOnClean];
      break;
    }
  [def synchronize];

  [preferencesDict setObject:[def objectForKey:PromptOnClean] 
                      forKey:PromptOnClean];
}

// Saving
- (void)setSaveOnQuit:(id)sender
{
  NSUserDefaults *def = [NSUserDefaults standardUserDefaults];

  if (saveOnQuit == nil)
    { // HACK!!!
      saveOnQuit = sender;
      return;
    }

  switch ([sender state])
    {
    case 0:
      [def setObject:@"NO" forKey:SaveOnQuit];
      break;
    case 1:
      [def setObject:@"YES" forKey:SaveOnQuit];
      break;
    }
  [def synchronize];

  [preferencesDict setObject:[def objectForKey:SaveOnQuit] 
                      forKey:SaveOnQuit];
}

- (void)setSaveAutomatically:(id)sender
{
  NSUserDefaults *def = [NSUserDefaults standardUserDefaults];

  if (saveAutomatically == nil)
    { // HACK!!!
      saveAutomatically = sender;
      return;
    }
    
  switch ([[sender selectedCell] state])
    {
    case 0:
      [def setObject:@"NO" forKey:AutoSave];
      break;
    case 1:
      [def setObject:@"YES" forKey:AutoSave];
      break;
    }
  [def synchronize];

  [preferencesDict setObject:[def objectForKey:AutoSave]
                      forKey:AutoSave];
}

- (void)setKeepBackup:(id)sender
{
  NSUserDefaults *def = [NSUserDefaults standardUserDefaults];

  if (keepBackup == nil)
    { // HACK!!!
      keepBackup = sender;
      return;
    }
    
  switch ([[sender selectedCell] state])
    {
    case 0:
      [def setObject:@"NO" forKey:KeepBackup];
      break;
    case 1:
      [def setObject:@"YES" forKey:KeepBackup];
      break;
    }
  [def synchronize];

  [preferencesDict setObject:[def objectForKey:KeepBackup] 
                      forKey:KeepBackup];
}

- (void)setSavePeriod:(id)sender
{
  NSString *periodString = [autosaveField stringValue];
  
  if (periodString == nil || [periodString isEqualToString:@""])
    {
      periodString = [NSString stringWithString:@"120"];
      [autosaveField setStringValue:@"120"];
    }

  [autosaveSlider setFloatValue:[periodString floatValue]];

  [[NSUserDefaults standardUserDefaults] setObject:periodString 
                                            forKey:AutoSavePeriod];
  [preferencesDict setObject:periodString forKey:AutoSavePeriod];

  [[NSNotificationCenter defaultCenter] 
    postNotificationName:SavePeriodDidChangeNotification
                  object:periodString];
}

// Miscellaneous
- (void)setDisplayPanels: (id)sender
{
  NSUserDefaults *def = [NSUserDefaults standardUserDefaults];
  NSString       *key = nil;

  if (sender == separateBuilder)
    {
      key = [NSString stringWithString: SeparateBuilder];
    }
  else if (sender == separateLauncher)
    {
      key = [NSString stringWithString: SeparateLauncher];
    }
  else if (sender == separateEditor)
    {
      key = [NSString stringWithString: SeparateEditor];
    }
  else if (sender == separateLoadedFiles)
    {
      key = [NSString stringWithString: SeparateLoadedFiles];
    }

  switch ([sender state])
    {
    case NSOffState:
      [def setObject: @"NO" forKey: key];
      break;
    case NSOnState:
      [def setObject:@"YES" forKey: key];
      break;
    }
  [def synchronize];

  [preferencesDict setObject: [def objectForKey: key] 
                      forKey: key];
}

- (void)promptWhenQuitting:(id)sender
{
  NSUserDefaults *def = [NSUserDefaults standardUserDefaults];

  switch ([[sender selectedCell] state])
    {
    case 0:
      [def setObject:@"NO" forKey:PromptOnQuit];
      break;
    case 1:
      [def setObject:@"YES" forKey:PromptOnQuit];
      break;
    }
  [def synchronize];

  [preferencesDict setObject:[def objectForKey:PromptOnQuit] 
                      forKey:PromptOnQuit];
}

- (void)setDebugger:(id)sender
{
  NSString *path = [debuggerField stringValue];
  
  if (path)
    {
      [[NSUserDefaults standardUserDefaults] setObject:path forKey:PDebugger];
      [preferencesDict setObject:path forKey:PDebugger];
    }
}

- (void)setEditor:(id)sender
{
  NSString *path = [editorField stringValue];
  
  if (path)
    {
      [[NSUserDefaults standardUserDefaults] setObject:path forKey:Editor];
      [preferencesDict setObject:path forKey:Editor];
    }
}

// Bundles
- (void)setBundlePath:(id)sender
{
  NSString *path = [bundlePathField stringValue];

  if (path)
    {
      [[NSUserDefaults standardUserDefaults] setObject:path forKey:BundlePaths];
      [preferencesDict setObject:path forKey:BundlePaths];
    }
}

@end

