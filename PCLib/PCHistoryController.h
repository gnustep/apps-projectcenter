/* 
 * PCHistoryController.h created by probert on 2002-02-21 14:28:09 +0000
 *
 * Project ProjectCenter
 *
 * Created with ProjectCenter - http://www.gnustep.org
 *
 * $Id$
 */

#ifndef _PCHISTORYCONTROLLER_H_
#define _PCHISTORYCONTROLLER_H_

#include <AppKit/AppKit.h>

@class PCProject;

@interface PCHistoryController : NSObject
{
    id browser;
    PCProject *project;
    NSMutableArray *editedFiles;
}

- (id)initWithProject:(PCProject *)aProj;
- (void)dealloc;

- (void)click:(id)sender;

- (void)setBrowser:(NSBrowser *)aBrowser;

- (void)historyDidChange:(NSNotification *)notif;

@end

@interface PCHistoryController (HistoryBrowserDelegate)

- (void)browser:(NSBrowser *)sender createRowsForColumn:(int)column inMatrix:(NSMatrix *)matrix;
- (void)browser:(NSBrowser *)sender willDisplayCell:(id)cell atRow:(int)row column:(int)column;
- (BOOL)browser:(NSBrowser *)sender selectCellWithString:(NSString *)title inColumn:(int)column;

@end

#endif // _PCHISTORYCONTROLLER_H_

