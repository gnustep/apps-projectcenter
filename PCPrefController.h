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

#ifndef _PCPREFCONTROLLER_H
#define _PCPREFCONTROLLER_H

#include <AppKit/AppKit.h>

@interface PCPrefController : NSObject
{
  IBOutlet NSPanel       *panel;
  IBOutlet NSPopUpButton *popupButton;
  IBOutlet NSBox         *sectionsView;

  IBOutlet NSBox         *buildingView;
  IBOutlet NSTextField   *successField;
  IBOutlet NSButton      *setSuccessButton;
  IBOutlet NSTextField   *failureField;
  IBOutlet NSButton      *setFailureButton;
  IBOutlet NSButton      *promptOnClean;

  IBOutlet NSBox         *savingView;
  IBOutlet NSButton      *saveOnQuit;
  IBOutlet NSButton      *saveAutomatically;
  IBOutlet NSButton      *keepBackup;
  IBOutlet NSSlider      *autosaveSlider;
  IBOutlet NSTextField   *autosaveField;
  
  IBOutlet NSBox         *keyBindingsView;
  
  IBOutlet NSBox         *miscView;
  IBOutlet NSButton      *separateBuilder;
  IBOutlet NSButton      *separateLauncher;
  IBOutlet NSButton      *separateEditor;
  IBOutlet NSButton      *separateLoadedFiles;
  IBOutlet NSButton      *promptWhenQuit;
  IBOutlet NSTextField   *debuggerField;
  IBOutlet NSTextField   *editorField;
  
  IBOutlet NSBox         *bundlesView;
  IBOutlet NSTextField   *bundlePathField;
  
  NSMutableDictionary *preferencesDict;
}

+ (PCPrefController *)sharedPCPreferences;

- (id)init;
- (void)dealloc;

- (void)showPanel:(id)sender;
- (void)loadPrefernces;

- (void)popupChanged:(id)sender;

- (void)setSuccessSound:(id)sender;
- (void)setFailureSound:(id)sender;
- (void)setPromptOnClean:(id)sender;

- (void)setSaveAutomatically:(id)sender;
- (void)setKeepBackup:(id)sender;
- (void)setSaveOnQuit:(id)sender;
- (void)setSavePeriod:(id)sender;

- (void)promptWhenQuitting:(id)sender;
- (void)setDebugger:(id)sender;
- (void)setEditor:(id)sender;
- (void)setBundlePath:(id)sender;

- (NSDictionary *)preferencesDict;

- (NSString *)selectFileWithTypes:(NSArray *)types;

@end

extern NSString *SavePeriodDidChangeNotification;

#endif

