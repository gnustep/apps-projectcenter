/* 
 * Project ProjectCenter
 */

#include "PCProjectHistory.h"
#include "PCDefines.h"
#include "PCProject.h"
#include "PCProjectEditor.h"
#include "PCEditor.h"

@implementation PCProjectHistory

- (id)initWithProject:(PCProject *)aProj 
{
  NSAssert(aProj, @"Project is mandatory!");

  if((self = [super init]))
    {
      project = aProj;
      editedFiles = [[NSMutableArray alloc] init];
      filesPath = [[NSMutableArray alloc] init];

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
      [filesList setTarget:self];
      [filesList setDoubleAction:@selector(doubleClick:)];
      [filesList setAction:@selector(click:)];

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
	   selector:@selector(fileDidOpen:)
	       name:PCEditorDidOpenNotification
	     object:nil];

      [[NSNotificationCenter defaultCenter]
	addObserver:self 
	   selector:@selector(fileDidClose:)
	       name:PCEditorDidCloseNotification
	     object:nil];
	     
      [[NSNotificationCenter defaultCenter]
	addObserver:self 
	   selector:@selector(editorDidBecomeActive:)
	       name:PCEditorDidBecomeActiveNotification
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
  RELEASE(filesPath);

  [super dealloc];
}

- (void)click:(id)sender
{
  // NSTableView doesn't call setAction: action
  NSLog(@"ProjectHistory click received");
}

- (void)doubleClick:(id)sender
{
  int      row = [filesList selectedRow];
  NSString *path = [filesPath objectAtIndex:row];

  [[project projectEditor] orderFrontEditorForFile:path];
}

- (NSView *)componentView
{
  return filesScroll;
}

// ===========================================================================
// ==== Notifications
// ===========================================================================

- (void)fileDidOpen:(NSNotification *)aNotif
{
  PCEditor *editor = [aNotif object];
  NSString *path = nil;
  NSString *file = nil;

  if ([editor projectEditor] != [project projectEditor])
    {
      return;
    }

  NSLog(@"PCProjectHistory: project %@", [project projectName]);

  path = [editor path];
  file = [path lastPathComponent];
  
  if ([editedFiles containsObject:file] == YES)
    {
      [editedFiles removeObject:file];
    }

  [editedFiles insertObject:file atIndex:0];
  [filesPath insertObject:path atIndex:0];
  [filesList reloadData];
  
  NSLog(@"PCProjectHistory: fileDidOpen.END");
}

- (void)fileDidClose:(NSNotification *)aNotif
{
  PCEditor *editor = [aNotif object];
  NSString *file = [[editor path] lastPathComponent];

  if ([editor projectEditor] != [project projectEditor])
    {
      return;
    }

  if ([editedFiles containsObject:file] == YES)
    {
      unsigned index = [editedFiles indexOfObject:file];
      
      [editedFiles removeObject:file];
      [filesPath removeObjectAtIndex:index];
      [filesList reloadData];
    }
}

- (void)editorDidBecomeActive:(NSNotification *)aNotif
{
  PCEditor *editor = [aNotif object];
  NSString *file = nil;
  unsigned index;
  
  if ([editor projectEditor] != [project projectEditor])
    {
      return;
    }

  file = [[editor path] lastPathComponent];
  index = [editedFiles indexOfObject:file];
  [filesList selectRow:index byExtendingSelection:NO];
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
/*  NSString *path = nil;
  NSParameterAssert (rowIndex >= 0 && rowIndex < [editedFiles count]);

  [editedFiles removeObjectAtIndex:rowIndex];
  [editedFiles insertObject:anObject atIndex:rowIndex];

  path = 
  [filesPath removeObjectAtIndex:rowIndex];
  [filesPath insertObject:[editor path] atIndex:rowIndex];*/
}

@end

