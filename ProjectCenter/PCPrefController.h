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

#ifndef _PCPREFCONTROLLER_H
#define _PCPREFCONTROLLER_H

#include <AppKit/AppKit.h>

@interface PCPrefController : NSObject
{
  id prefWindow;
  id prefPopup;
  
  id prefEmptyView;
  id prefBuildingView;
  id prefMiscView;
  id prefEditingView;
  id prefSavingView;
  id prefInterfaceView;
  
  id tabMatrix;

  id successField;
  id failureField;
  
  id autoSaveField;
  id saveAutomatically;
  id keepBackup;
  id saveOnQuit;

  id useExternalEditor;
  id promptWhenQuit;
  id promptOnClean;
  
  id editorField;
  id debuggerField;
  id compilerField;
  id bundlePathField;
  
  id separateBuilder;
  id separateLauncher;
  id separateEditor;
  
  NSMutableDictionary *preferencesDict;
}

- (id)init;
- (void)dealloc;

- (void)showPrefWindow:(id)sender;
- (void)popupChanged:(id)sender;

- (void)setSuccessSound:(id)sender;
- (void)setFailureSound:(id)sender;
- (void)setPromptOnClean:(id)sender;

- (void)setSaveAutomatically:(id)sender;
- (void)setKeepBackup:(id)sender;
- (void)setSavePeriod:(id)sender;
- (void)setSaveOnQuit:(id)sender;

- (void)setUseExternalEditor:(id)sender;

- (void)setEditor:(id)sender;
- (void)setCompiler:(id)sender;
- (void)setDebugger:(id)sender;
- (void)setBundlePath:(id)sender;
- (void)promptWhenQuitting:(id)sender;

- (void)setTabBehaviour:(id)sender;

- (NSDictionary *)preferencesDict;

- (NSString *)selectFileWithTypes:(NSArray *)types;

@end

extern NSString *SavePeriodDidChangeNotification;

#endif
