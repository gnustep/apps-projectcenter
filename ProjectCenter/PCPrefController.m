/*
   GNUstep ProjectCenter - http://www.projectcenter.ch

   Copyright (C) 2000 Philippe C.D. Robert

   Author: Philippe C.D. Robert <phr@projectcenter.ch>

   This file is part of ProjectCenter.

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

#import "PCPrefController.h"
#import <ProjectCenter/ProjectCenter.h>

#if defined(GNUSTEP)
#import <AppKit/IMLoading.h>
#endif

@interface PCPrefController (CreateUI)

- (void)_initUI;

@end

@implementation PCPrefController (CreateUI)

- (void)_initUI
{
  NSView *_c_view;
  unsigned int style = NSTitledWindowMask | NSClosableWindowMask;
  NSRect _w_frame;
  NSBox *line;
  NSBox *v;
  NSButton *b;
  NSTextField *textField;

  /*
   * Pref Window
   *
   */

  _w_frame = NSMakeRect(200,300,268,365);
  prefWindow = [[NSWindow alloc] initWithContentRect:_w_frame
                                           styleMask:style
                                             backing:NSBackingStoreBuffered
                                               defer:NO];
  [prefWindow setMinSize:NSMakeSize(268,365)];
  [prefWindow setTitle:@"Preferences"];
  [prefWindow setDelegate:self];
  [prefWindow setReleasedWhenClosed:NO];
  [prefWindow setFrameAutosaveName:@"Preferences"];
  _c_view = [prefWindow contentView];

  prefPopup = [[NSPopUpButton alloc] initWithFrame:NSMakeRect(72,328,120,20)];
  [prefPopup addItemWithTitle:@"None"];
  [prefPopup setTarget:self];
  [prefPopup setAction:@selector(popupChanged:)];
  [_c_view addSubview:prefPopup];

  line = [[[NSBox alloc] init] autorelease];
  [line setTitlePosition:NSNoTitle];
  [line setFrameFromContentFrame:NSMakeRect(0,312,272,2)];
  [_c_view addSubview:line];

  prefEmptyView = [[NSBox alloc] init];
  [prefEmptyView setTitlePosition:NSNoTitle];
  [prefEmptyView setFrameFromContentFrame:NSMakeRect(-1,1,270,310)];
  [prefEmptyView setBorderType:NSNoBorder];
  [_c_view addSubview:prefEmptyView];

  /*
   * Building view
   *
   */
	
  prefBuildingView = [[NSBox alloc] init];
  [prefBuildingView setTitlePosition:NSNoTitle];
  [prefBuildingView setFrameFromContentFrame:NSMakeRect(1,1,260,308)];
  [prefBuildingView setBorderType:NSNoBorder];

  v = [[[NSBox alloc] init] autorelease];
  [v setTitle:@"Sound"];
  [v setFrameFromContentFrame:NSMakeRect(16,208,228,72)];
  [prefBuildingView addSubview:v];

  b = [[[NSButton alloc] initWithFrame:NSMakeRect(72,176,108,15)] autorelease];
  [b setTitle:@"Prompt on clean"];
  [b setButtonType:NSSwitchButton];
  [b setBordered:NO];
  [b setTarget:self];
  [b setAction:@selector(setPromptOnClean:)];
  [b setContinuous:NO];
  [prefBuildingView addSubview:b];
  [b sizeToFit];

  /*
   * Misc view
   *
   */

  prefMiscView = [[NSBox alloc] init];
  [prefMiscView setTitlePosition:NSNoTitle];
  [prefMiscView setFrameFromContentFrame:NSMakeRect(1,1,260,308)];
  [prefMiscView setBorderType:NSNoBorder];

  v = [[[NSBox alloc] init] autorelease];
  [v setTitle:@"External Tools"];
  [v setFrameFromContentFrame:NSMakeRect(16,184,228,96)];
  [prefMiscView addSubview:v];

  /*
   * Editor
   */

  textField = [[NSTextField alloc] initWithFrame:NSMakeRect(12,24,60,21)];
  [textField setAlignment: NSRightTextAlignment];
  [textField setBordered: NO];
  [textField setEditable: NO];
  [textField setBezeled: NO];
  [textField setDrawsBackground: NO];
  [textField setStringValue:@"Editor:"];
  [v addSubview:[textField autorelease]];

  editorField = [[NSTextField alloc] initWithFrame:NSMakeRect(72,24,144,21)];
  [editorField setAlignment: NSLeftTextAlignment];
  [editorField setBordered: NO];
  [editorField setEditable: YES];
  [editorField setBezeled: YES];
  [editorField setDrawsBackground: YES];
  [editorField setTarget:self];
  [editorField setAction:@selector(setEditor:)];
  [v addSubview:[editorField autorelease]];

  /*
   * Compiler
   */

  textField = [[NSTextField alloc] initWithFrame:NSMakeRect(12,48,60,21)];
  [textField setAlignment: NSRightTextAlignment];
  [textField setBordered: NO];
  [textField setEditable: NO];
  [textField setBezeled: NO];
  [textField setDrawsBackground: NO];
  [textField setStringValue:@"Compiler:"];
  [v addSubview:[textField autorelease]];

  compilerField = [[NSTextField alloc] initWithFrame:NSMakeRect(72,48,144,21)];
  [compilerField setAlignment: NSLeftTextAlignment];
  [compilerField setBordered: NO];
  [compilerField setEditable: YES];
  [compilerField setBezeled: YES];
  [compilerField setDrawsBackground: YES];
  [compilerField setTarget:self];
  [compilerField setAction:@selector(setCompiler:)];
  [v addSubview:[compilerField autorelease]];

  /*
   * Debugger
   */

  textField = [[NSTextField alloc] initWithFrame:NSMakeRect(12,72,60,21)];
  [textField setAlignment: NSRightTextAlignment];
  [textField setBordered: NO];
  [textField setEditable: NO];
  [textField setBezeled: NO];
  [textField setDrawsBackground: NO];
  [textField setStringValue:@"Debugger:"];
  [v addSubview:[textField autorelease]];

  debuggerField = [[NSTextField alloc] initWithFrame:NSMakeRect(72,72,144,21)];
  [debuggerField setAlignment: NSLeftTextAlignment];
  [debuggerField setBordered: NO];
  [debuggerField setEditable: YES];
  [debuggerField setBezeled: YES];
  [debuggerField setDrawsBackground: YES];
  [debuggerField setTarget:self];
  [debuggerField setAction:@selector(setDebugger:)];
  [v addSubview:[debuggerField autorelease]];

  /*
   * Bundles Box
   */

  v = [[[NSBox alloc] init] autorelease];
  [v setTitle:@"Bundle Path"];
  [v setFrameFromContentFrame:NSMakeRect(16,96,228,48)];
  [prefMiscView addSubview:v];

  /*
   * Bundle path
   */

  bundlePathField = [[NSTextField alloc] initWithFrame:NSMakeRect(12,24,212,21)];
  [bundlePathField setAlignment: NSLeftTextAlignment];
  [bundlePathField setBordered: NO];
  [bundlePathField setEditable: YES];
  [bundlePathField setBezeled: YES];
  [bundlePathField setDrawsBackground: YES];
  [bundlePathField setTarget:self];
  [bundlePathField setAction:@selector(setBundlePath:)];
  [v addSubview:[bundlePathField autorelease]];

  /*
   * Some buttons
   */

  useExternalEditor = [[[NSButton alloc] initWithFrame:NSMakeRect(32,24,204,15)] autorelease];
  [useExternalEditor setTitle:@"use external Editor"];
  [useExternalEditor setButtonType:NSSwitchButton];
  [useExternalEditor setBordered:NO];
  [useExternalEditor setTarget:self];
  [useExternalEditor setAction:@selector(setUseExternalEditor:)];
  [useExternalEditor setContinuous:NO];
  [prefMiscView addSubview:useExternalEditor];
  [useExternalEditor sizeToFit];

  b = [[[NSButton alloc] initWithFrame:NSMakeRect(32,44,204,15)] autorelease];
  [b setTitle:@"Prompt when quitting"];
  [b setButtonType:NSSwitchButton];
  [b setBordered:NO];
  [b setTarget:self];
  // [b setAction:@selector()];
  [b setContinuous:NO];
  [prefMiscView addSubview:b];
  [b sizeToFit];

  /*
   * Saving view
   *
   */

  prefSavingView = [[NSBox alloc] init];
  [prefSavingView setTitlePosition:NSNoTitle];
  [prefSavingView setFrameFromContentFrame:NSMakeRect(1,1,260,308)];
  [prefSavingView setBorderType:NSNoBorder];

  v = [[[NSBox alloc] init] autorelease];
  [v setTitle:@"Saving"];
  [v setFrameFromContentFrame:NSMakeRect(16,208,228,72)];
  [prefSavingView addSubview:v];

  b = [[[NSButton alloc] initWithFrame:NSMakeRect(24,32,124,15)] autorelease];
  [b setTitle:@"Save Automatically"];
  [b setButtonType:NSSwitchButton];
  [b setBordered:NO];
  [b setTarget:self];
  [b setAction:@selector(setSaveAutomatically:)];
  [b setContinuous:NO];
  [v addSubview:b];
  [b sizeToFit];

  b = [[[NSButton alloc] initWithFrame:NSMakeRect(24,12,124,15)] autorelease];
  [b setTitle:@"Remove Backup"];
  [b setButtonType:NSSwitchButton];
  [b setBordered:NO];
  [b setTarget:self];
  [b setAction:@selector(setRemoveBackup:)];
  [b setContinuous:NO];
  [v addSubview:b];
  [b sizeToFit];

  v = [[[NSBox alloc] init] autorelease];
  [v setTitle:@"Auto-Save"];
  [v setFrameFromContentFrame:NSMakeRect(16,104,228,48)];
  [prefSavingView addSubview:v];
}

@end

@implementation PCPrefController

- (id)init
{
  if ((self = [super init])) {
    NSDictionary	*prefs;
    
    // The prefs from the defaults
    prefs = [[NSUserDefaults standardUserDefaults] dictionaryRepresentation];
    preferencesDict = [[NSMutableDictionary alloc] initWithDictionary:prefs];
  }
  return self;
}

- (void)dealloc
{
  [preferencesDict release];
  
  [prefWindow release];
  [prefPopup release];
  
  [prefEmptyView release];
  [prefBuildingView release];
  [prefMiscView release];
  [prefSavingView release];

  [[NSUserDefaults standardUserDefaults] synchronize];

  [super dealloc];
}

- (void)showPrefWindow:(id)sender
{
  NSDictionary *prefs;
  NSString *val;

  if (!prefWindow) {
    id	     view;
    
    [self _initUI];
    
    // The popup and selected view
    [prefPopup removeAllItems];
    [prefPopup addItemWithTitle:@"Building"];
    [prefPopup addItemWithTitle:@"Saving"];
    [prefPopup addItemWithTitle:@"Miscellaneous"];
    
    [prefPopup selectItemWithTitle:@"Building"];
    
    view = [prefBuildingView retain];
    [(NSBox *)prefEmptyView setContentView:view];
    [prefEmptyView display]; 
  }

  prefs = [[NSUserDefaults standardUserDefaults] dictionaryRepresentation];
  [preferencesDict addEntriesFromDictionary:prefs];
  
  // Fill in the defaults
  [compilerField setStringValue:(val=[preferencesDict objectForKey:Compiler]) ? val : @""];
  [debuggerField setStringValue:(val=[preferencesDict objectForKey:Debugger]) ? val : @""];
  [editorField setStringValue:(val=[preferencesDict objectForKey:Editor]) ? val : @""];
  [bundlePathField setStringValue:(val=[preferencesDict objectForKey:BundlePaths]) ? val : @""];
  
  [useExternalEditor setState:([[preferencesDict objectForKey:ExternalEditor] isEqualToString:@"YES"])?NSOnState:NSOffState];

  if (![prefWindow isVisible]) { 
    [prefWindow setFrameUsingName:@"Preferences"];
  }
  [prefWindow makeKeyAndOrderFront:self];
}

- (void)popupChanged:(id)sender
{
    NSView *view = nil;

    switch([sender indexOfSelectedItem]) {
        case 0:
            view = [prefBuildingView retain];
            break;
        case 1:
            view = [prefSavingView retain];
            break;
        case 2:
            view = [prefMiscView retain];
            break;
    }
    [(NSBox *)prefEmptyView setContentView:view];
    [prefEmptyView display];
}

- (void)setSuccessSound:(id)sender
{
    NSString *path = [self selectFileWithTypes:[NSArray arrayWithObjects:@"snd",@"au",nil]];

    if (path) {
        [successField setStringValue:path];

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
}

- (void)setSaveAutomatically:(id)sender
{
}

- (void)setRemoveBackup:(id)sender
{
}

- (void)setSavePeriod:(id)sender
{
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
    [[NSUserDefaults standardUserDefaults] setObject:path forKey:Debugger];
    [preferencesDict setObject:path forKey:Debugger];
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
}

- (NSDictionary *)preferencesDict
{
    return preferencesDict;
}

- (NSString *)selectFileWithTypes:(NSArray *)types
{
  NSString 	*file = nil;
  NSOpenPanel	*openPanel;
  int		retval;

  openPanel = [NSOpenPanel openPanel];
  [openPanel setAllowsMultipleSelection:NO];
  [openPanel setCanChooseDirectories:YES];
  [openPanel setCanChooseFiles:YES];

  retval = [openPanel runModalForDirectory:[[NSUserDefaults standardUserDefaults] objectForKey:@"LastOpenDirectory"] file:nil types:types];
  
  if (retval == NSOKButton) {
    [[NSUserDefaults standardUserDefaults] setObject:[openPanel directory] forKey:@"LastOpenDirectory"];
    file = [[openPanel filenames] objectAtIndex:0];
    
  }
  return file;
}

@end





