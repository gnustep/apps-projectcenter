/* 
 * Project ProjectCenter
 */

#include "PCProjectHistory.h"
#include "PCDefines.h"
#include "PCProject.h"

@implementation PCProjectHistory

- (id)initWithProject:(PCProject *)aProj 
{
  NSAssert(aProj, @"Project is mandatory!");

  if((self = [super init]))
    {
      project = aProj;
      editedFiles = [[NSMutableArray alloc] init];

      // Column
      filesColumn = [[NSTableColumn alloc] initWithIdentifier: @"Files List"];
      [filesColumn setEditable:NO];

      // Table
      filesList = [[NSTableView alloc] 
	initWithFrame:NSMakeRect(0,0,160,128)];
      [filesList setAllowsMultipleSelection:NO];
      [filesList setAllowsColumnReordering:NO];
      [filesList setAllowsColumnResizing:NO];
      [filesList setAllowsEmptySelection:YES];
      [filesList setAllowsColumnSelection:NO];
      [filesList setCornerView:nil];
      [filesList setHeaderView:nil];
      [filesList addTableColumn:filesColumn];
      [filesList setDataSource:self];
/*      [filesList setBackgroundColor: [NSColor colorWithDeviceRed:0.88
                                                           green:0.76 
                                                            blue:0.60 
                                                           alpha:1.0]];*/
      // Hack! Should be [filesList setDrawsGrid:NO]
      [filesList setGridColor: [NSColor lightGrayColor]];

      // Scrollview
      filesScroll = [[NSScrollView alloc] initWithFrame:
	NSMakeRect (0, 0, 80, 128)];
      [filesScroll setDocumentView:filesList];
      [filesScroll setHasHorizontalScroller:NO];
      [filesScroll setHasVerticalScroller:YES];
      if ([[[[NSUserDefaults standardUserDefaults] dictionaryRepresentation]
  	  objectForKey: SeparateHistory] isEqualToString: @"NO"])
	{
	  [filesScroll setBorderType:NSBezelBorder];
	}

      [filesList reloadData];

      [[NSNotificationCenter defaultCenter]
	addObserver:self
	   selector:@selector(historyDidChange:)
	       name:@"FileBecomesEditedNotification"
	     object:nil];
    }

  return self;
}

- (void)dealloc
{
  NSLog (@"PCProjectHistory: dealloc");

  [[NSNotificationCenter defaultCenter] removeObserver:self];

  RELEASE(filesColumn);
  RELEASE(filesList);
  RELEASE(editedFiles);

  [super dealloc];
}

- (void)click:(id)sender
{
/*  NSString *file = [[[sender selectedCell] stringValue] copy];

  [project filesListDidClickFile:file category:nil];*/

    /* This causes a problem because we try to reloadColumn on the filesList
       in the middle of someone clicking in it (-click: sends notification
       which is received by histortDidChange:, etc. Is there a better
       way around this? */
/*  [[NSNotificationCenter defaultCenter] 
    postNotificationName:@"FileBecomesEditedNotification"
                  object:file];

  AUTORELEASE(file);*/
}

- (void)historyDidChange:(NSNotification *)notif
{
  NSString *file = [notif object];

  if ([editedFiles containsObject:file] == YES)
    {
      [editedFiles removeObject:file];
    }

  [editedFiles insertObject:file atIndex:0];
  [filesList reloadData];
}

- (NSView *)componentView
{
  return filesScroll;
}

@end

@implementation PCProjectHistory (HistoryTableDelegate)

- (int)numberOfRowsInTableView: (NSTableView *)aTableView
{
  return [editedFiles count];
}

- (id)            tableView: (NSTableView *)aTableView
  objectValueForTableColumn: (NSTableColumn *)aTableColumn
                        row: (int)rowIndex
{
  return [editedFiles objectAtIndex: rowIndex];
}

- (void) tableView:(NSTableView *)aTableView
    setObjectValue:anObject
    forTableColumn:(NSTableColumn *)aTableColumn
               row:(int)rowIndex
{
  NSParameterAssert (rowIndex >= 0 && rowIndex < [editedFiles count]);

  [editedFiles removeObjectAtIndex:rowIndex];
  [editedFiles insertObject:anObject atIndex:rowIndex];
}

@end

