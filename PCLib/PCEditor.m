
/* 
 * PCEditor.m created by probert on 2002-01-29 20:37:27 +0000
 *
 * Project ProjectCenter
 *
 * Created with ProjectCenter - http://www.gnustep.org
 *
 * $Id$
 */

#include "PCEditor.h"
#include "PCDefines.h"
#include "PCEditorView.h"
#include "ProjectComponent.h"
#include "PCProjectEditor.h"

#include "PCEditor+UInterface.h"

NSString *PCEditorDidBecomeKeyNotification=@"PCEditorDidBecomeKeyNotification";
NSString *PCEditorDidResignKeyNotification=@"PCEditorDidResignKeyNotification";

@implementation PCEditor

- (id)initWithPath:(NSString*)file
{
  if((self = [super init]))
  {
    NSString            *t;
    NSAttributedString *as;
    NSDictionary       *at;
    NSFont             *ft;

    ft = [NSFont userFixedPitchFontOfSize:0.0];
    at = [NSDictionary dictionaryWithObject:ft forKey:NSFontAttributeName];
    t  = [NSString stringWithContentsOfFile:file];
    as = [[NSAttributedString alloc] initWithString:t attributes:at];

    _isEdited = NO;
    _path = [file copy];

    [self _initUI];

    [_window setTitle:file];
    [_storage setAttributedString:as];
    RELEASE(as);

    [_iView setNeedsDisplay:YES];
    [_eView setNeedsDisplay:YES];

    [[NSNotificationCenter defaultCenter] addObserver:self 
                                          selector:@selector(textDidChange:)
                                          name:NSTextDidChangeNotification
                                          object:_eView];
    [[NSNotificationCenter defaultCenter] addObserver:self 
                                          selector:@selector(textDidChange:)
                                          name:NSTextDidChangeNotification
                                          object:_iView];
  }
  return self;
}

- (void)dealloc
{
  [[NSNotificationCenter defaultCenter] removeObserver:self];

  RELEASE(_window);
  RELEASE(_path);

  RELEASE(_iView);
  RELEASE(_storage);

  [super dealloc];
}

- (void)setDelegate:(id)aDelegate
{
  _delegate = aDelegate;
}

- (id)delegate
{
  return _delegate;
}

- (NSWindow *)editorWindow
{
  return _window;
}

- (NSString *)path
{
  return _path;
}

- (void)setIsEdited:(BOOL)yn
{
  [_window setDocumentEdited:yn];
  _isEdited = yn;
}

- (void)showInProjectEditor:(PCProjectEditor *)pe
{
  [pe setEditorView:_iView];
}

- (void)show
{
  [_window makeKeyAndOrderFront:self];
}

- (void)close
{
  if( _isEdited )
  {
    BOOL ret;

    if( [_window isVisible] )
    {
      [_window makeKeyAndOrderFront:self];
    }

    ret = NSRunAlertPanel(@"Edited File!",
                          @"Should '%@' be saved before closing?",
                          @"Yes",@"No",nil,_path);

    if( ret == YES )
    {
      ret = [self saveFile];

      if((ret == NO))
      {
        NSRunAlertPanel(@"Save Failed!",
                        @"Could not save file '%@'!",
                        @"OK",nil,nil,_path);
      }
    }

    [self setIsEdited:NO];
  }

  if( _delegate && [_delegate respondsToSelector:@selector(editorDidClose:)] )
  {
    [_delegate editorDidClose:self];
  }
}

- (BOOL)saveFileIfNeeded
{
  if((_isEdited))
  {
    return [self saveFile];
  }

  return YES;
}

- (BOOL)saveFile
{
  [self setIsEdited:NO];

  // Operate on the text storage!
  return [[_storage string] writeToFile:_path atomically:YES];
}

- (BOOL)revertFile
{
  NSString *text = [NSString stringWithContentsOfFile:_path];
  NSAttributedString *as = [[NSAttributedString alloc] initWithString:text];

  [self setIsEdited:NO];

  // Operate on the text storage!
  [_storage setAttributedString:as];
  RELEASE(as);

  [_iView setNeedsDisplay:YES];
  [_eView setNeedsDisplay:YES];
  
  return YES;
}

- (void)windowWillClose:(NSNotification *)aNotification
{
  if( [[aNotification object] isEqual:_window] )
  {
    [self close];
  }
}

- (void)windowDidBecomeKey:(NSNotification *)aNotification
{
  if( [[aNotification object] isEqual:_window] )
  {
    [[NSNotificationCenter defaultCenter] postNotificationName:PCEditorDidBecomeKeyNotification object:self];
  }
}

- (void)windowDidResignKey:(NSNotification *)aNotification
{
  if( [[aNotification object] isEqual:_window] )
  {
    [[NSNotificationCenter defaultCenter] postNotificationName:PCEditorDidResignKeyNotification object:self];
  }
}

- (void)textDidChange:(NSNotification *)aNotification
{
  [self setIsEdited:YES];
}

@end
