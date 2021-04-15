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
//
/* All rights reserved */

#import <AppKit/AppKit.h>
#import <Protocols/Preferences.h>

#define IndentWhenTyping        @"IndentWhenTyping"
#define IndentForOpenCurly      @"IndentForOpenCurly"
#define IndentForCloseCurly     @"IndentForCloseCurly"
#define IndentForSemicolon      @"IndentForSemicolon"
#define IndentForColon          @"IndentForColon"
#define IndentForHash           @"IndentForHash"
#define IndentForReturn         @"IndentForReturn"
#define IndentForSoloOpenCurly  @"IndentForSoloOpenCurly"
#define IndentNumberOfSpaces    @"IndentNumberOfSpaces"
#define IndentUsingSpaces       @"IndentUsingSpaces"
#define IndentWidth             @"IndentWidth"
#define TabWidth                @"TabWidth"

@interface PCIndentationPrefs : NSObject <PCPrefsSection, NSTextFieldDelegate>
{
  id <PCPreferences> prefs;

  IBOutlet NSBox *_view;
  
  id _indentWhenTyping;
  id _indentForOpenCurly;
  id _indentForCloseCurly;
  id _indentForSemicolon;
  id _indentForColon;
  id _indentForHash;
  id _indentForReturn;
  id _indentForSoloOpenCurly;
  id _indentNumberOfSpaces;

  id _indentUsingSpaces;
  id _indentWidth;
  id _tabWidth;
}

// Indentation
- (void) setIndentWhenTyping: (id)sender;
- (void) setIndentForOpenCurlyBrace: (id)sender;
- (void) setIndentForCloseCurlyBrace: (id)sender;
- (void) setIndentForSemicolon: (id)sender;
- (void) setIndentForColon: (id)sender;
- (void) setIndentForHash: (id)sender;
- (void) setIndentForReturn: (id)sender;
- (void) setIndentForSoloOpenBrace: (id)sender;
- (void) setIndentNumberOfSpaces: (id)sender;

// Tabs/Spaces
- (void) setIndentUsingSpaces: (id)sender;
- (void) setIndentWidth: (id)sender;
- (void) setTabWidth: (id)sender;

@end
