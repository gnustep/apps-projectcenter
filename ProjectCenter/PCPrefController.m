/*
   GNUstep ProjectCenter - http://www.gnustep.org

   Copyright (C) 2001 Free Software Foundation

   Author: Philippe C.D. Robert <phr@3dkit.org>

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
#include <ProjectCenter/ProjectCenter.h>

#if defined(GNUSTEP)
#include <AppKit/IMLoading.h>
#endif

NSString *SavePeriodDidChangeNotification = @"SavePeriodDidChangeNotification";

@interface PCPrefController (CreateUI)

- (void)_initUI;

@end

@implementation PCPrefController (CreateUI)

- (void)_initUI
{
  NSView       *_c_view;
  unsigned int style = NSTitledWindowMask | NSClosableWindowMask;
  NSRect       _w_frame;
  NSBox        *line;
  NSBox        *v;
  NSTextField  *textField;
  NSButtonCell *cell;

  /*
   * Pref Window
   *
   */

  _w_frame = NSMakeRect(200,300,270,365);
  prefWindow = [[NSWindow alloc] initWithContentRect:_w_frame
                                           styleMask:style
                                             backing:NSBackingStoreBuffered
                                               defer:YES];
  [prefWindow setMinSize: NSMakeSize (270,365)];
  [prefWindow setTitle: @"Preferences"];
  [prefWindow setDelegate: self];
  [prefWindow setReleasedWhenClosed: NO];
  [prefWindow center];
  [prefWindow setFrameAutosaveName: @"Preferences"];
  _c_view = [prefWindow contentView];

  prefPopup = [[NSPopUpButton alloc] initWithFrame: NSMakeRect (72,334,120,21)];
  [prefPopup addItemWithTitle: @"None"];
  [prefPopup setTarget: self];
  [prefPopup setAction: @selector (popupChanged:)];
  [_c_view addSubview: prefPopup];

  line = [[NSBox alloc] init];
  [line setTitlePosition: NSNoTitle];
  [line setFrameFromContentFrame: NSMakeRect(0,312,270,2)];
  [_c_view addSubview:line];
  RELEASE(line);

  prefEmptyView = [[NSBox alloc] init];
  [prefEmptyView setTitlePosition: NSNoTitle];
  [prefEmptyView setFrameFromContentFrame: NSMakeRect(0,0,270,310)];
  [prefEmptyView setBorderType: NSNoBorder];
  [_c_view addSubview: prefEmptyView];

  /*
   * Building view
   *
   */
  prefBuildingView = [[NSBox alloc] initWithFrame: NSMakeRect(0,0,270,310)];
  [prefBuildingView setTitlePosition:NSNoTitle];
  [prefBuildingView setBorderType:NSNoBorder];

  v = [[NSBox alloc] initWithFrame: NSMakeRect(5,208,254,102)];
  [v setTitle: @"Sounds"];
  [prefBuildingView addSubview: v];
  RELEASE(v);
  
  textField = [[NSTextField alloc] initWithFrame: NSMakeRect(0,40,54,21)];
  [textField setAlignment: NSRightTextAlignment];
  [textField setBordered: NO];
  [textField setEditable: NO];
  [textField setBezeled: NO];
  [textField setDrawsBackground: NO];
  [textField setStringValue: @"Success:"];
  [v addSubview:textField];
  RELEASE(textField);

  successField = [[NSTextField alloc] initWithFrame:NSMakeRect(58,40,144,21)];
  [successField setAlignment: NSLeftTextAlignment];
  [successField setBordered: NO];
  [successField setEditable: YES];
  [successField setBezeled: YES];
  [successField setDrawsBackground: YES];
  [successField setTarget: self];
  [successField setAction: @selector (setSuccessSound:)];
  [v addSubview: successField];

  textField = [[NSTextField alloc] initWithFrame: NSMakeRect(0,16,54,21)];
  [textField setAlignment: NSRightTextAlignment];
  [textField setBordered: NO];
  [textField setEditable: NO];
  [textField setBezeled: NO];
  [textField setDrawsBackground: NO];
  [textField setStringValue: @"Failure:"];
  [v addSubview:textField];
  RELEASE(textField);

  failureField = [[NSTextField alloc] initWithFrame:NSMakeRect(58,16,144,21)];
  [failureField setAlignment: NSLeftTextAlignment];
  [failureField setBordered: NO];
  [failureField setEditable: YES];
  [failureField setBezeled: YES];
  [failureField setDrawsBackground: YES];
  [failureField setTarget: self];
  [failureField setAction: @selector (setFailureSound:)];
  [v addSubview: failureField];

  promptOnClean = [[NSButton alloc] initWithFrame: NSMakeRect(72,176,108,15)];
  [promptOnClean setTitle: @"Prompt on clean"];
  [promptOnClean setButtonType: NSSwitchButton];
  [promptOnClean setBordered: NO];
  [promptOnClean setRefusesFirstResponder: YES];
  [promptOnClean setTarget: self];
  [promptOnClean setAction: @selector (setPromptOnClean:)];
  [promptOnClean setContinuous: NO];
  [prefBuildingView addSubview: promptOnClean];
  [promptOnClean sizeToFit];

  /*
   * Saving view
   */
  prefSavingView = [[NSBox alloc] initWithFrame: NSMakeRect (0,0,270,310)];
  [prefSavingView setTitlePosition: NSNoTitle];
  [prefSavingView setBorderType: NSNoBorder];

  v = [[NSBox alloc] initWithFrame: NSMakeRect (5,208,254,102)];
  [v setTitle: @"Saving"];
  [prefSavingView addSubview: v];
  RELEASE(v);

  saveOnQuit=[[NSButton alloc] initWithFrame: NSMakeRect (24,52,124,15)];
  [saveOnQuit setTitle: @"Save Projects Upon Quit"];
  [saveOnQuit setButtonType: NSSwitchButton];
  [saveOnQuit setBordered: NO];
  [saveOnQuit setTarget: self];
  [saveOnQuit setAction: @selector (setSaveOnQuit:)];
  [saveOnQuit setContinuous: NO];
  [v addSubview: saveOnQuit];
  [saveOnQuit sizeToFit];

  saveAutomatically=[[NSButton alloc] initWithFrame: NSMakeRect (24,32,124,15)];
  [saveAutomatically setTitle: @"Save Project Automatically"];
  [saveAutomatically setButtonType: NSSwitchButton];
  [saveAutomatically setBordered :NO];
  [saveAutomatically setTarget: self];
  [saveAutomatically setAction: @selector (setSaveAutomatically:)];
  [saveAutomatically setContinuous: NO];
  [v addSubview: saveAutomatically];
  [saveAutomatically sizeToFit];

  keepBackup = [[NSButton alloc] initWithFrame: NSMakeRect (24,12,124,15)];
  [keepBackup setTitle: @"Keep Project Backup"];
  [keepBackup setButtonType: NSSwitchButton];
  [keepBackup setBordered: NO];
  [keepBackup setTarget: self];
  [keepBackup setAction: @selector (setKeepBackup:)];
  [keepBackup setContinuous: NO];
  [v addSubview: keepBackup];
  [keepBackup sizeToFit];

  v = [[NSBox alloc] initWithFrame: NSMakeRect(5,149,254,49)];
  [v setTitle: @"Auto-Save"];
  [prefSavingView addSubview: v];
  RELEASE(v);

  textField = [[NSTextField alloc] initWithFrame: NSMakeRect(12,0,54,21)];
  [textField setAlignment: NSRightTextAlignment];
  [textField setBordered: NO];
  [textField setEditable: NO];
  [textField setBezeled: NO];
  [textField setDrawsBackground: NO];
  [textField setStringValue: @"Seconds:"];
  [v addSubview: textField];
  RELEASE(textField);

  autoSaveField = [[NSTextField alloc] initWithFrame:NSMakeRect(72,0,144,21)];
  [autoSaveField setAlignment: NSLeftTextAlignment];
  [autoSaveField setBordered: NO];
  [autoSaveField setEditable: YES];
  [autoSaveField setBezeled: YES];
  [autoSaveField setDrawsBackground: YES];
  [autoSaveField setTarget:self];
  [autoSaveField setAction:@selector(setSavePeriod:)];
  [v addSubview:autoSaveField];

  /*
   * Editing view
   */
  prefEditingView = [[NSBox alloc] initWithFrame: NSMakeRect (0,0,270,310)];
  [prefEditingView setTitlePosition: NSNoTitle];
  [prefEditingView setBorderType: NSNoBorder];

  v = [[NSBox alloc] initWithFrame: NSMakeRect(5,208,254,102)];
  [v setTitle:@"Tab Control"];
  [prefEditingView addSubview:v];
  RELEASE(v);

  cell = [[NSButtonCell alloc] init];
  [cell setButtonType: NSRadioButton];
  [cell setBordered: NO];
  [cell setImagePosition: NSImageLeft]; 

  tabMatrix = [[NSMatrix alloc] initWithFrame: NSMakeRect(32,16,164,40)
                                      mode: NSRadioModeMatrix
                                 prototype: cell
                              numberOfRows: 2
                           numberOfColumns: 2];   

  [tabMatrix setIntercellSpacing: NSMakeSize (8, 8) ];
  [tabMatrix setTarget: self];
  [tabMatrix setAction: @selector (setTabBehaviour:)];
  [tabMatrix setAutosizesCells: NO];

  cell = [tabMatrix cellAtRow: 0 column: 0];
  [cell setTitle: @"Tabulator"];
  [cell setTag: 0];

  cell = [tabMatrix cellAtRow: 1 column: 0];
  [cell setTitle: @"2 Spaces"];
  [cell setTag: 1];

  cell = [tabMatrix cellAtRow: 0 column: 1];
  [cell setTitle: @"4 Spaces"];
  [cell setTag: 2];

  cell = [tabMatrix cellAtRow: 1 column: 1];
  [cell setTitle: @"8 Spaces"];
  [cell setTag: 3];

  [v addSubview:tabMatrix];
  RELEASE(tabMatrix);

  [tabMatrix selectCellAtRow: 0 column: 1];


  /*
   * Misc view
   *
   */
  prefMiscView = [[NSBox alloc] init];
  [prefMiscView setTitlePosition:NSNoTitle];
  [prefMiscView setFrameFromContentFrame:NSMakeRect(1,1,260,308)];
  [prefMiscView setBorderType:NSNoBorder];

  v = [[NSBox alloc] initWithFrame: NSMakeRect(5,189,254,121)];
  [v setTitle:@"External Tools"];
  [prefMiscView addSubview:v];
  RELEASE(v);

  // Editor
  textField = [[NSTextField alloc] initWithFrame:NSMakeRect(12,16,60,21)];
  [textField setAlignment: NSRightTextAlignment];
  [textField setBordered: NO];
  [textField setEditable: NO];
  [textField setBezeled: NO];
  [textField setDrawsBackground: NO];
  [textField setStringValue:@"Editor:"];
  [v addSubview:textField];
  RELEASE(textField);

  editorField = [[NSTextField alloc] initWithFrame:NSMakeRect(72,16,144,21)];
  [editorField setAlignment: NSLeftTextAlignment];
  [editorField setBordered: NO];
  [editorField setEditable: YES];
  [editorField setBezeled: YES];
  [editorField setDrawsBackground: YES];
  [editorField setTarget:self];
  [editorField setAction:@selector(setEditor:)];
  [v addSubview:editorField];

  // Compiler
  textField = [[NSTextField alloc] initWithFrame:NSMakeRect(12,40,60,21)];
  [textField setAlignment: NSRightTextAlignment];
  [textField setBordered: NO];
  [textField setEditable: NO];
  [textField setBezeled: NO];
  [textField setDrawsBackground: NO];
  [textField setStringValue:@"Compiler:"];
  [v addSubview:textField];
  RELEASE(textField);

  compilerField = [[NSTextField alloc] initWithFrame:NSMakeRect(72,40,144,21)];
  [compilerField setAlignment: NSLeftTextAlignment];
  [compilerField setBordered: NO];
  [compilerField setEditable: YES];
  [compilerField setBezeled: YES];
  [compilerField setDrawsBackground: YES];
  [compilerField setTarget:self];
  [compilerField setAction:@selector(setCompiler:)];
  [v addSubview:compilerField];

  // Debugger
  textField = [[NSTextField alloc] initWithFrame:NSMakeRect(12,64,60,21)];
  [textField setAlignment: NSRightTextAlignment];
  [textField setBordered: NO];
  [textField setEditable: NO];
  [textField setBezeled: NO];
  [textField setDrawsBackground: NO];
  [textField setStringValue:@"Debugger:"];
  [v addSubview:textField];
  RELEASE(textField);

  debuggerField = [[NSTextField alloc] initWithFrame:NSMakeRect(72,64,144,21)];
  [debuggerField setAlignment: NSLeftTextAlignment];
  [debuggerField setBordered: NO];
  [debuggerField setEditable: YES];
  [debuggerField setBezeled: YES];
  [debuggerField setDrawsBackground: YES];
  [debuggerField setTarget:self];
  [debuggerField setAction:@selector(setDebugger:)];
  [v addSubview:debuggerField];

  // Bundles Box
  v = [[NSBox alloc] initWithFrame: NSMakeRect(5,131,254,48)];
  [v setTitle: @"Bundle Path"];
  [prefMiscView addSubview: v];
  RELEASE(v);

  // Bundle path
  bundlePathField=[[NSTextField alloc] initWithFrame:NSMakeRect(12,0,212,21)];
  [bundlePathField setAlignment: NSLeftTextAlignment];
  [bundlePathField setBordered: NO];
  [bundlePathField setEditable: YES];
  [bundlePathField setBezeled: YES];
  [bundlePathField setDrawsBackground: YES];
  [bundlePathField setTarget:self];
  [bundlePathField setAction:@selector(setBundlePath:)];
  [v addSubview:bundlePathField];

  /*
   * Interface view
   */

  prefInterfaceView = [[NSBox alloc] initWithFrame: NSMakeRect (0,0,270,310)];
  [prefInterfaceView setTitlePosition: NSNoTitle];
  [prefInterfaceView setBorderType: NSNoBorder];

  v = [[NSBox alloc] initWithFrame: NSMakeRect (5,208,254,102)];
  [v setTitle: @"Display as separate panel..."];
  [prefInterfaceView addSubview: v];
  RELEASE(v);

  separateBuilder = [[NSButton alloc] initWithFrame: NSMakeRect (48,48,124,21)];
  [separateBuilder setTitle: @"Project Builder"];
  [separateBuilder setButtonType: NSSwitchButton];
  [separateBuilder setBordered: NO];
  [separateBuilder setRefusesFirstResponder: YES];
  [separateBuilder setTarget: self];
  [separateBuilder setAction: @selector (setDisplayPanels:)];
  [separateBuilder setContinuous: NO];
  [v addSubview: separateBuilder];

  separateLauncher = [[NSButton alloc] initWithFrame: NSMakeRect(48,27,124,21)];
  [separateLauncher setTitle: @"Project Launcher"];
  [separateLauncher setButtonType: NSSwitchButton];
  [separateLauncher setBordered: NO];
  [separateLauncher setRefusesFirstResponder: YES];
  [separateLauncher setTarget: self];
  [separateLauncher setAction: @selector (setDisplayPanels:)];
  [separateLauncher setContinuous: NO];
  [v addSubview: separateLauncher];

  separateEditor = [[NSButton alloc] initWithFrame: NSMakeRect(48,6,124,21)];
  [separateEditor setTitle: @"Project Editor"];
  [separateEditor setButtonType: NSSwitchButton];
  [separateEditor setBordered: NO];
  [separateEditor setRefusesFirstResponder: YES];
  [separateEditor setTarget: self];
  [separateEditor setAction: @selector (setDisplayPanels:)];
  [separateEditor setContinuous: NO];
  [v addSubview: separateEditor];

  // Some buttons
  v = [[NSBox alloc] initWithFrame: NSMakeRect(5,121,254,77)];
  [v setTitle: @"Misc"];
  [prefInterfaceView addSubview: v];
  RELEASE(v);

  promptWhenQuit = [[NSButton alloc] initWithFrame: NSMakeRect(48,7,204,21)];
  [promptWhenQuit setTitle: @"Prompt when quitting"];
  [promptWhenQuit setButtonType: NSSwitchButton];
  [promptWhenQuit setBordered: NO];
  [promptWhenQuit setRefusesFirstResponder: YES];
  [promptWhenQuit setTarget: self];
  [promptWhenQuit setAction: @selector (promptWhenQuitting:)];
  [promptWhenQuit setContinuous: NO];
  [v addSubview: promptWhenQuit];
  [promptWhenQuit sizeToFit];

  useExternalEditor = [[NSButton alloc] initWithFrame:NSMakeRect(48,28,204,21)];
  [useExternalEditor setTitle: @"Use external Editor"];
  [useExternalEditor setButtonType: NSSwitchButton];
  [useExternalEditor setBordered: NO];
  [useExternalEditor setRefusesFirstResponder: YES];
  [useExternalEditor setTarget: self];
  [useExternalEditor setAction: @selector(setUseExternalEditor:)];
  [useExternalEditor setContinuous: NO];
  [v addSubview: useExternalEditor];
  [useExternalEditor sizeToFit];
}

@end

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
  RELEASE(prefPopup);
  
  RELEASE(prefEmptyView);
  RELEASE(prefBuildingView);
  RELEASE(prefMiscView);
  RELEASE(prefEditingView);
  RELEASE(prefSavingView);

  RELEASE(useExternalEditor);
  RELEASE(promptWhenQuit);
  RELEASE(promptOnClean);
  RELEASE(saveOnQuit);
  RELEASE(saveAutomatically);
  RELEASE(keepBackup);

  RELEASE(editorField);
  RELEASE(debuggerField);
  RELEASE(compilerField);
  RELEASE(bundlePathField);

  RELEASE(autoSaveField);

  [[NSUserDefaults standardUserDefaults] synchronize];

  [super dealloc];
}

- (void)showPrefWindow: (id)sender
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
  if( [[preferencesDict objectForKey: TabBehaviour] isEqualToString:@"Tab"] )
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


  if (![prefWindow isVisible])
    { 
      [prefWindow setFrameUsingName: @"Preferences"];
    }
  [prefWindow makeKeyAndOrderFront: self];
}

- (void)popupChanged:(id)sender
{
  NSView *view = nil;
  
  switch([sender indexOfSelectedItem]) 
  {
  case 0:
    view = [prefBuildingView retain];
    break;
  case 1:
    view = [prefSavingView retain];
    break;
  case 2:
    view = [prefEditingView retain];
    break;
  case 3:
    view = [prefMiscView retain];
    break;
  case 4:
    view = [prefInterfaceView retain];
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
  NSString       *key;

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

