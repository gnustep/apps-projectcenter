/*
   GNUstep ProjectCenter - http://www.gnustep.org

   Copyright (C) 2003 Free Software Foundation

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

@implementation PCPrefController (UInterface)

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
  RELEASE(prefPopup);

  line = [[NSBox alloc] init];
  [line setTitlePosition: NSNoTitle];
  [line setFrameFromContentFrame: NSMakeRect(0,312,270,2)];
  [_c_view addSubview:line];
  RELEASE(line);

  prefEmptyView = [[NSBox alloc] init];
  [prefEmptyView setTitlePosition: NSNoTitle];
  [prefEmptyView setFrameFromContentFrame: NSMakeRect(0,0,270,312)];
  [prefEmptyView setBorderType: NSNoBorder];
  [_c_view addSubview: prefEmptyView];
  RELEASE(prefEmptyView);

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
  RELEASE(successField);

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
  RELEASE(failureField);

  promptOnClean = [[NSButton alloc] initWithFrame: NSMakeRect(72,170,108,21)];
  [promptOnClean setTitle: @"Prompt on clean"];
  [promptOnClean setButtonType: NSSwitchButton];
  [promptOnClean setBordered: NO];
  [promptOnClean setRefusesFirstResponder: YES];
  [promptOnClean setTarget: self];
  [promptOnClean setAction: @selector (setPromptOnClean:)];
  [promptOnClean setContinuous: NO];
  [prefBuildingView addSubview: promptOnClean];
  [promptOnClean sizeToFit];
  RELEASE(promptOnClean);

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
  RELEASE(saveOnQuit);

  saveAutomatically=[[NSButton alloc] initWithFrame: NSMakeRect (24,32,124,15)];
  [saveAutomatically setTitle: @"Save Project Automatically"];
  [saveAutomatically setButtonType: NSSwitchButton];
  [saveAutomatically setBordered :NO];
  [saveAutomatically setTarget: self];
  [saveAutomatically setAction: @selector (setSaveAutomatically:)];
  [saveAutomatically setContinuous: NO];
  [v addSubview: saveAutomatically];
  [saveAutomatically sizeToFit];
  RELEASE(saveAutomatically);

  keepBackup = [[NSButton alloc] initWithFrame: NSMakeRect (24,12,124,15)];
  [keepBackup setTitle: @"Keep Project Backup"];
  [keepBackup setButtonType: NSSwitchButton];
  [keepBackup setBordered: NO];
  [keepBackup setTarget: self];
  [keepBackup setAction: @selector (setKeepBackup:)];
  [keepBackup setContinuous: NO];
  [v addSubview: keepBackup];
  [keepBackup sizeToFit];
  RELEASE(keepBackup);

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
  RELEASE(autoSaveField);

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
  RELEASE(editorField);

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
  RELEASE(compilerField);

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
  RELEASE(debuggerField);

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
  RELEASE(bundlePathField);

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
  RELEASE(separateBuilder);

  separateLauncher = [[NSButton alloc] initWithFrame: NSMakeRect(48,27,124,21)];
  [separateLauncher setTitle: @"Project Launcher"];
  [separateLauncher setButtonType: NSSwitchButton];
  [separateLauncher setBordered: NO];
  [separateLauncher setRefusesFirstResponder: YES];
  [separateLauncher setTarget: self];
  [separateLauncher setAction: @selector (setDisplayPanels:)];
  [separateLauncher setContinuous: NO];
  [v addSubview: separateLauncher];
  RELEASE(separateLauncher);

  separateEditor = [[NSButton alloc] initWithFrame: NSMakeRect(48,6,124,21)];
  [separateEditor setTitle: @"Project Editor"];
  [separateEditor setButtonType: NSSwitchButton];
  [separateEditor setBordered: NO];
  [separateEditor setRefusesFirstResponder: YES];
  [separateEditor setTarget: self];
  [separateEditor setAction: @selector (setDisplayPanels:)];
  [separateEditor setContinuous: NO];
  [v addSubview: separateEditor];
  RELEASE(separateEditor);

  // Some buttons
  v = [[NSBox alloc] initWithFrame: NSMakeRect(5,100,254,98)];
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
  RELEASE(promptWhenQuit);

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
  RELEASE(useExternalEditor);

  useExternalDebugger=[[NSButton alloc] initWithFrame:NSMakeRect(48,49,204,21)];
  [useExternalDebugger setTitle: @"Use external Debugger"];
  [useExternalDebugger setButtonType: NSSwitchButton];
  [useExternalDebugger setBordered: NO];
  [useExternalDebugger setRefusesFirstResponder: YES];
  [useExternalDebugger setTarget: self];
  [useExternalDebugger setAction: @selector(setUseExternalDebugger:)];
  [useExternalDebugger setContinuous: NO];
  [v addSubview: useExternalDebugger];
  [useExternalDebugger sizeToFit];
  RELEASE(useExternalDebugger);
}

@end

