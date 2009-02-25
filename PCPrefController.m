/*
   GNUstep ProjectCenter - http://www.gnustep.org/experience/ProjectCenter.html

   Copyright (C) 2001-2008 Free Software Foundation

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

#import <ProjectCenter/PCDefines.h>
#import <ProjectCenter/PCLogController.h>
#import <ProjectCenter/PCBundleManager.h>

#import "PCPrefController.h"
#import <Protocols/Preferences.h>

// TODO: rewrite it as PCPreferences, use +sharedPreferences instead of
// [NSUserDefaults standardUserDefaults] in every part of ProjectCenter

@implementation PCPrefController

// ===========================================================================
// ==== Class methods
// ===========================================================================

static PCPrefController *_prefCtrllr = nil;
  
+ (PCPrefController *)sharedPCPreferences
{
  if (!_prefCtrllr)
    {
      _prefCtrllr = [[PCPrefController alloc] init];
    }
  
  return _prefCtrllr;
}

//
- (id)init
{
  NSDictionary *prefs = nil;

  if (!(self = [super init]))
    {
      return nil;
    }
    
  // The prefs from the defaults

  userDefaults = [NSUserDefaults standardUserDefaults];
  RETAIN(userDefaults);

  preferencesDict = [[NSMutableDictionary alloc] 
    initWithDictionary:[userDefaults dictionaryRepresentation]];

  [userDefaults setPersistentDomain:preferencesDict forName:@"ProjectCenter"];

  if ([preferencesDict objectForKey:@"Version"] == nil)
    {
      [self setDefaultValues];
    }

  return self;
}

- (void)dealloc
{
#ifdef DEVELOPMENT
  NSLog(@"PCPrefController: dealloc");
#endif
  
  RELEASE(preferencesDict);
  
  RELEASE(panel);

  RELEASE(savingView);
  RELEASE(keyBindingsView);
  RELEASE(miscView);

  [[NSUserDefaults standardUserDefaults] synchronize];

  [super dealloc];
}

- (void)setDefaultValues
{
  NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];

  PCLogInfo(self, @"setDefaultValues");

  // Clean preferences
  [preferencesDict removeAllObjects];

  [preferencesDict setObject:@"0.4" forKey:@"Version"];
  
  // Saving
  [preferencesDict setObject:@"YES" forKey:SaveOnQuit];
  [preferencesDict setObject:@"YES" forKey:KeepBackup];
  [preferencesDict setObject:@"120" forKey:AutoSavePeriod];

  // Key Bindings
  [preferencesDict setObject:@"Tab" forKey:TabBehaviour];

  // Miscellaneous
  [preferencesDict setObject:@"YES" forKey:PromptOnQuit];
  [preferencesDict setObject:@"YES" forKey:DeleteCacheWhenQuitting];
  [preferencesDict setObject:@"YES" forKey:FullPathInFilePanels];
  [preferencesDict setObject:@"/usr/bin/gdb" forKey:Debugger];
  [preferencesDict setObject:@"ProjectCenter" forKey:Editor];

  // Interface
  [preferencesDict setObject:@"YES" forKey:SeparateBuilder];
  [preferencesDict setObject:@"YES" forKey:SeparateLauncher];
  [preferencesDict setObject:@"NO" forKey:SeparateEditor];
  [preferencesDict setObject:@"YES" forKey:SeparateLoadedFiles];
  
  [preferencesDict setObject:@"30" forKey:EditorLines];
  [preferencesDict setObject:@"80" forKey:EditorColumns];

  [preferencesDict setObject:@"YES" forKey:RememberWindows];
  [preferencesDict setObject:@"NO" forKey:DisplayLog];

  [ud setPersistentDomain:preferencesDict forName:@"ProjectCenter"];
  [ud synchronize];
}

- (void)loadPreferences
{
  NSString     *val;
  NSString     *defValue = @"";

  // Fill in the defaults

  // Saving
  [saveOnQuit setState:
    ([[preferencesDict objectForKey: SaveOnQuit] 
     isEqualToString: @"YES"]) ? NSOnState : NSOffState];
     
  [keepBackup setState:
    ([[preferencesDict objectForKey: KeepBackup] 
     isEqualToString: @"YES"]) ? NSOnState : NSOffState];

  defValue = @"120";
  [autosaveField setStringValue:
    (val = [preferencesDict objectForKey: AutoSavePeriod]) ? val : defValue];
  [autosaveSlider setFloatValue:[[autosaveField stringValue] floatValue]];

  // Key Bindings
  val = [preferencesDict objectForKey:TabBehaviour];
  [tabMatrix deselectAllCells];
  if ([val isEqualToString:@"Tab"])
    {
      [tabMatrix selectCellAtRow:0 column:0];
    }
  else if ([val isEqualToString:@"IndentAlways"])
    {
      [tabMatrix selectCellAtRow:1 column:0];
    }
  else if ([val isEqualToString:@"IndentAtBeginning"])
    {
      [tabMatrix selectCellAtRow:2 column:0];
    }
  else if ([val isEqualToString:@"Spaces"])
    {
      [tabMatrix selectCellAtRow:3 column:0];
    }

  // Miscellaneous
  [promptWhenQuit setState:
    ([[preferencesDict objectForKey: PromptOnQuit] 
     isEqualToString:@"YES"]) ? NSOnState : NSOffState];
  [deleteCache setState:
    ([[preferencesDict objectForKey: DeleteCacheWhenQuitting] 
     isEqualToString:@"YES"]) ? NSOnState : NSOffState];
  [fullPathInFilePanels setState:
    ([[preferencesDict objectForKey: FullPathInFilePanels] 
     isEqualToString:@"YES"]) ? NSOnState : NSOffState];

  [debuggerField setStringValue:
    (val = [preferencesDict objectForKey: Debugger]) ? val : PCDefaultDebugger];
  [editorField setStringValue:
    (val = [preferencesDict objectForKey: Editor]) ? val : @"ProjectCenter"];
 
  // Interface
  [separateBuilder setState:
    ([[preferencesDict objectForKey: SeparateBuilder] 
     isEqualToString:@"YES"]) ? NSOnState : NSOffState];
  [separateLauncher setState:
    ([[preferencesDict objectForKey: SeparateLauncher] 
     isEqualToString:@"YES"]) ? NSOnState : NSOffState];
  [separateEditor setState:
    ([[preferencesDict objectForKey: SeparateEditor] 
     isEqualToString:@"YES"]) ? NSOnState : NSOffState];
  [separateLoadedFiles setState:
    ([[preferencesDict objectForKey: SeparateLoadedFiles] 
     isEqualToString:@"YES"]) ? NSOnState : NSOffState];
     
  [editorLinesField setStringValue:
    (val = [preferencesDict objectForKey: EditorLines]) ? val : @"30"];
  [editorColumnsField setStringValue:
    (val = [preferencesDict objectForKey: EditorColumns]) ? val : @"80"];
  if ([separateEditor state] == NSOffState 
      || ![[editorField stringValue] isEqualToString:@"ProjectCenter"])
    {
      [self setEditorSizeEnabled:NO];
    }
     
  [rememberWindows setState:
    ([[preferencesDict objectForKey: RememberWindows] 
     isEqualToString:@"YES"]) ? NSOnState : NSOffState];
  [displayLog setState:
    ([[preferencesDict objectForKey:DisplayLog] 
     isEqualToString:@"YES"]) ? NSOnState : NSOffState];
}

- (void)awakeFromNib
{
  NSArray  *tabMatrixCells;
  unsigned i;
  
  [saveOnQuit setRefusesFirstResponder:YES];
  [keepBackup setRefusesFirstResponder:YES];

  tabMatrixCells = [tabMatrix cells];

  for (i = 0; i < [tabMatrixCells count]; i++)
    {
      [[tabMatrixCells objectAtIndex:i] setRefusesFirstResponder:YES];
    }

  [promptWhenQuit setRefusesFirstResponder:YES];
  [deleteCache setRefusesFirstResponder:YES];
  [fullPathInFilePanels setRefusesFirstResponder:YES];

  [separateBuilder setRefusesFirstResponder:YES];
  [separateLauncher setRefusesFirstResponder:YES];
  [separateEditor setRefusesFirstResponder:YES];
  [separateLoadedFiles setRefusesFirstResponder:YES];

  [rememberWindows setRefusesFirstResponder:YES];
  [displayLog setRefusesFirstResponder:YES];
}

// Accessory
- (NSDictionary *)preferencesDict
{
  return [userDefaults dictionaryRepresentation];
}

- (id)objectForKey:(NSString *)key
{
  return [userDefaults objectForKey:key];
}

- (void)setObject:(id)anObject forKey:(NSString *)aKey
{
  [userDefaults setObject:anObject forKey:aKey];
  [userDefaults synchronize];

  [[NSNotificationCenter defaultCenter] 
    postNotificationName:PCPreferencesDidChangeNotification
                  object:self];
}

- (NSString *)selectFileWithTypes:(NSArray *)types
{
  NSUserDefaults   *def = [NSUserDefaults standardUserDefaults];
  NSString 	   *file = nil;
  NSOpenPanel	   *openPanel;
  int		    retval;

  openPanel = [NSOpenPanel openPanel];
  [openPanel setAllowsMultipleSelection:NO];
  [openPanel setCanChooseDirectories:YES];
  [openPanel setCanChooseFiles:YES];

  retval = [openPanel 
    runModalForDirectory:[def objectForKey:@"LastOpenDirectory"]
                    file:nil
		   types:types];

  if (retval == NSOKButton) 
    {
      [def setObject:[openPanel directory] forKey:@"LastOpenDirectory"];
      file = [[openPanel filenames] objectAtIndex:0];

    }

  return file;
}

- (void)loadPrefsSections
{
  PCBundleManager  *bundleManager = [[PCBundleManager alloc] init];
  NSDictionary     *bundlesInfo;
  NSEnumerator     *enumerator;
  NSString         *bundlePath;
  NSString         *sectionName;
  id<PCPrefsSection> section;

  sectionsDict = [[NSMutableDictionary alloc] init];

  bundlesInfo = [bundleManager infoForBundlesType:@"preferences"];
  enumerator = [[bundlesInfo allKeys] objectEnumerator];
  while ((bundlePath = [enumerator nextObject]))
    {
      sectionName = [[bundlesInfo objectForKey:bundlePath] 
				  objectForKey:@"Name"];
      section = [bundleManager 
	objectForBundleWithName:sectionName
			   type:@"preferences"
		       protocol:@protocol(PCPrefsSection)];
      [section setPrefController:self];
      [sectionsDict setObject:section forKey:sectionName];
    }
}

- (void)showPanel:(id)sender
{
  if (panel == nil 
      && [NSBundle loadNibNamed:@"Preferences" owner:self] == NO)
    {
      PCLogError(self, @"error loading NIB file!");
      return;
    }

  [panel setFrameAutosaveName:@"Preferences"];
  if (![panel setFrameUsingName: @"Preferences"])
    {
      [panel center];
    }

  [self loadPrefsSections];

  // The popup and selected view
  [popupButton removeAllItems];
  [popupButton addItemsWithTitles:[sectionsDict allKeys]];
  [popupButton selectItemAtIndex:0];
  [self popupChanged:popupButton];

  [panel makeKeyAndOrderFront:self];
}

//
- (void)popupChanged:(id)sender
{
  id<PCPrefsSection> section;
  NSView             *view;

  section = [sectionsDict objectForKey:[sender titleOfSelectedItem]];
  view = [section view];

  [sectionsView setContentView:view];
//  [sectionsView display];
}

// Saving
- (void)setSaveOnQuit:(id)sender
{
  NSUserDefaults *def = [NSUserDefaults standardUserDefaults];

  if (saveOnQuit == nil)
    { // HACK!!!
      saveOnQuit = sender;
      return;
    }

  switch ([sender state])
    {
    case 0:
      [def setObject:@"NO" forKey:SaveOnQuit];
      break;
    case 1:
      [def setObject:@"YES" forKey:SaveOnQuit];
      break;
    }
  [def synchronize];

  [preferencesDict setObject:[def objectForKey:SaveOnQuit] 
                      forKey:SaveOnQuit];
}

- (void)setKeepBackup:(id)sender
{
  NSUserDefaults *def = [NSUserDefaults standardUserDefaults];

  if (keepBackup == nil)
    { // HACK!!!
      keepBackup = sender;
      return;
    }
    
  switch ([[sender selectedCell] state])
    {
    case 0:
      [def setObject:@"NO" forKey:KeepBackup];
      break;
    case 1:
      [def setObject:@"YES" forKey:KeepBackup];
      break;
    }
  [def synchronize];

  [preferencesDict setObject:[def objectForKey:KeepBackup] 
                      forKey:KeepBackup];
}

- (void)setSavePeriod:(id)sender
{
  NSString *periodString = nil;
  
  if (sender == autosaveSlider)
    {
      [autosaveField setIntValue:[sender intValue]];
    }
  else if (sender == autosaveField)
    {
      if ([autosaveField floatValue] < [autosaveSlider minValue])
	{
	  [autosaveField setFloatValue:[autosaveSlider minValue]];
	}
      else if ([autosaveField floatValue] > [autosaveSlider maxValue])
	{
	  [autosaveField setFloatValue:[autosaveSlider maxValue]];
	}
      [autosaveSlider setFloatValue:[autosaveField floatValue]];
    }

  periodString = [autosaveField stringValue];

  [[NSUserDefaults standardUserDefaults] setObject:periodString 
                                            forKey:AutoSavePeriod];
  [preferencesDict setObject:periodString forKey:AutoSavePeriod];

  [[NSNotificationCenter defaultCenter] 
    postNotificationName:PCSavePeriodDidChangeNotification
                  object:periodString];
}

// Key bindings
- (void)setTabBehaviour:(id)sender
{
  id       cell = [sender selectedCell];
  NSString *tabBehaviour = nil;

  PCLogInfo(self, @"setTabBehaviour: %@", [cell title]);

  if ([[cell title] isEqualToString:@"Insert Tab"])
    {
      tabBehaviour = [NSString stringWithString:@"Tab"];
    }
  else if ([[cell title] isEqualToString:@"Indent only at beginning of line"])
    {
      tabBehaviour = [NSString stringWithString:@"IndentAtBeginning"];
    }
  else if ([[cell title] isEqualToString:@"Indent always"])
    {
      tabBehaviour = [NSString stringWithString:@"IndentAlways"];
    }
  else if ([[cell title] isEqualToString:@"Insert spaces"])
    {
      tabBehaviour = [NSString stringWithString:@"Spaces"];
      [tabSpacesField setEnabled:YES];
      [tabSpacesField becomeFirstResponder];
    }
    
  [[NSUserDefaults standardUserDefaults] setObject:tabBehaviour
                                            forKey:TabBehaviour];
  [preferencesDict setObject:tabBehaviour forKey:TabBehaviour];
}

- (void)setTabSpaces:(id)sender
{
  if ([[tabSpacesField stringValue] isEqualToString:@""])
    {
      [tabSpacesField setStringValue:@"2"];
    }
    
  [[NSUserDefaults standardUserDefaults] 
      setObject:[tabSpacesField stringValue]
         forKey:TabSpaces];
  [preferencesDict setObject:[tabSpacesField stringValue] forKey:TabSpaces];
}

// Miscellaneous
- (void)setPromptWhenQuit:(id)sender
{
  NSUserDefaults *def = [NSUserDefaults standardUserDefaults];

  if (promptWhenQuit == nil)
    {
      promptWhenQuit = sender;
      return;
    }

  switch ([sender state])
    {
    case 0:
      [def setObject:@"NO" forKey:PromptOnQuit];
      break;
    case 1:
      [def setObject:@"YES" forKey:PromptOnQuit];
      break;
    }
  [def synchronize];

  [preferencesDict setObject:[def objectForKey:PromptOnQuit] 
                      forKey:PromptOnQuit];
}

- (void)setDeleteCache:(id)sender
{
  NSUserDefaults *def = [NSUserDefaults standardUserDefaults];

  if (deleteCache == nil)
    {
      deleteCache = sender;
      return;
    }

  switch ([sender state])
    {
    case 0:
      [def setObject:@"NO" forKey:DeleteCacheWhenQuitting];
      break;
    case 1:
      [def setObject:@"YES" forKey:DeleteCacheWhenQuitting];
      break;
    }
  [def synchronize];

  [preferencesDict setObject:[def objectForKey:DeleteCacheWhenQuitting] 
                      forKey:DeleteCacheWhenQuitting];
}

- (void)setFullPathInFilePanels:(id)sender
{
  NSUserDefaults *def = [NSUserDefaults standardUserDefaults];

  if (fullPathInFilePanels == nil)
    {
      fullPathInFilePanels = sender;
      return;
    }

  switch ([sender state])
    {
    case 0:
      [def setObject:@"NO" forKey:FullPathInFilePanels];
      break;
    case 1:
      [def setObject:@"YES" forKey:FullPathInFilePanels];
      break;
    }
  [def synchronize];

  [preferencesDict setObject:[def objectForKey:FullPathInFilePanels] 
                      forKey:FullPathInFilePanels];
}

- (void)setDebugger:(id)sender
{
  NSString *path;
  
  if (sender == debuggerButton)
    {
      path = [self selectFileWithTypes:nil];
      [debuggerField setStringValue:path];
    }
  else
    {
      path = [debuggerField stringValue];
    }   

 
  if ([path isEqualToString:@""] || !path)
    {
      [debuggerField setStringValue:PCDefaultDebugger];
      path = [debuggerField stringValue];
    }
  else if (!path || ![[NSFileManager defaultManager] fileExistsAtPath:path])
    {
      [debuggerField selectText:self];
      NSRunAlertPanel(@"Debugger not found!",
		      @"File %@ doesn't exist!",
      		      @"OK", nil, nil, path);
    }

  [[NSUserDefaults standardUserDefaults] setObject:path forKey:Debugger];
  [preferencesDict setObject:path forKey:Debugger];
}

- (void)setEditor:(id)sender
{
  NSString      *path = [editorField stringValue];
  NSString      *editorPath = nil;
  NSFileManager *fm = [NSFileManager defaultManager];
  
  [separateEditor setEnabled:YES];
  [self setEditorSizeEnabled:YES];
  
  editorPath = [[path componentsSeparatedByString:@" "] objectAtIndex:0];
  if ([path isEqualToString:@""] || !path)
    {
      [editorField setStringValue:@"ProjectCenter"];
      path = [editorField stringValue];
    }
  else if (![path isEqualToString:@"ProjectCenter"])
    {
      if (![fm fileExistsAtPath:editorPath])
	{
	  [editorField selectText:self];
	  NSRunAlertPanel(@"Editor not found!",
	    		  @"File %@ doesn't exist!",
	    		  @"Close", nil, nil, path);
	}
      else if (![fm isExecutableFileAtPath:editorPath])
	{
	  [editorField selectText:self];
	  NSRunAlertPanel(@"Editor file error!",
	    		  @"File %@ exist but is not executable!",
	    		  @"Close", nil, nil, path);
	}
      [separateEditor setEnabled:NO];
      [self setEditorSizeEnabled:NO];
    }
    
  [[NSUserDefaults standardUserDefaults] setObject:path forKey:Editor];
  [preferencesDict setObject:path forKey:Editor];
}

// Interface
- (void)setDisplayPanels:(id)sender
{
  NSUserDefaults *def = [NSUserDefaults standardUserDefaults];
  NSString       *key = nil;

  if (sender == separateBuilder)
    {
      key = [NSString stringWithString: SeparateBuilder];
    }
  else if (sender == separateLauncher)
    {
      key = [NSString stringWithString: SeparateLauncher];
    }
  else if (sender == separateEditor)
    {
      key = [NSString stringWithString: SeparateEditor];
    }
  else if (sender == separateLoadedFiles)
    {
      key = [NSString stringWithString: SeparateLoadedFiles];
    }

  switch ([sender state])
    {
    case NSOffState:
      [def setObject: @"NO" forKey: key];
      break;
    case NSOnState:
      [def setObject:@"YES" forKey: key];
      break;
    }
  [def synchronize];

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

  [preferencesDict setObject:[def objectForKey:key] 
                      forKey:key];
  [[NSNotificationCenter defaultCenter] 
    postNotificationName:PCPreferencesDidChangeNotification
                  object:self];
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
  [[NSUserDefaults standardUserDefaults] setObject:val forKey:key];
  [preferencesDict setObject:val forKey:key];
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

- (void)setRememberWindows:(id)sender
{
  NSUserDefaults *def = [NSUserDefaults standardUserDefaults];

  if (rememberWindows == nil)
    {
      rememberWindows = sender;
      return;
    }

  switch ([sender state])
    {
    case 0:
      [def setObject:@"NO" forKey:RememberWindows];
      break;
    case 1:
      [def setObject:@"YES" forKey:RememberWindows];
      break;
    }
  [def synchronize];

  [preferencesDict setObject:[def objectForKey:RememberWindows] 
                      forKey:RememberWindows];
}

- (void)setDisplayLog:(id)sender
{
  NSUserDefaults *def = [NSUserDefaults standardUserDefaults];

  if (displayLog == nil)
    {
      displayLog = sender;
      return;
    }

  switch ([sender state])
    {
    case 0:
      [def setObject:@"NO" forKey:DisplayLog];
      break;
    case 1:
      [def setObject:@"YES" forKey:DisplayLog];
      break;
    }
  [def synchronize];

  [preferencesDict setObject:[def objectForKey:DisplayLog] 
                      forKey:DisplayLog];
}

@end

