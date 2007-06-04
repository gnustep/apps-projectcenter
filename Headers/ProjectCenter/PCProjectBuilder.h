/*
   GNUstep ProjectCenter - http://www.gnustep.org/experience/ProjectCenter.html

   Copyright (C) 2000-2004 Free Software Foundation

   Authors: Philippe C.D. Robert
            Serg Stoyan

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

#ifndef _PCProjectBuilder_h_
#define _PCProjectBuilder_h_

#include <AppKit/AppKit.h>

@class PCProject;
@class PCButton;

typedef enum _ErrorLevel {
    ELFile,
    ELFunction,
    ELIncluded,
    ELIncludedError,
    ELError,
    ELNone
} ErrorLevel;

@interface PCProjectBuilder : NSObject
{
  PCProject       *project;
  NSDictionary    *currentOptions;

  NSString        *makePath;
  NSString        *statusString;
  NSMutableString *buildTarget;
  NSMutableArray  *buildArgs;
  SEL             postProcess;
  NSTask          *makeTask;

  NSFileHandle    *readHandle;
  NSFileHandle    *errorReadHandle;

  BOOL            _isBuilding;
  BOOL            _isCleaning;
  BOOL            _isLogging;
  BOOL            _isErrorLogging;

  // Component view
  BOOL            _isCVLoaded;
  NSBox           *componentView;
  PCButton        *buildButton;
  PCButton        *cleanButton;
  PCButton        *installButton;
  PCButton        *optionsButton;
  NSTextField     *errorsCountField;
  NSSplitView     *split;
  NSTextField     *buildStatusField;
  NSTextField     *targetField;

  // Error logging
  NSTableView     *errorOutput;
  NSTableColumn   *errorImageColumn;
  NSTableColumn   *errorColumn;
  NSMutableArray  *errorArray;
  NSMutableString *errorString;

  ErrorLevel      currentEL;
  ErrorLevel      lastEL;
  ErrorLevel      nextEL;
  NSString        *lastIndentString;
  int             errorsCount;
  int             warningsCount;

  // Output logging
  NSTextView      *logOutput;
  NSMutableString *currentBuildFile;
  NSMutableArray  *currentBuildPath;

  // Options panel
  NSPanel         *optionsPanel;
  NSPopUpButton   *targetPopup;
  NSTextField     *buildArgsField;
  NSButton        *debugButton;
  NSButton        *profileButton;
  NSButton        *sharedLibsButton;
  NSButton        *verboseButton;
}

- (id)initWithProject:(PCProject *)aProject;
- (void)dealloc;

- (NSView *)componentView;
- (BOOL)setMakePath;

// --- Accessory
- (BOOL)isBuilding;
- (BOOL)isCleaning;
- (void)performStartBuild;
- (void)performStartClean;
- (void)performStopBuild;

// --- Actions
- (void)startBuild:(id)sender;
- (void)startClean:(id)sender;
- (void)startInstall:(id)sender;
- (BOOL)stopMake:(id)sender;
- (void)cleanupAfterMake;

- (BOOL)prebuildCheck;
- (void)build:(id)sender;
//- (void)buildDidTerminate;

- (void)logStdOut:(NSNotification *)aNotif;
- (void)logErrOut:(NSNotification *)aNotif;

- (void)updateErrorsCountField;

@end

@interface PCProjectBuilder (BuildLogging)

- (void)parseBuildLine:(NSString *)string;

- (void)logString:(NSString *)string error:(BOOL)yn newLine:(BOOL)newLine;
- (void)logData:(NSData *)data error:(BOOL)yn;

@end

@interface PCProjectBuilder (ErrorLogging)

- (void)logErrorString:(NSString *)string;

- (NSString *)lineTail:(NSString*)line afterString:(NSString*)string;
- (NSArray *)parseErrorLine:(NSString *)string;

@end

@interface PCProjectBuilder (Options)

@end

#endif
