// 
// GNUstep ProjectCenter - http://www.gnustep.org/experience/ProjectCenter.html
//
// Copyright (C) 2001-2009 Free Software Foundation
//
// Authors: Sergii Stoian
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

#import <AppKit/AppKit.h>
#import <Protocols/Preferences.h>

#define EditorPlainTextFont     @"EditorPlainTextFont"
#define EditorPlainTextFontSize @"EditorPlainTextFontSize"
#define EditorRichTextFont      @"EditorRichTextFont"
#define EditorRichTextFontSize  @"EditorRichTextFontSize"

#define EditorLines             @"EditorLines"
#define EditorColumns           @"EditorColumns"

#define EditorForegroundColor   @"EditorForegroundColor"
#define EditorBackgroundColor   @"EditorBackgroundColor"
#define EditorSelectionColor    @"EditorSelectionColor"


@interface PCEditorFSCPrefs : NSObject <PCPrefsSection>
{
  id <PCPreferences>   prefs;

  IBOutlet NSBox       *editorFSCView;

  IBOutlet NSButton    *plainTextFontButton;
  IBOutlet NSTextField *plainTextFontField;
  IBOutlet NSButton    *richTextFontButton;
  IBOutlet NSTextField *richTextFontField;

  IBOutlet NSTextField *editorLinesField;
  IBOutlet NSTextField *editorColumnsField;

  IBOutlet NSColorWell *foregroundColorWell;
  IBOutlet NSColorWell *backgroundColorWell;
  IBOutlet NSColorWell *selectionColorWell;

  NSFont               *currentPlainFont;
  NSFont               *currentRichFont;
  NSColor              *currentBackgroundColor;
  NSColor              *currentForegroundColor;
  NSColor              *currentSelectionColor;
}

- (void)setEditorPlainTextFont:(id)sender;
- (void)setEditorRichTextFont:(id)sender;

- (void)setEditorSize:(id)sender;
- (void)setEditorColor:(id)sender;

@end

