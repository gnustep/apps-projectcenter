/* 
 * AppController.h created by phr on 2000-08-27 11:38:59 +0000
 *
 * Project TestApp
 *
 * Created with ProjectCenter - http://www.projectcenter.ch
 *
 * $Id$
 */

#import <Foundation/Foundation.h>

@interface AppController : NSObject
{
}

- (id)init;
- (void)dealloc;

- (void)awakeFromNib;

- (void)applicationDidFinishLaunching:(NSNotification *)notif;

- (void)showPrefPanel:(id)sender;
- (void)showInfoPanel:(id)sender;

@end
