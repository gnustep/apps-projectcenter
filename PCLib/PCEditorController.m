/* 
 * PCEditorController.m created by probert on 2002-02-02 15:28:31 +0000
 *
 * Project ProjectCenter
 *
 * Created with ProjectCenter - http://www.gnustep.org
 *
 * $Id$
 */

#include "PCProjectEditor.h"
#include "PCEditorController.h"
#include "PCEditorView.h"
#include "PCDefines.h"
#include "PCProject.h"
#include "PCEditor.h"
#include "PCProject+ComponentHandling.h"
#include "PCBrowserController.h"

@implementation PCEditorController

// ===========================================================================
// ==== Class Methods
// ===========================================================================

+ (void)openFileInEditor:(NSString *)path
{
    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];

    if([[ud objectForKey:ExternalEditor] isEqualToString:@"YES"])
    {
        NSTask         *editorTask;
	NSMutableArray *args;
	NSString       *editor = [ud objectForKey:Editor];
	NSString       *app;
	NSArray        *ea = [editor componentsSeparatedByString: @" "];

	args = [NSMutableArray arrayWithArray:ea];
	app = [args objectAtIndex: 0];

	if( [[app pathExtension] isEqualToString:@"app"] )
	{
	    BOOL ret = [[NSWorkspace sharedWorkspace] openFile:path 
	                                       withApplication:app];

	    if( ret == NO )
	    {
	        NSLog(@"Could not open %@ using %@",path,app);
	    }

            return;
	}

	editorTask = [[NSTask alloc] init];

	[editorTask setLaunchPath:app];
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
	[editor setDelegate:self];
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
    [editorDict removeAllObjects];
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

- (PCEditor *)internalEditorForFile:(NSString *)path
{
    PCEditor *editor;

    if((editor = [editorDict objectForKey:path]))
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

- (PCEditor *)editorForFile:(NSString *)path
{
    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];

    if([[ud objectForKey:ExternalEditor] isEqualToString:@"YES"])
    {
        [PCEditorController openFileInEditor:path];

	return nil;
    }
    else
    {
        return [self internalEditorForFile:path];
    }
}

- (PCEditor *)activeEditor
{
  NSEnumerator *enumerator = [editorDict keyEnumerator];
  PCEditor     *editor;
  NSString     *key;
  NSWindow     *window;

  while(( key = [enumerator nextObject] ))
    {
      editor = [editorDict objectForKey:key];
      window = [editor editorWindow];

      if (([window isVisible] && [window isKeyWindow])
	  || ([[editor internalView] superview]
	      && [[project projectWindow] isKeyWindow]))
	{
	  return editor;
	}
    }

  return nil;
}

- (NSArray *)allEditors
{
    return [editorDict allValues];
}

- (void)closeEditorForFile:(NSString *)file
{
  PCEditor *editor;

  editor = [editorDict objectForKey:file];
  [editor closeFile:self];
  [editorDict removeObjectForKey:file];
}

- (void)closeAllEditors
{
  NSEnumerator *enumerator = [editorDict keyEnumerator];
  PCEditor     *editor;
  NSString     *key;

  while ((key = [enumerator nextObject]))
    {
      editor = [editorDict objectForKey:key];
      [editor closeFile:self];
    }
  [editorDict removeAllObjects];
}

// ===========================================================================
// ==== File handling
// ===========================================================================

- (BOOL)saveAllFiles
{
    NSEnumerator *enumerator = [editorDict keyEnumerator];
    PCEditor     *editor;
    NSString     *key;
    BOOL          ret = YES;

    while(( key = [enumerator nextObject] ))
    {
        editor = [editorDict objectForKey:key];

	if( [editor saveFileIfNeeded] == NO )
	{
	    ret = NO;
	}
    }

    return ret;
}

- (BOOL)saveFile
{
  PCEditor *editor = [self activeEditor];

  if (editor != nil)
    {
      return [editor saveFileIfNeeded];
    }

  return NO;
}

- (BOOL)saveFileAs:(NSString *)file
{
  PCEditor *editor = [self activeEditor];

  if (editor != nil)
    {
      BOOL res;
      res = [editor saveFileTo:file];
      [editor closeFile:self];

      [[self internalEditorForFile:file]
	showInProjectEditor:[project projectEditor]];
      return res;
    }

  return NO;
}

- (BOOL)saveFileTo:(NSString *)file
{
  PCEditor *editor = [self activeEditor];

  if (editor != nil)
    {
      return [editor saveFileTo:file];
    }

  return NO;
}

- (BOOL)revertFileToSaved
{
  PCEditor *editor = [self activeEditor];

  if (editor != nil)
    {
      return [editor revertFileToSaved];
    }

  return NO;
}

- (void)closeFile:(id)sender
{
  [[self activeEditor] closeFile:self];
}

// ===========================================================================
// ==== Delegate
// ===========================================================================

- (void)editorDidClose:(id)sender
{
  PCEditor *editor = (PCEditor*)sender;
  
  [editorDict removeObjectForKey:[editor path]];

  if ([editorDict count])
    {
      editor = [editorDict objectForKey: [[editorDict allKeys] lastObject]];
      [editor showInProjectEditor: [project projectEditor]];
      [[project projectWindow] makeFirstResponder:[editor internalView]];
    }
  else
    {
      [[project projectEditor] setEditorView:nil];
      [[project browserController] projectDictDidChange:nil];
    }
}

- (void)setBrowserPath:(NSString *)file category:(NSString *)category
{
  [[project browserController] setPathForFile:file category:category];
}

@end
