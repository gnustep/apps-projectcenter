#import <AppKit/AppKit.h>
#import <Foundation/Foundation.h>
#import <Renaissance/Renaissance.h>
#import "AppController.h"


/*
 * Initialise and go!
 */

int main(int argc, const char *argv[]) 
{
  CREATE_AUTORELEASE_POOL (pool);
  [NSApplication sharedApplication];
  [NSApp setDelegate: [AppController new]];
  
  #ifdef GNUSTEP
    [NSBundle loadGSMarkupNamed: @"MainMenu-GNUstep"  owner: [NSApp delegate]];
  #else
    [NSBundle loadGSMarkupNamed: @"MainMenu-OSX"  owner: [NSApp delegate]];
  #endif


  RELEASE (pool);
  return NSApplicationMain (argc, argv);

}
