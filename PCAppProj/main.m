#import <AppKit/AppKit.h>
#import "AppController.h"

#define APP_NAME @"GNUstep"

/*
 * Create the application's menu
 */

void createMenu();

/*
 * Initialise and go!
 */

int main(int argc, const char *argv[]) {
  NSApplication *theApp;
  id pool = [[NSAutoreleasePool alloc] init];
  AppController *controller;
  
#ifndef NX_CURRENT_COMPILER_RELEASE
  initialize_gnustep_backend();
#endif
  
  theApp = [NSApplication sharedApplication];

  createMenu();

  controller = [[AppController alloc] init];
  [theApp setDelegate:controller];

  /*
   * Go...
   */  

  [theApp run];
  
  /*
   * ...and finish!
   */

  [controller release];
  [pool release];
  
  return 0;
}

void createMenu()
{
  NSMenu *menu;
  NSMenu *info;
  NSMenu *edit;
  NSMenu *services;
  NSMenu *windows;

  SEL action = @selector(method:);

  menu = [[NSMenu alloc] initWithTitle:APP_NAME];

  [menu addItemWithTitle:@"Info" action:action keyEquivalent:@""];
  [menu addItemWithTitle:@"Edit" action:action keyEquivalent:@""];
  [menu addItemWithTitle:@"Windows" action:action keyEquivalent:@""];
  [menu addItemWithTitle:@"Services" action:action keyEquivalent:@""];
  [menu addItemWithTitle:@"Hide" action:@selector(hide:) keyEquivalent:@"h"];
  [menu addItemWithTitle:@"Quit" action:@selector(terminate:) keyEquivalent:@"q"];

  info = [[[NSMenu alloc] init] autorelease];
  [menu setSubmenu:info forItem:[menu itemWithTitle:@"Info"]];
  [info addItemWithTitle:@"Info Panel..." action:@selector(showInfoPanel:) keyEquivalent:@""];
  [info addItemWithTitle:@"Preferences" action:@selector(showPrefPanel:) keyEquivalent:@""];
  [info addItemWithTitle:@"Help" action:action keyEquivalent:@"?"];

  edit = [[[NSMenu alloc] init] autorelease];
  [edit addItemWithTitle:@"Cut" action:action keyEquivalent:@"x"];
  [edit addItemWithTitle:@"Copy" action:action keyEquivalent:@"c"];
  [edit addItemWithTitle:@"Paste" action:action keyEquivalent:@"v"];
  [edit addItemWithTitle:@"Delete" action:action keyEquivalent:@""];
  [edit addItemWithTitle:@"Select All" action:action keyEquivalent:@"a"];
  [menu setSubmenu:edit forItem:[menu itemWithTitle:@"Edit"]];

  windows = [[[NSMenu alloc] init] autorelease];
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

  services = [[[NSMenu alloc] init] autorelease];
  [menu setSubmenu:services forItem:[menu itemWithTitle:@"Services"]];

  [[NSApplication sharedApplication] setMainMenu:menu];
  [[NSApplication sharedApplication] setServicesMenu: services];

  [menu update];
  [menu display];
}



