/*
   GNUstep ProjectCenter - http://www.gnustep.org

   Copyright (C) 2001 Free Software Foundation

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

   $Id$
*/

#include "PCPrefController.h"
#include "PCPrefController+UInterface.h"
#include <ProjectCenter/ProjectCenter.h>

NSString *SavePeriodDidChangeNotification = @"SavePeriodDidChangeNotification";

@implementation PCPrefController

- (id)init
{
  if ((self = [super init])) {
    NSDictionary *prefs;
    
    // The prefs from the defaults
    prefs = [[NSUserDefaults standardUserDefaults] dictionaryRepresentation];
    preferencesDict = [[NSMutableDictionary alloc] initWithDictionary:prefs];
  }
  return self;
}

- (void)dealloc
{
  RELEASE(preferencesDict);
  
  RELEASE(prefWindow);

  RELEASE(prefBuildingView);
  RELEASE(prefMiscView);
  RELEASE(prefEditingView);
  RELEASE(prefSavingView);

  [[NSUserDefaults standardUserDefaults] synchronize];

  [super dealloc];
}

- (void) showPrefWindow: (id)sender
{
  NSDictionary *prefs;
  NSString     *val;

  if (!prefWindow)
    {
      id view;

      [self _initUI];

      // The popup and selected view
      [prefPopup removeAllItems];
      [prefPopup addItemWithTitle: @"Building"];
      [prefPopup addItemWithTitle: @"Saving"];
      [prefPopup addItemWithTitle: @"Editing"];
      [prefPopup addItemWithTitle: @"Miscellaneous"];
      [prefPopup addItemWithTitle: @"Interface"];

      [prefPopup selectItemWithTitle: @"Building"];

      view = [prefBuildingView retain];
      [(NSBox *)prefEmptyView setContentView: view];
      [prefEmptyView display]; 
    }

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

  [autoSaveField setStringValue:
    (val = [preferencesDict objectForKey: AutoSavePeriod]) ? val : @"120"];

  // Editing
  if([[preferencesDict objectForKey: TabBehaviour] isEqualToString:@"Tab"])
    {
      [tabMatrix selectCellAtRow: 0 column: 0];
    }
  else if([[preferencesDict objectForKey: TabBehaviour] isEqualToString:@"Sp2"])
    {
      [tabMatrix selectCellAtRow: 1 column: 0];
    }
  else if([[preferencesDict objectForKey: TabBehaviour] isEqualToString:@"Sp4"])
    {
      [tabMatrix selectCellAtRow: 0 column: 1];
    }
  else if([[preferencesDict objectForKey: TabBehaviour] isEqualToString:@"Sp8"])
    {
      [tabMatrix selectCellAtRow: 1 column: 1];
    }

  // Miscellaneous
  [compilerField setStringValue:
    (val = [preferencesDict objectForKey: Compiler]) ? val : @""];
  [debuggerField setStringValue:
    (val = [preferencesDict objectForKey: PDebugger]) ? val : @""];
  [editorField setStringValue:
    (val = [preferencesDict objectForKey: Editor]) ? val : @""];
  [bundlePathField setStringValue:
    (val = [preferencesDict objectForKey: BundlePaths]) ? val : @""];
  
  // Interface
  [separateBuilder setState:
    ([[preferencesDict objectForKey: SeparateBuilder] 
     isEqualToString:@"YES"]) ? NSOnState : NSOffState];
  [separateLauncher setState:
    ([[preferencesDict objectForKey: SeparateLauncher] 
     isEqualToString:@"YES"]) ? NSOnState : NSOffState];
  [separateEditor setState:
    ([[preferencesDict objectForKey: SeparateEditor] 
     isEqualToString:@"YES"]) ? NSOnState : NSOffState];

  [promptWhenQuit setState:
    ([[preferencesDict objectForKey: PromptOnQuit] 
     isEqualToString:@"YES"]) ? NSOnState : NSOffState];
  [useExternalEditor setState:
    ([[preferencesDict objectForKey: ExternalEditor] 
     isEqualToString:@"YES"]) ? NSOnState : NSOffState];
  [useExternalDebugger setState:
    ([[preferencesDict objectForKey: ExternalDebugger] 
     isEqualToString:@"YES"]) ? NSOnState : NSOffState];


  if (![prefWindow isVisible])
    { 
      [prefWindow setFrameUsingName: @"Preferences"];
    }
  [prefWindow makeKeyAndOrderFront: self];
}

- (void)popupChanged:(id)sender
{
  NSView *view = nil;

  switch ([sender indexOfSelectedItem]) 
    {
    case 0:
      view = prefBuildingView;
      break;
    case 1:
      view = prefSavingView;
      break;
    case 2:
      view = prefEditingView;
      break;
    case 3:
      view = prefMiscView;
      break;
    case 4:
      view = prefInterfaceView;
      break;
    }

  [(NSBox *)prefEmptyView setContentView:view];
  [prefEmptyView display];
}

- (void)setSuccessSound:(id)sender
{
  NSArray *types = [NSArray arrayWithObjects:@"snd",@"au",nil];
  NSString *path = [self selectFileWithTypes:types];
  
  if (path) {
    [successField setStringValue: path];
    
    [[NSUserDefaults standardUserDefaults] setObject:path forKey:SuccessSound];
    [preferencesDict setObject:path forKey:SuccessSound];
  }
}

- (void)setFailureSound:(id)sender
{
  NSString *path = [self selectFileWithTypes:[NSArray arrayWithObjects:@"snd",@"au",nil]];
  
  if (path) {
    [failureField setStringValue:path];
    
    [[NSUserDefaults standardUserDefaults] setObject:path forKey:FailureSound];
    [preferencesDict setObject:path forKey:FailureSound];
  }
}

- (void)setPromptOnClean:(id)sender
{
  NSUserDefaults *def = [NSUserDefaults standardUserDefaults];

  switch ([[sender selectedCell] state]) {
  case 0:
    [def setObject:@"NO" forKey:PromptOnClean];
    break;
  case 1:
    [def setObject:@"YES" forKey:PromptOnClean];
    break;
  }
  [def synchronize];

  [preferencesDict setObject:[def objectForKey:PromptOnClean] 
                      forKey:PromptOnClean];
}

- (void)setSaveAutomatically:(id)sender
{
  NSUserDefaults *def = [NSUserDefaults standardUserDefaults];

  switch ([[sender selectedCell] state]) {
  case 0:
    [def setObject:@"NO" forKey:AutoSave];
    break;
  case 1:
    [def setObject:@"YES" forKey:AutoSave];
    break;
  }
  [def synchronize];

  [preferencesDict setObject:[def objectForKey:AutoSave] forKey:AutoSave];
}

- (void)setKeepBackup:(id)sender
{
  NSUserDefaults *def = [NSUserDefaults standardUserDefaults];

  switch ([[sender selectedCell] state]) {
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
  NSString *periodString = [autoSaveField stringValue];
  
  if (periodString == nil || [periodString isEqualToString:@""]) {
      periodString = [NSString stringWithString:@"300"];
  }

  [[NSUserDefaults standardUserDefaults] setObject:periodString 
                                            forKey:AutoSavePeriod];
  [preferencesDict setObject:periodString forKey:AutoSavePeriod];

  [[NSNotificationCenter defaultCenter] postNotificationName:SavePeriodDidChangeNotification object:periodString];
}

- (void)setSaveOnQuit:(id)sender
{
  NSUserDefaults *def = [NSUserDefaults standardUserDefaults];

  switch ([[sender selectedCell] state]) {
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

- (void)setUseExternalEditor:(id)sender
{
  NSUserDefaults *def = [NSUserDefaults standardUserDefaults];

  switch ([[sender selectedCell] state]) {
  case 0:
    [def setObject:@"NO" forKey:ExternalEditor];
    break;
  case 1:
    [def setObject:@"YES" forKey:ExternalEditor];
    break;
  }
  [def synchronize];

  [preferencesDict setObject:[def objectForKey:ExternalEditor] 
                      forKey:ExternalEditor];
}

- (void)setUseExternalDebugger:(id)sender
{
  NSUserDefaults *def = [NSUserDefaults standardUserDefaults];

  switch ([[sender selectedCell] state]) {
  case 0:
    [def setObject:@"NO" forKey:ExternalDebugger];
    break;
  case 1:
    [def setObject:@"YES" forKey:ExternalDebugger];
    break;
  }
  [def synchronize];

  [preferencesDict setObject:[def objectForKey:ExternalDebugger] 
                      forKey:ExternalDebugger];
}

- (void)setEditor:(id)sender
{
  NSString *path = [editorField stringValue];
  
  if (path) {
    [[NSUserDefaults standardUserDefaults] setObject:path forKey:Editor];
    [preferencesDict setObject:path forKey:Editor];
  }
}

- (void)setCompiler:(id)sender
{
  NSString *path = [compilerField stringValue];

  if (path) {
    [[NSUserDefaults standardUserDefaults] setObject:path forKey:Compiler];
    [preferencesDict setObject:path forKey:Compiler];
  }
}

- (void)setDebugger:(id)sender
{
  NSString *path = [debuggerField stringValue];
  
  if (path) {
    [[NSUserDefaults standardUserDefaults] setObject:path forKey:PDebugger];
    [preferencesDict setObject:path forKey:PDebugger];
  }
}

- (void)setBundlePath:(id)sender
{
  NSString *path = [bundlePathField stringValue];
  
  if (path) {
    [[NSUserDefaults standardUserDefaults] setObject:path forKey:BundlePaths];
    [preferencesDict setObject:path forKey:BundlePaths];
  }
}

- (void)promptWhenQuitting:(id)sender
{
  NSUserDefaults *def = [NSUserDefaults standardUserDefaults];

  switch ([[sender selectedCell] state]) {
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

- (void)setTabBehaviour:(id)sender
{
    NSUserDefaults *def = [NSUserDefaults standardUserDefaults];

    switch ([[sender selectedCell] tag]) 
    {
        case 0:
//            [PCEditorView setTabBehaviour:PCTabTab];
	    [def setObject:@"Tab" forKey:TabBehaviour];
            break;
        case 1:
//            [PCEditorView setTabBehaviour:PCTab2Sp];
	    [def setObject:@"Sp2" forKey:TabBehaviour];
            break;
        case 2:
//            [PCEditorView setTabBehaviour:PCTab4Sp];
	    [def setObject:@"Sp4" forKey:TabBehaviour];
            break;
        case 3:
//            [PCEditorView setTabBehaviour:PCTab8Sp];
	    [def setObject:@"Sp8" forKey:TabBehaviour];
            break;
    }
    [def synchronize];

    [preferencesDict setObject:[def objectForKey:TabBehaviour] 
                        forKey:TabBehaviour];
}

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

- (NSDictionary *)preferencesDict
{
    return preferencesDict;
}

- (NSString *)selectFileWithTypes:(NSArray *)types
{
    NSString 	   *file = nil;
    NSOpenPanel	   *openPanel;
    int		    retval;
    NSUserDefaults *def = [NSUserDefaults standardUserDefaults];

    openPanel = [NSOpenPanel openPanel];
    [openPanel setAllowsMultipleSelection:NO];
    [openPanel setCanChooseDirectories:YES];
    [openPanel setCanChooseFiles:YES];

    retval = [openPanel runModalForDirectory:[def objectForKey:@"LastOpenDirectory"] file:nil types:types];

    if (retval == NSOKButton) 
    {
	[def setObject:[openPanel directory] forKey:@"LastOpenDirectory"];
	file = [[openPanel filenames] objectAtIndex:0];
	
    }
    return file;
}

@end

