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

#import "PCInterfacePrefs.h"

@implementation PCInterfacePrefs

// ----------------------------------------------------------------------------
// --- Init and free
// ----------------------------------------------------------------------------

- (id)initWithPrefController:(id <PCPreferences>)aPrefs
{
  self = [super init];

  if ([NSBundle loadNibNamed:@"InterfacePrefs" owner:self] == NO)
    {
      NSLog(@"PCInterfacePrefs: error loading NIB file!");
    }

  prefs = aPrefs;

  RETAIN(interfaceView);

  return self;
}

- (void)dealloc
{
#ifdef DEBUG
  NSLog (@"PCInterfacePrefs: dealloc");
#endif

  [[NSNotificationCenter defaultCenter] removeObserver:self];

  RELEASE(interfaceView);

  [super dealloc];
}

- (void)awakeFromNib
{
  [separateBuilder setRefusesFirstResponder:YES];
  [separateLauncher setRefusesFirstResponder:YES];
  [separateEditor setRefusesFirstResponder:YES];
  [separateLoadedFiles setRefusesFirstResponder:YES];
}

- (void)setEditorSizeEnabled:(BOOL)yn
{
  if (yn)
    {
      [editorLinesField setEnabled:YES];
      [editorLinesField setTextColor:[NSColor blackColor]];
      [editorLinesField setEditable:YES];
      [editorColumnsField setEnabled:YES];
      [editorColumnsField setTextColor:[NSColor blackColor]];
      [editorColumnsField setEditable:YES];
    }
  else
    {
      [editorLinesField setEnabled:NO];
      [editorLinesField setTextColor:[NSColor darkGrayColor]];
      [editorLinesField setEditable:NO];
      [editorColumnsField setEnabled:NO];
      [editorColumnsField setTextColor:[NSColor darkGrayColor]];
      [editorColumnsField setEditable:NO];
    }
}

// Protocol
- (void)setDefaults
{
  [prefs setObject:@"YES" forKey:SeparateBuilder notify:NO];
  [prefs setObject:@"YES" forKey:SeparateLauncher notify:NO];
  [prefs setObject:@"NO" forKey:SeparateEditor notify:NO];
  [prefs setObject:@"YES" forKey:SeparateLoadedFiles notify:NO];
  
  [prefs setObject:@"30" forKey:EditorLines notify:NO];
  [prefs setObject:@"80" forKey:EditorColumns notify:NO];
}

- (void)readPreferences
{
  NSString *val;
  int      state;

  val = [prefs objectForKey:SeparateBuilder];
  state = [val isEqualToString:@"YES"] ? NSOnState : NSOffState;
  [separateBuilder setState:state];

  val = [prefs objectForKey:SeparateLauncher];
  state = [val isEqualToString:@"YES"] ? NSOnState : NSOffState;
  [separateLauncher setState:state];

  val = [prefs objectForKey:SeparateEditor];
  state = [val isEqualToString:@"YES"] ? NSOnState : NSOffState;
  [separateEditor setState:state];

  val = [prefs objectForKey:SeparateLoadedFiles];
  state = [val isEqualToString:@"YES"] ? NSOnState : NSOffState;
  [separateLoadedFiles setState:state];

  if (!(val = [prefs objectForKey:EditorLines]))
    val = @"30";
  [editorLinesField setStringValue:val];
  if (!(val = [prefs objectForKey:EditorColumns]))
    val = @"80";
  [editorColumnsField setStringValue:val];
/*  if ([separateEditor state] == NSOffState 
      || ![[editorField stringValue] isEqualToString:@"ProjectCenter"])
    {
      [self setEditorSizeEnabled:NO];
    }*/
}

- (NSView *)view
{
  return interfaceView;
}

// Actions
- (void)setDisplayPanels:(id)sender
{
  NSString *key;
  NSString *state;

  NSLog(@"PCInterfacePrefs: setDisplayPanels");

  if (sender == separateBuilder)
    {
      NSLog(@"PCInterfacePrefs: separateBuilder");
      key = [NSString stringWithString:SeparateBuilder];
    }
  else if (sender == separateLauncher)
    {
      NSLog(@"PCInterfacePrefs: separateLauncher");
      key = [NSString stringWithString:SeparateLauncher];
    }
  else if (sender == separateEditor)
    {
      NSLog(@"PCInterfacePrefs: separateEditor");
      key = [NSString stringWithString:SeparateEditor];
    }
  else if (sender == separateLoadedFiles)
    {
      NSLog(@"PCInterfacePrefs: separateLoadedFiles");
      key = [NSString stringWithString:SeparateLoadedFiles];
    }

  if (sender == separateEditor)
    {
      if ([sender state] == NSOffState)
	{
	  [self setEditorSizeEnabled:NO];
	}
      else
	{
	  [self setEditorSizeEnabled:YES];
	}
      [sender becomeFirstResponder];
    }

  state = ([sender state] == NSOffState) ? @"NO" : @"YES";
  [prefs setObject:state forKey:key notify:YES];
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

@end

