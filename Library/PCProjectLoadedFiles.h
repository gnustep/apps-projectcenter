/* 
 * Project ProjectCenter
 */

#ifndef _PCProjectLoadedFiles_h_
#define _PCProjectLoadedFiles_h_

#include <AppKit/AppKit.h>

@class PCProject;

typedef enum _PHSortType
{
  PHSortByTime,
  PHSortByName
} PHSortType;

@interface PCProjectLoadedFiles : NSObject
{
  PCProject      *project;
  NSTableView    *filesList;
  NSTableColumn  *filesColumn;
  NSScrollView   *filesScroll;
  NSMutableArray *editedFiles;

  PHSortType     sortType;
}

- (id)initWithProject:(PCProject *)aProj;
- (void)dealloc;
- (NSView *)componentView;
- (NSArray *)editedFilesRep;

- (void)setSortType:(PHSortType)type;
- (void)setSortByTime;
- (void)setSortByName;
- (void)selectNextFile;
- (void)selectPreviousFile;

- (void)click:(id)sender;
- (void)doubleClick:(id)sender;

@end

@interface PCProjectLoadedFiles (HistoryTableDelegate)

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

