/*
   GNUstep ProjectCenter - http://www.projectcenter.ch

   Copyright (C) 2000 Philippe C.D. Robert

   Author: Philippe C.D. Robert <phr@projectcenter.ch>

   This file is part of ProjectCenter.

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

#import <AppKit/AppKit.h>
#import"PCAppController.h"

void createMenu();

int main(int argc, const char **argv) 
{
  NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
  PCAppController   *controller;

  [NSApplication sharedApplication];

  createMenu();

  controller = [[PCAppController alloc] init];
  [NSApp setDelegate:controller];

  RELEASE(pool);

  return NSApplicationMain (argc, argv);
}

void createMenu()
{
  NSMenu *menu;
  NSMenu *info;
  NSMenu *subprojects;
  NSMenu *project;
  NSMenu *file;
  NSMenu *edit;
  NSMenu *format;
  NSMenu *fontmenu;
  NSMenu *tools;
  NSMenu *services;
  NSMenu *windows;

  SEL action = @selector(method:);

  menu = [[NSMenu alloc] initWithTitle:@"ProjectCenter"];

  /*
   * The main menu
   */

  [menu addItemWithTitle:@"Info" action:action keyEquivalent:@""];
  [menu addItemWithTitle:@"Project" action:action keyEquivalent:@""];
  [menu addItemWithTitle:@"File" action:action keyEquivalent:@""];
  [menu addItemWithTitle:@"Edit" action:action keyEquivalent:@""];
  [menu addItemWithTitle:@"Format" action:action keyEquivalent:@""];
  [menu addItemWithTitle:@"Tools" action:action keyEquivalent:@""];
  [menu addItemWithTitle:@"Windows" action:action keyEquivalent:@""];
  [menu addItemWithTitle:@"Services" action:action keyEquivalent:@""];
  [menu addItemWithTitle:@"Hide" action:@selector(hide:) keyEquivalent:@"h"];
  [menu addItemWithTitle:@"Quit" action:@selector(terminate:)
		keyEquivalent:@"q"];

  /*
   * Info submenu
   */

  info = [[[NSMenu alloc] init] autorelease];
  [menu setSubmenu:info forItem:[menu itemWithTitle:@"Info"]];
  [info addItemWithTitle:@"Info Panel..." action:@selector(showInfoPanel:) keyEquivalent:@""];
  [info addItemWithTitle:@"Preferences" action:@selector(showPrefWindow:) keyEquivalent:@""];
  [info addItemWithTitle:@"Help" action:action keyEquivalent:@"?"];

  /*
   * Project submenu
   */

  project = [[[NSMenu alloc] init] autorelease];
  [menu setSubmenu:project forItem:[menu itemWithTitle:@"Project"]];
  [project addItemWithTitle:@"Open" action:@selector(openProject:) keyEquivalent:@"o"];
  [project addItemWithTitle:@"New" action:@selector(newProject:) keyEquivalent:@"n"];
  [project addItemWithTitle:@"Save" action:@selector(saveProject:) keyEquivalent:@"s"];
  [project addItemWithTitle:@"Save As" action:@selector(saveProjectAs:) keyEquivalent:@""];
  [project addItemWithTitle:@"Subprojects" action:action keyEquivalent:@""];
  [project addItemWithTitle:@"Close" action:@selector(closeProject:) keyEquivalent:@""];

  subprojects = [[[NSMenu alloc] init] autorelease];
  [project setSubmenu:subprojects forItem:[project itemWithTitle:@"Subprojects"]];
  [subprojects addItemWithTitle:@"New..." action:@selector(newSubproject:) keyEquivalent:@""];
  [subprojects addItemWithTitle:@"Add..." action:@selector(addSubproject:) keyEquivalent:@""];
  [subprojects addItemWithTitle:@"Remove..." action:@selector(removeSubproject:) keyEquivalent:@""];

  /*
   * File submenu
   */

  file = [[[NSMenu alloc] init] autorelease];
  [menu setSubmenu:file forItem:[menu itemWithTitle:@"File"]];
  [file addItemWithTitle:@"Open..." action:@selector(openFile:) keyEquivalent:@"O"];
  [file addItemWithTitle:@"Add..." action:@selector(addFile:) keyEquivalent:@"A"];
  [file addItemWithTitle:@"New in Project" action:@selector(newFile:) keyEquivalent:@"N"];
  [file addItemWithTitle:@"Remove File" action:@selector(removeFile:) keyEquivalent:@""];
  [file addItemWithTitle:@"Save..." action:@selector(saveFile:) keyEquivalent:@""];
  [file addItemWithTitle:@"Save as..." action:@selector(saveFileAs:) keyEquivalent:@""];
  [file addItemWithTitle:@"Revert" action:@selector(revertFile:) keyEquivalent:@""];
  [file addItemWithTitle:@"Rename" action:@selector(renameFile:) keyEquivalent:@""];

  /*
   * Edit submenu
   */

  edit = [[[NSMenu alloc] init] autorelease];
  [menu setSubmenu:edit forItem:[menu itemWithTitle:@"Edit"]];
  [edit addItemWithTitle: @"Cut" 
                   action: @selector(cut:) 
            keyEquivalent: @"x"];
  [edit addItemWithTitle: @"Copy" 
                   action: @selector(copy:) 
            keyEquivalent: @"c"];
  [edit addItemWithTitle: @"Paste" 
                   action: @selector(paste:) 
            keyEquivalent: @"v"];
  [edit addItemWithTitle: @"Delete" 
                   action: @selector(delete:) 
            keyEquivalent: @""];
  [edit addItemWithTitle: @"Select All" 
                   action: @selector(selectAll:) 
            keyEquivalent: @"a"];

  /*
   * Format submenu
   */

  format = [[[NSMenu alloc] init] autorelease];
  [menu setSubmenu:format forItem:[menu itemWithTitle:@"Format"]];
  [format addItemWithTitle:@"Fonts" action:NULL keyEquivalent:@""];

  fontmenu = [[[NSMenu alloc] init] autorelease];
  [format setSubmenu:[[NSFontManager sharedFontManager] fontMenu: YES] forItem:[format itemWithTitle:@"Fonts"]];

  /*
   * Tools submenu
   */

  tools = [[[NSMenu alloc] init] autorelease];
  [menu setSubmenu:tools forItem:[menu itemWithTitle:@"Tools"]];
  [tools addItemWithTitle:@"Loaded Projects..." action:@selector(showLoadedProjects:) keyEquivalent:@""];
  [tools addItemWithTitle:@"Build Panel" action:@selector(showBuildPanel:) keyEquivalent:@""];
  [tools addItemWithTitle:@"Find Panel" action:@selector(showFindPanel:) keyEquivalent:@"F"];
  [tools addItemWithTitle:@"Inspector Panel" action:@selector(showInspector:) keyEquivalent:@""];

  /*
   * Windows submenu
   */

  windows = [[[NSMenu alloc] init] autorelease];
  [menu setSubmenu:windows forItem:[menu itemWithTitle:@"Windows"]];
  [windows addItemWithTitle:@"Arrange"
		   action:@selector(arrangeInFront:)
		   keyEquivalent:@""];
  [windows addItemWithTitle:@"Miniaturize"
		   action:@selector(performMiniaturize:)
		   keyEquivalent:@"m"];
  [windows addItemWithTitle:@"Close"
		   action:@selector(performClose:)
		   keyEquivalent:@"w"];

  /*
   * Services submenu
   */

  services = [[[NSMenu alloc] init] autorelease];
  [menu setSubmenu:services forItem:[menu itemWithTitle:@"Services"]];

  [[NSApplication sharedApplication] setMainMenu:menu];
  [[NSApplication sharedApplication] setServicesMenu: services];

  //  [menu update];
  //  [menu display];
}
