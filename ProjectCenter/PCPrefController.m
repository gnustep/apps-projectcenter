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
  unsigned int style = NSTitledWindowMask | NSClosableWindowMask | 
                       NSResizableWindowMask;
  NSRect _w_frame;
  NSBox *line;
  NSBox *v;
  NSButton *b;

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

  /*
   * Misc view
   *
   */

  prefMiscView = [[NSBox alloc] init];
  [prefMiscView setTitlePosition:NSNoTitle];
  [prefMiscView setFrameFromContentFrame:NSMakeRect(1,1,260,308)];
  [prefMiscView setBorderType:NSNoBorder];

  v = [[[NSBox alloc] init] autorelease];
  [v setTitle:@"External"];
  [v setFrameFromContentFrame:NSMakeRect(16,184,228,96)];
  [prefMiscView addSubview:v];

  v = [[[NSBox alloc] init] autorelease];
  [v setTitle:@"Bundles"];
  [v setFrameFromContentFrame:NSMakeRect(16,120,228,48)];
  [prefMiscView addSubview:v];

  b = [[[NSButton alloc] initWithFrame:NSMakeRect(32,80,144,15)] autorelease];
  [b setTitle:@"Prompt when quitting"];
  [b setButtonType:NSSwitchButton];
  [b setBordered:NO];
  [b setTarget:self];
  //  [b setAction:@selector(setPromptOnClean:)];
  [b setContinuous:NO];
  [prefMiscView addSubview:b];

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

  b = [[[NSButton alloc] initWithFrame:NSMakeRect(13,32,124,15)] autorelease];
  [b setTitle:@"Save Automatically"];
  [b setButtonType:NSSwitchButton];
  [b setBordered:NO];
  [b setTarget:self];
  [b setAction:@selector(setSaveAutomatically:)];
  [b setContinuous:NO];
  [v addSubview:b];

  b = [[[NSButton alloc] initWithFrame:NSMakeRect(13,13,124,15)] autorelease];
  [b setTitle:@"Remoe Backup"];
  [b setButtonType:NSSwitchButton];
  [b setBordered:NO];
  [b setTarget:self];
  [b setAction:@selector(setRemoveBackup:)];
  [b setContinuous:NO];
  [v addSubview:b];

  v = [[[NSBox alloc] init] autorelease];
  [v setTitle:@"Auto-Save"];
  [v setFrameFromContentFrame:NSMakeRect(16,104,228,80)];
  [prefSavingView addSubview:v];

  _needsReleasing = YES;
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
  
  if (_needsReleasing) {
    [prefWindow release];
    [prefPopup release];

    [prefEmptyView release];
    [prefBuildingView release];
    [prefMiscView release];
    [prefSavingView release];
  }
  
  [super dealloc];
}

- (void)showPrefWindow:(id)sender
{
  if (!prefWindow) {
    id	     view;
    NSString *val;
    
#if defined(GNUSTEP)
    [self _initUI];
#else
    if(![NSBundle loadNibNamed:@"Preferences.nib" owner:self]) {
      [[NSException exceptionWithName:NIB_NOT_FOUND_EXCEPTION reason:@"Could not load Preferences.gmodel" userInfo:nil] raise];
      return;
    }
#endif
    
    // Fill in the defaults
    [compilerField setStringValue:(val=[preferencesDict objectForKey:Compiler]) ? val : @""];
    [debuggerField setStringValue:(val=[preferencesDict objectForKey:Debugger]) ? val : @""];
    [editorField setStringValue:(val=[preferencesDict objectForKey:Editor]) ? val : @""];
    [bundlePathField setStringValue:(val=[preferencesDict objectForKey:BundlePaths]) ? val : @""];
    
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
  
  [prefWindow center];
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

- (void)setEditor:(id)sender
{
    NSString *path = [self selectFileWithTypes:[NSArray arrayWithObjects:@"app",nil]];

    if (path) {
        [editorField setStringValue:path];

        [[NSUserDefaults standardUserDefaults] setObject:path forKey:Editor];
        [preferencesDict setObject:path forKey:Editor];
    }
}

- (void)setCompiler:(id)sender
{
    NSString *path = [self selectFileWithTypes:nil];

    if (path) {
        [compilerField setStringValue:path];

        [[NSUserDefaults standardUserDefaults] setObject:path forKey:Compiler];
        [preferencesDict setObject:path forKey:Compiler];
    }
}

- (void)setDebugger:(id)sender
{
    NSString *path = [self selectFileWithTypes:nil];

    if (path) {
        [debuggerField setStringValue:path];

        [[NSUserDefaults standardUserDefaults] setObject:path forKey:Debugger];
        [preferencesDict setObject:path forKey:Debugger];
    }
}

- (void)setBundlePath:(id)sender
{
    NSString *path = [self selectFileWithTypes:[NSArray arrayWithObjects:@"bundle",nil]];

    if (path) {
        [bundlePathField setStringValue:path];

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





