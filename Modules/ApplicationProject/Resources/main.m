/* 
 *  This application is free software; you can redistribute it and/or
 *  modify it under the terms of the GNU General Public
 *  License as published by the Free Software Foundation; either
 *  version 2 of the License, or (at your option) any later version.
 *
 *  This application is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 *  Library General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public
 *  License along with this library; if not, write to the Free
 *  Software Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111 USA.
 */

#include <AppKit/AppKit.h>
#include "AppController.h"

/*
 * Create the application's menu
 */

void createMenu();

/*
 * Initialise and go!
 */

int main(int argc, const char *argv[]) 
{
  NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
  AppController     *controller;
  
  [NSApplication sharedApplication];

  createMenu();

  controller = [[AppController alloc] init];
  [NSApp setDelegate:controller];

  RELEASE(pool);

  return NSApplicationMain (argc, argv);
}

void createMenu()
{
  NSMenu *menu;
  NSMenu *info;
  NSMenu *edit;
  NSMenu *services;
  NSMenu *windows;

  SEL action = @selector(method:);

  menu = [[NSMenu alloc] initWithTitle:@"GNUstep"];

  [menu addItemWithTitle:@"Info" action:@selector(showInfoPanel:) 
	keyEquivalent:@""];
  [menu addItemWithTitle:@"Edit" action:action keyEquivalent:@""];
  [menu addItemWithTitle:@"Windows" action:action keyEquivalent:@""];
  [menu addItemWithTitle:@"Services" action:action keyEquivalent:@""];
  [menu addItemWithTitle:@"Hide" action:@selector(hide:) keyEquivalent:@"h"];
  [menu addItemWithTitle:@"Quit" action:@selector(terminate:) keyEquivalent:@"q"];

  info = AUTORELEASE([[NSMenu alloc] init]);
  [menu setSubmenu:info forItem:[menu itemWithTitle:@"Info"]];
  [info addItemWithTitle:@"Info Panel..." 
	action:@selector(showInfoPanel:) keyEquivalent:@""];
  [info addItemWithTitle:@"Preferences" 
	action:@selector(showPrefPanel:) keyEquivalent:@""];
  [info addItemWithTitle:@"Help" action:action keyEquivalent:@"?"];

  edit = AUTORELEASE([[NSMenu alloc] init]);
  [edit addItemWithTitle:@"Cut" 
	action:@selector(cut:) 
	keyEquivalent:@"x"];
  [edit addItemWithTitle:@"Copy" 
	action:@selector(copy:) 
	keyEquivalent:@"c"];
  [edit addItemWithTitle:@"Paste" 
	action:@selector(paste:)
	keyEquivalent:@"v"];
  [edit addItemWithTitle:@"Delete" 
	action:@selector(delete:)
	keyEquivalent:@""];
  [edit addItemWithTitle:@"Select All" 
	action:@selector(selectAll:)
	keyEquivalent:@"a"];
  [menu setSubmenu:edit forItem:[menu itemWithTitle:@"Edit"]];

  windows = AUTORELEASE([[NSMenu alloc] init]);
  [windows addItemWithTitle:@"Arrange"
		   action:@selector(arrangeInFront:)
		   keyEquivalent:@""];
  [windows addItemWithTitle:@"Miniaturize"
		   action:@selector(performMiniaturize:)
		   keyEquivalent:@"m"];
  [windows addItemWithTitle:@"Close"
		   action:@selector(performClose:)
		   keyEquivalent:@"w"];
  [menu setSubmenu:windows forItem:[menu itemWithTitle:@"Windows"]];

  services = AUTORELEASE([[NSMenu alloc] init]);
  [menu setSubmenu:services forItem:[menu itemWithTitle:@"Services"]];

  [NSApp setMainMenu:menu];
  [NSApp setServicesMenu: services];
}





