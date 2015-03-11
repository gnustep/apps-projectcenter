// 
// GNUstep ProjectCenter - http://www.gnustep.org/experience/ProjectCenter.html
//
// Copyright (C) 2001-2015 Free Software Foundation
//
// Authors: Sergii Stoian
//          Riccardo Mottola
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

#import <AppKit/NSColorSpace.h>

#import "PCEditorFSCPrefs.h"

// ----------------------------------------------------------------------------
// --- PCEditorFSCPrefsFontButton created to forward changeFont: message
// --- to PCEditorFSCPrefs class
// ----------------------------------------------------------------------------

@interface PCEditorFSCPrefsFontButton : NSButton
{
}
@end
@implementation PCEditorFSCPrefsFontButton

- (void)changeFont:(id)sender
{
  [[_cell target] changeFont:sender];
}

- (BOOL)resignFirstResponder
{
  [[NSFontPanel sharedFontPanel] close];
  return YES;
}

@end

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
  currentEditorFont = nil;
  currentConsoleFixedFont = nil;

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
  [editorFontButton setTarget:self];
  [editorFontField setAllowsEditingTextAttributes:YES];

  [consoleFixedFontButton setTarget:self];
  [consoleFixedFontField setAllowsEditingTextAttributes:YES];
}

// ----------------------------------------------------------------------------
// --- Utility methods
// ----------------------------------------------------------------------------

- (void)pickFont:(NSFont *)currentFont
{
  NSFontManager *fontManager = [NSFontManager sharedFontManager];

  [fontManager setSelectedFont:currentEditorFont isMultiple:NO];
  [fontManager orderFrontFontPanel:self];
}

- (void)changeFont:(id)sender
{
  NSButton *button = (NSButton *)[[editorFSCView window] firstResponder];
  int      buttonTag;
  NSFont   *font;
  NSString *fontString;

  if (![button isKindOfClass:[NSButton class]])
    {
      return;
    }

  font = [sender convertFont:currentEditorFont];
  fontString = [NSString stringWithFormat:@"%@ %0.1f", 
	     [font fontName], [font pointSize]];

  buttonTag = [button tag];
  if (buttonTag == 0) // Editor font button
    {
      [editorFontField setStringValue:fontString];
      [editorFontField setFont:font];
      [prefs setString:[font fontName] forKey:EditorTextFont notify:YES];
      [prefs setFloat:[font pointSize] 
	       forKey:EditorTextFontSize
	       notify:YES];
    }
  else if (buttonTag == 1) // Console Fixed Font button
    {
      [consoleFixedFontField setStringValue:fontString];
      [consoleFixedFontField setFont:font];
      [prefs setString:[font fontName] forKey:ConsoleFixedFont notify:YES];
      [prefs setFloat:[font pointSize] 
	       forKey:ConsoleFixedFontSize
	       notify:YES];
    }
}

- (NSColor *)colorFromString:(NSString *)colorString
{
  NSArray  *colorComponents;
  NSString *colorSpaceName;
  NSColor  *color;

  colorComponents = [colorString componentsSeparatedByString:@" "];
  colorSpaceName = [colorComponents objectAtIndex:0];

  if ([colorSpaceName isEqualToString:@"White"]) // Treat as WhiteColorSpace
    {
      color = [NSColor 
	colorWithCalibratedWhite:[[colorComponents objectAtIndex:1] floatValue]
       			   alpha:1.0];
    }
  else // Treat as RGBColorSpace
    {
      color = [NSColor 
	colorWithCalibratedRed:[[colorComponents objectAtIndex:1] floatValue]
			 green:[[colorComponents objectAtIndex:2] floatValue]
			  blue:[[colorComponents objectAtIndex:3] floatValue]
			 alpha:1.0];
    }

  return color;
}

// ----------------------------------------------------------------------------
// --- Protocol
// ----------------------------------------------------------------------------
- (void)readPreferences
{
  NSString *fontName;
  float    fontSize;
  NSFont   *editorFont = [NSFont userFixedPitchFontOfSize:0.0];
  NSFont   *consoleFixedFont = [NSFont userFixedPitchFontOfSize:0.0];
  NSString *val;

  // Editor font
  fontName = [prefs stringForKey:EditorTextFont 
		    defaultValue:[editorFont fontName]];
  fontSize = [prefs floatForKey:EditorTextFontSize 
		   defaultValue:[editorFont pointSize]];
  currentEditorFont = [NSFont fontWithName:fontName size:fontSize];
  [editorFontField setStringValue:[NSString stringWithFormat:@"%@ %0.1f", 
    [currentEditorFont fontName], [currentEditorFont pointSize]]];
  [editorFontField setFont:currentEditorFont];

  // Console fixed font
  fontName = [prefs stringForKey:ConsoleFixedFont 
		    defaultValue:[consoleFixedFont fontName]];
  fontSize = [prefs floatForKey:ConsoleFixedFontSize
		   defaultValue:[consoleFixedFont pointSize]];
  consoleFixedFont = [NSFont fontWithName:fontName size:fontSize];
  [consoleFixedFontField setStringValue:[NSString stringWithFormat:@"%@ %0.1f", 
    [currentConsoleFixedFont fontName], [currentConsoleFixedFont pointSize]]];
  [consoleFixedFontField setFont:currentConsoleFixedFont];

  // Editor window size
  val = [prefs stringForKey:EditorLines defaultValue:@"30"];
  [editorLinesField setStringValue:val];
  val = [prefs stringForKey:EditorColumns defaultValue:@"80"];
  [editorColumnsField setStringValue:val];

  // Colors
  val = [prefs stringForKey:EditorForegroundColor defaultValue:@"White 0.0"];
  currentForegroundColor = [self colorFromString:val];
  [foregroundColorWell setColor:currentForegroundColor];

  val = [prefs stringForKey:EditorBackgroundColor defaultValue:@"White 1.0"];
  currentBackgroundColor = [self colorFromString:val];
  [backgroundColorWell setColor:currentBackgroundColor];

  val = [prefs stringForKey:EditorSelectionColor defaultValue:@"White 0.66"];
  currentSelectionColor = [self colorFromString:val];
  [selectionColorWell setColor:currentSelectionColor];
}

- (NSView *)view
{
  return editorFSCView;
}

// ----------------------------------------------------------------------------
// --- Actions
// ----------------------------------------------------------------------------

- (void)setEditorTextFont:(id)sender
{
  [[editorFSCView window] makeFirstResponder:editorFontButton];
  [self pickFont:currentEditorFont];
}

- (void)setConsoleFixedFont:(id)sender
{
  [[editorFSCView window] makeFirstResponder:consoleFixedFontButton];
  [self pickFont:currentConsoleFixedFont];
}

- (void)setEditorSize:(id)sender
{
  NSString *val;
  NSString *key;
  
  if (sender == editorLinesField)
    {
      key = EditorLines;
      val = [editorLinesField stringValue];
    }
  else // editorColumnsField
    {
      key = EditorColumns;
      val = [editorColumnsField stringValue];
    }

  [prefs setString:val forKey:key notify:YES];
}

- (void)setEditorColor:(id)sender
{
  NSColor  *color;
  NSColor  *currentColor;
  NSString *colorString;
  NSString *key;
  NSString *colorSpaceName;

  if (sender == foregroundColorWell)
    {
      NSLog(@"foregroundColorWell");
      color = [foregroundColorWell color];
      currentColor = currentForegroundColor;
      key = EditorForegroundColor;
    }
  else if (sender == backgroundColorWell)
    {
      NSLog(@"backgroundColorWell");
      color = [backgroundColorWell color];
      currentColor = currentBackgroundColor;
      key = EditorBackgroundColor;
    }
  else // selectionColorWell
    {
      NSLog(@"selectionColorWell");
      color = [selectionColorWell color];
      currentColor = currentSelectionColor;
      key = EditorSelectionColor;
    }

  colorSpaceName =  [color colorSpaceName];
  NSLog(@"Color's colorspace name: '%@'", colorSpaceName);
  if ([colorSpaceName isEqualToString:@"NSCalibratedRGBColorSpace"])
    {
/*      [sender setColor:currentColor];
      NSRunAlertPanel(@"Set Color", 
		      @"Please, use RGB color.\n"
		      @"Color in color well left unchanged",
		      @"Close", nil, nil);*/
      colorString = [NSString stringWithFormat:@"RGB %0.1f %0.1f %0.1f",
		  [color redComponent], 
		  [color greenComponent],
		  [color blueComponent]];
    }
  else if ([colorSpaceName isEqualToString:@"NSCalibratedWhiteColorSpace"])
    {
      colorString = [NSString stringWithFormat:@"White %0.1f", 
		  [color whiteComponent]];
    }
  else
    {
      return;
    }

  currentColor = color;

  NSLog(@"Selected color: '%@'", colorString);

  [prefs setString:colorString forKey:key notify:YES];
}

@end

