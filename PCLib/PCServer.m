/*
   GNUstep ProjectCenter - http://www.projectcenter.ch

   Copyright (C) 2000 Philippe C.D. Robert

   Author: Philippe C.D. Robert <phr@projectcenter.ch>

   This file is part of ProjectCenter.

   This application is free software; you can redistribute it and/or
   modify it under the terms of the GNU General Public
   License as published by the Free Software Foundation; either
   version 2 of the License, or (at your option) any later version.

   This application is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
   Library General Public License for more details.

   You should have received a copy of the GNU General Public
   License along with this library; if not, write to the Free
   Software Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111 USA.

   $Id$
*/

#import "PCServer.h"
#import "ProjectCenter.h"
#import "PCBrowserController.h"

@implementation PCServer

//----------------------------------------------------------------------------
// Init and free
//----------------------------------------------------------------------------

- (id)init
{
  if ((self = [super init])) {
    clients = [[NSMutableArray alloc] init];
    openDocuments = [[NSMutableDictionary alloc] init];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(fileShouldBeOpened:) name:FileShouldOpenNotification object:nil];
  }
  return self;
}

- (void)dealloc
{
  [[NSNotificationCenter defaultCenter] removeObserver:self];

  [openDocuments release];
  [clients release];

  [super dealloc];
}

//----------------------------------------------------------------------------
// Miscellaneous
//----------------------------------------------------------------------------

- (void)fileShouldBeOpened:(NSNotification *)aNotif
{
  NSString *file = [[aNotif userInfo] objectForKey:@"FilePathKey"];

  if ([[[NSUserDefaults standardUserDefaults] objectForKey:ExternalEditor] isEqualToString:@"YES"]) {
    [self openFileInExternalEditor:file];
  }
  else {
    [self openFileInInternalEditor:file];
  }
}

- (void)openFileInExternalEditor:(NSString *)file
{
  NSTask *editorTask;
  NSMutableArray *args = [NSMutableArray array];
  NSUserDefaults *udef = [NSUserDefaults standardUserDefaults];
  NSString *editor = [udef objectForKey:Editor];

  editorTask = [[[NSTask alloc] init] autorelease];
  [editorTask setLaunchPath:editor];  

  [args addObject:file];
  [editorTask setArguments:args];

  [editorTask launch];
}

- (void)openFileInInternalEditor:(NSString *)file
{
  if ([openDocuments objectForKey:file]) {
    [[openDocuments objectForKey:file] makeKeyAndOrderFront:self];
  }
  else {
    NSWindow *editorWindow = [self editorForFile:file];
    
    [editorWindow setDelegate:self];
    [editorWindow center];
    [editorWindow makeKeyAndOrderFront:self];
    
    [openDocuments setObject:editorWindow forKey:file];
  }
}

- (NSWindow *)editorForFile:(NSString *)aFile
{
  unsigned int style = NSTitledWindowMask | NSClosableWindowMask | NSMiniaturizableWindowMask | NSResizableWindowMask;
  NSRect rect = NSMakeRect(100,100,512,320);
  NSWindow *window = [[NSWindow alloc] initWithContentRect:rect
				       styleMask:style
				       backing:NSBackingStoreBuffered
				       defer:YES];
  PCEditorView *textView;
  NSScrollView *scrollView;

  NSString *text = [NSString stringWithContentsOfFile:aFile];

  [window setMinSize:NSMakeSize(512,320)];
  [window setTitle:aFile];

  textView = [[PCEditorView alloc] initWithFrame:NSMakeRect(0,0,498,306)];
  [textView setMaxSize:NSMakeSize(1e7, 1e7)];
  [textView setRichText:NO];
  [textView setEditable:NO];
  [textView setSelectable:YES];
  [textView setVerticallyResizable:YES];
  [textView setHorizontallyResizable:NO];
  [textView setAutoresizingMask: NSViewWidthSizable | NSViewHeightSizable];
  [textView setBackgroundColor:[NSColor whiteColor]];
  [[textView textContainer] setWidthTracksTextView:YES];
  [textView autorelease];

  scrollView = [[NSScrollView alloc] initWithFrame:NSMakeRect (-1,-1,514,322)];
  [scrollView setDocumentView:textView];
  //[textView setMinSize:NSMakeSize(0.0,[scrollView contentSize].height)];
  [[textView textContainer] setContainerSize:NSMakeSize([scrollView contentSize].width,1e7)];
  [scrollView setHasHorizontalScroller: YES];
  [scrollView setHasVerticalScroller: YES];
  [scrollView setBorderType: NSBezelBorder];
  [scrollView setAutoresizingMask: (NSViewWidthSizable | NSViewHeightSizable)];
  [scrollView autorelease];

  [[window contentView] addSubview:scrollView];

  /*
   * Will be replaced when a real editor is available...
   */

  [textView setText:text];

  return [window autorelease];
}

- (void)windowDidClose:(NSNotification *)aNotif
{
  NSWindow *window = [aNotif object];

  [openDocuments removeObjectForKey:[window title]];
}

//----------------------------------------------------------------------------
// Server
//----------------------------------------------------------------------------

- (BOOL)registerProjectSubmenu:(NSMenu *)menu
{
}

- (BOOL)registerFileSubmenu:(NSMenu *)menu
{
}

- (BOOL)registerToolsSubmenu:(NSMenu *)menu
{
}

- (BOOL)registerPrefController:(id<PreferenceController>)prefs
{
}

- (BOOL)registerEditor:(id<ProjectEditor>)anEditor
{
}

- (BOOL)registerDebugger:(id<ProjectDebugger>)aDebugger
{
}

- (PCProject *)activeProject
{
}

- (NSString*)pathToActiveProject
{
}

- (id)activeFile
{
}

- (NSString*)pathToActiveFile
{
}

- (NSArray*)selectedFiles
{
}

- (NSArray*)touchedFiles
{
}

- (BOOL)queryTouchedFiles
{
}

- (BOOL)addFileAt:(NSString*)filePath toProject:(PCProject *)projectPath
{
}

- (BOOL)removeFileFromProject:(NSString *)filePath
{
}

- (void)connectionDidDie:(NSNotification *)notif
{
    id clientCon = [notif object];

    if ([clientCon isKindOfClass:[NSConnection class]]) {
        int i;

        for (i=0;i<[clients count];i++) {
            id client = [clients objectAtIndex:i];

            if ([client isProxy] && [client connectionForProxy] == clientCon) {
                [clients removeObjectAtIndex:i];
            }
        }        
    }
}

@end
