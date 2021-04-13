// 
// GNUstep ProjectCenter - http://www.gnustep.org/experience/ProjectCenter.html
//
// Copyright (C) 2021 Free Software Foundation
//
// Authors: Gregory Casamento
//
// Description: 
//
// This file is part of GNUstep.
//
// This application is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public
// License as published by the Free Software Foundation; either
// version 2 of the License, or (at your option) any later version.
//
// This application is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
// Library General Public License for more details.
//
// You should have received a copy of the GNU General Public
// License along with this library; if not, write to the Free
// Software Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111 USA.
/* All rights reserved */

#import <AppKit/AppKit.h>
#import "PCIndentationPrefs.h"

@implementation PCIndentationPrefs

- (id)initWithPrefController:(id <PCPreferences>)aPrefs
{
  self = [super init];

  if ([NSBundle loadNibNamed:@"IndentationPrefs" owner:self] == NO)
    {
      NSLog(@"PCIndentationPrefs: error loading NIB file!");
    }

  prefs = aPrefs;
  RETAIN(_view);

  return self;
}

- (void) readPreferences
{
}

- (void) setIndentWhenTyping: (id)sender
{
  /* insert your code here */
}


- (void) setIndentForOpenCurlyBrace: (id)sender
{
  /* insert your code here */
}


- (void) setIndentForCloseCurlyBrace: (id)sender
{
  /* insert your code here */
}


- (void) setIndentForSemicolon: (id)sender
{
  /* insert your code here */
}


- (void) setIndentForColon: (id)sender
{
  /* insert your code here */
}


- (void) setIndentForHash: (id)sender
{
  /* insert your code here */
}


- (void) setIndentForReturn: (id)sender
{
  /* insert your code here */
}


- (void) setIndentForSoloOpenBrace: (id)sender
{
  /* insert your code here */
}

- (NSView *) view
{
  return _view;
}
@end
