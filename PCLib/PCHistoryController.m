/* 
 * PCHistoryController.m created by probert on 2002-02-21 14:28:08 +0000
 *
 * Project ProjectCenter
 *
 * Created with ProjectCenter - http://www.gnustep.org
 *
 * $Id$
 */

#import "PCHistoryController.h"
#import "PCProject.h"

@implementation PCHistoryController

- (id)initWithProject:(PCProject *)aProj 
{
    NSAssert(aProj, @"Project is mandatory!");

    if((self = [super init]))
    {
	project = aProj;

	editedFiles = [[NSMutableArray alloc] init];
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];

    RELEASE(editedFiles);

    [super dealloc];
}

- (void)click:(id)sender
{
    NSString *file = [[[sender selectedCell] stringValue] copy];

    [project browserDidClickFile:file category:nil];

    /* This causes a problem because we try to reloadColumn on the browser
       in the middle of someone clicking in it (-click: sends notification
       which is received by histortDidChange:, etc. Is there a better
       way around this? */
    //[[NSNotificationCenter defaultCenter] postNotificationName:@"FileBecomesEditedNotification" object:file];

    AUTORELEASE(file);
}

- (void)setBrowser:(NSBrowser *)aBrowser
{
    NSAssert(browser==nil,@"The browser is already set!");

    browser = aBrowser;

    [browser setTitled:NO];

    [browser setTarget:self];
    [browser setAction:@selector(click:)];

    [browser setMaxVisibleColumns:1];
    [browser setAllowsMultipleSelection:NO];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(historyDidChange:) name:@"FileBecomesEditedNotification" object:nil];
}

- (void)historyDidChange:(NSNotification *)notif
{
    NSString *file = [notif object];

    if( [editedFiles containsObject:file] == YES )
    {
        [editedFiles removeObject:file];
    }

    [editedFiles insertObject:file atIndex:0];
    [browser reloadColumn:0];
}

@end

@implementation PCHistoryController (HistoryBrowserDelegate)

- (void)browser:(NSBrowser *)sender createRowsForColumn:(int)column inMatrix:(NSMatrix *)matrix
{
    int i;
    int count = [editedFiles count];

    if( sender != browser ) return;

    for( i=0; i<count;++i )
    {
      id cell;

      [matrix insertRow:i];

      cell = [matrix cellAtRow:i column:0];
      [cell setStringValue:[editedFiles objectAtIndex:i]];
      [cell setLeaf:YES];
    }
}

- (void)browser:(NSBrowser *)sender willDisplayCell:(id)cell atRow:(int)row column:(int)column
{
}

- (BOOL)browser:(NSBrowser *)sender selectCellWithString:(NSString *)title inColumn:(int)column
{
    return YES;
}

@end

