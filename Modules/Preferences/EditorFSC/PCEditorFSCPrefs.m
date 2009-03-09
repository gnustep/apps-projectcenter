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
// modify it under the terms of the GNU General Public License as published 
// by the Free Software Foundation; either version 2 of the License, or 
// (at your option) any later version.
//
// This application is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
// Library General Public License for more details.
//
// You should have received a copy of the GNU General Public
// License along with this library; if not, write to the Free Software 
// Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111 USA.

#import <ProjectCenter/PCDefines.h>
#import <ProjectCenter/PCFileManager.h>

#import "PCEditorFSCPrefs.h"

@implementation PCEditorFSCPrefs

// ----------------------------------------------------------------------------
// --- Init and free
// ----------------------------------------------------------------------------

- (id)initWithPrefController:(id <PCPreferences>)aPrefs
{
  self = [super init];

  if ([NSBundle loadNibNamed:@"EditorFSCPrefs" owner:self] == NO)
    {
      NSLog(@"PCEditorFSCPrefs: error loading NIB file!");
    }

  prefs = aPrefs;

  RETAIN(editorFSCView);

  return self;
}

- (void)dealloc
{
#ifdef DEBUG
  NSLog (@"PCEditorFSCPrefs: dealloc");
#endif

  [[NSNotificationCenter defaultCenter] removeObserver:self];

  RELEASE(editorFSCView);

  [super dealloc];
}

- (void)awakeFromNib
{
  [plainTextFontButton setRefusesFirstResponder:YES];
  [plainTextFontField setDelegate:self];
  [richTextFontButton setRefusesFirstResponder:YES];
}

// Protocol
- (void)setDefaults
{
  [prefs setObject:@"30" forKey:EditorLines notify:NO];
  [prefs setObject:@"80" forKey:EditorColumns notify:NO];
}

- (void)readPreferences
{
  NSString *val;
  NSNumber *fval;
  NSFont   *font;

  // Plain text font
  font = [NSFont userFixedPitchFontOfSize:0.0];
  if (!(val = [prefs objectForKey:EditorPlainTextFont]))
    {
      val = [font fontName];
    }
  if (!(val = [prefs objectForKey:EditorPlainTextFontSize]))
    {
      fval = [NSNumber numberWithFloat:[font pointSize]];
    }
  [plainTextFontField setStringValue:
	  [NSString stringWithFormat:@"%@ %0.1f", val, [fval floatValue]]];

/*  // Rich text font
  font = [NSFont systemFontOfSize:0.0];
  if (!(val = [prefs objectForKey:EditorRichTextFont]))
    {
      val = [font fontName];
    }
  if (!(fval = [prefs objectForKey:EditorRichTextFontSize]))
    {
      fval = [font pointSize];
    }
  [richTextFontField setStringValue:
	 [NSString stringWithFormat:@"%@ %0.1f", val, fval];*/

  // Editor window size
  if (!(val = [prefs objectForKey:EditorLines]))
    val = @"30";
  [editorLinesField setStringValue:val];
  if (!(val = [prefs objectForKey:EditorColumns]))
    val = @"80";
  [editorColumnsField setStringValue:val];
}

- (NSView *)view
{
  return editorFSCView;
}

// Actions
- (void)setEditorPlainTextFont:(id)sender
{
  NSFontManager *fm = [NSFontManager sharedFontManager];
  NSFont        *currentFont;

  [[editorFSCView window] makeFirstResponder:plainTextFontField];
  currentFont = [NSFont 
    fontWithName:[prefs objectForKey:EditorPlainTextFont] 
	    size:[[prefs objectForKey:EditorPlainTextFontSize] floatValue]];

  [fm setSelectedFont:currentFont isMultiple:NO];
  [fm orderFrontFontPanel:self];
}

- (void)setEditorRichTextFont:(id)sender
{
}

- (void)setEditorSize:(id)sender
{
  NSString *val = nil;
  NSString *key = nil;
  
  if (sender == editorLinesField)
    {
      key = EditorLines;
      val = [editorLinesField stringValue];
    }
  else if (sender == editorColumnsField)
    {
      key = EditorColumns;
      val = [editorColumnsField stringValue];
    }

  [prefs setObject:val forKey:key notify:YES];
}

- (void)setEditorColor:(id)sender
{
}

-(void)changeFont:(id)sender
{
  NSLog(@"%@: Font: '%@ %0.1f'", [sender className],
	[[NSFont userFixedPitchFontOfSize:0.0] fontName], 
	[[NSFont userFixedPitchFontOfSize:0.0] pointSize]);

}

@end

