/* 
 * PCEditorController.m created by probert on 2002-02-02 15:28:31 +0000
 *
 * Project ProjectCenter
 *
 * Created with ProjectCenter - http://www.gnustep.org
 *
 * $Id$
 */

#import "PCEditorController.h"
#import "PCEditor.h"
#import "PCProject.h"
#import "ProjectCenter.h"

@implementation PCEditorController

// ===========================================================================
// ==== Class Methods
// ===========================================================================

+ (void)openFileInEditor:(NSString *)path
{
    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];

    if([[ud objectForKey:ExternalEditor] isEqualToString:@"YES"])
    {
        NSTask *editorTask;
	NSMutableArray *args;
	NSString *editor = [ud objectForKey:Editor];
	NSArray *ea = [editor componentsSeparatedByString: @" "];

	args = [NSMutableArray arrayWithArray:ea];
	editorTask = [[NSTask alloc] init];
	[editorTask setLaunchPath:[args objectAtIndex: 0]];
	[args removeObjectAtIndex: 0];
	[args addObject:path];
	[editorTask setArguments:args];

	AUTORELEASE( editorTask );
	[editorTask launch];
    }
    else
    {
        PCEditor *editor;

	editor = [[PCEditor alloc] initWithPath:path];
	[editor show];
    }
}

// ===========================================================================
// ==== Initialisation
// ===========================================================================

- (id)init
{
    if((self = [super init]))
    {
        editorDict = [[NSMutableDictionary alloc] init];
    }
    return self;
}

- (void)dealloc
{
    RELEASE( editorDict );

    [super dealloc];
}

// ===========================================================================
// ==== Project and Editor handling
// ===========================================================================

- (void)setProject:(PCProject *)aProject
{
    project = aProject;
}

- (PCEditor *)editorForFile:(NSString *)path
{
    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];

    if([[ud objectForKey:ExternalEditor] isEqualToString:@"YES"])
    {
        [PCEditorController openFileInEditor:path];
    }
    else
    {
	PCEditor *editor;

	if( editor = [editorDict objectForKey:path] )
	{
	    return editor;
	}
	else
	{
	    editor = [[PCEditor alloc] initWithPath:path];

	    [editor setDelegate:self];

	    [editorDict setObject:editor forKey:path];
	    //RELEASE(editor);

	    return editor;
	}
    }
}

- (NSArray *)allEditors
{
    return [editorDict allValues];
}

- (void)closeAllEditors
{
    NSEnumerator *enumerator = [editorDict keyEnumerator];
    PCEditor *editor;
    NSString *key;

    while(( key = [enumerator nextObject] ))
    {
        editor = [editorDict objectForKey:key];

	[editor close];
    }
    [editorDict removeAllObjects];
}

- (void)editorDidClose:(id)sender
{
    PCEditor *editor = (PCEditor*)sender;

    [editorDict removeObjectForKey:[editor path]];
}

@end
