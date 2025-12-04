/*
   GNUstep ProjectCenter - http://www.gnustep.org/experience/ProjectCenter.html

   Copyright (C) 2000-2025 Free Software Foundation

   Authors: Philippe C.D. Robert
            Sergii Stoian
            Riccardo Mottola

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
   Software Foundation, Inc., 31 Milk Street #960789 Boston, MA 02196 USA.
*/

#import <AppKit/AppKit.h>

@class PCProject;

typedef enum _MakeParallelism {
    Nis1 = 0,
    NisCPUminus1,
    NisCPU,
    NisCPUplus1,
    NisCPUdiv2,
    NisCPUdiv4
} MakeParallelism;


@interface PCProjectBuilderOptions : NSObject
{
  PCProject     *project;
  id            delegate;           // Usually PCProjectBuilder

  NSPanel       *optionsPanel;
  NSPopUpButton *targetPopup;
  NSPopUpButton *parallelismPopup;  // number of jobs
  NSTextField   *buildArgsField;
  NSButton      *verboseButton;     // messages=yes
  NSButton      *debugButton;       // debug=no
  NSButton      *stripButton;       // strip=yes
  NSButton      *sharedLibsButton;  // shared=no
}

- (id)initWithProject:(PCProject *)aProject delegate:(id)aDelegate;
- (void)show:(NSRect)builderRect;
- (NSString *)buildTarget;

- (void)loadProjectProperties:(NSNotification *)aNotif;

@end

@interface PCProjectBuilderOptions (Delegate)

- (void)targetDidSet:(NSString *)aTarget;
- (void)parallelismDidSet:(NSInteger)aTarget;

@end

