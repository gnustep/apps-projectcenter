/* 
 * Project ProjectCenter
 */

#ifndef _PCProjectHistory_h_
#define _PCProjectHistory_h_

#include <AppKit/AppKit.h>

@class PCProject;

@interface PCProjectHistory : NSObject
{
  PCProject      *project;
  NSTableView    *filesList;
  NSTableColumn  *filesColumn;
  NSScrollView   *filesScroll;
  NSMutableArray *editedFiles;
  NSMutableArray *filesPath;
}

- (id)initWithProject:(PCProject *)aProj;
- (void)dealloc;
- (NSView *)componentView;

- (void)click:(id)sender;
- (void)doubleClick:(id)sender;

@end

@interface PCProjectHistory (HistoryTableDelegate)

- (int)numberOfRowsInTableView:(NSTableView *)aTableView;

- (id)            tableView:(NSTableView *)aTableView
  objectValueForTableColumn:(NSTableColumn *)aTableColumn
                        row:(int)rowIndex;

- (void)tableView:(NSTableView *)aTableView
   setObjectValue:anObject
   forTableColumn:(NSTableColumn *)aTableColumn
              row:(int)rowIndex;

@end

#endif 

