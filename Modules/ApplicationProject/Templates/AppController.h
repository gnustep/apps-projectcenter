/* 
 * AppController.h created by phr on 2000-08-27 11:38:59 +0000
 *
 * GNUstep Application Controller
 *
 * Created with ProjectCenter - http://www.gnustep.org
 *
 * $Id$
 */
 
#ifndef _PCAPPPROJ_APPCONTROLLER_H
#define _PCAPPPROJ_APPCONTROLLER_H

#include <AppKit/AppKit.h>

@interface AppController : NSObject
{
}

+ (void)initialize;

- (id)init;
- (void)dealloc;

- (void)awakeFromNib;

- (void)applicationDidFinishLaunching:(NSNotification *)notif;

- (BOOL)applicationShouldTerminate:(id)sender;
- (void)applicationWillTerminate:(NSNotification *)notification;

- (BOOL)application:(NSApplication *)application openFile:(NSString *)fileName;

- (void)showPrefPanel:(id)sender;
- (void)showInfoPanel:(id)sender;

@end

#endif
