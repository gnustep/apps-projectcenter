/* 
 * PCTextFinder.h created by probert on 2002-02-03 13:23:01 +0000
 *
 * Project ProjectCenter
 *
 * Created with ProjectCenter - http://www.gnustep.org
 *
 * $Id$
 */

#ifndef _PCTEXTFINDER_H_
#define _PCTEXTFINDER_H_

#include <AppKit/AppKit.h>

@interface PCTextFinder : NSObject
{
    NSPanel *panel;
    NSString *findString;
    id findTextField;
    id replaceTextField;
    id statusField;
    id ignoreCaseButton;
    id regexpButton;

    BOOL findStringChangedSinceLastPasteboardUpdate;
    BOOL lastFindWasSuccessful;
    BOOL shouldReplaceAll;
    BOOL shouldIgnoreCase;
}

+ (PCTextFinder*)sharedFinder;

- (id)init;
- (void)dealloc;

- (NSPanel *)findPanel;

- (void)showFindPanel:(id)sender;
- (void)buttonPressed:(id)sender;
- (void)setReplaceAllScope:(id)sender;
- (void)setIgnoreCase:(id)sender;

- (BOOL)find:(BOOL)direction;
- (NSTextView *)textObjectToSearchIn;
- (NSString *)findString;
- (void)setFindString:(NSString *)string;

- (void)loadFindStringFromPasteboard;
- (void)loadFindStringToPasteboard;

- (void)findNext:(id)sender;
- (void)findPrevious:(id)sender;
- (void)findNextAndOrderFindPanelOut:(id)sender;
- (void)replace:(id)sender;
- (void)replaceAll:(id)sender;

@end

#endif // _PCTEXTFINDER_H_

