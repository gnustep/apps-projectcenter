
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

// ===========================================================================
// ==== Initialisation
// ===========================================================================

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
  [_iView setDelegate: aDelegate];
  [_eView setDelegate: aDelegate];
}

- (id)delegate
{
  return _delegate;
}

// ===========================================================================
// ==== Accessor methods
// ===========================================================================

- (NSWindow *)editorWindow
{
  return _window;
}

- (PCEditorView *)internalView
{
  return _iView;
}

- (PCEditorView *)externalView
{
  return _eView;
}

- (NSString *)path
{
  return _path;
}

- (void)setPath:(NSString *)path
{
  [_path autorelease];
  _path = [path copy];
}

- (NSString *)category
{
  return _category;
}

- (void)setCategory:(NSString *)category
{
  _category = [category copy];
}

- (BOOL)isEdited
{
  return _isEdited;
}

- (void)setIsEdited:(BOOL)yn
{
  [_window setDocumentEdited:yn];
  _isEdited = yn;
}

// ===========================================================================
// ==== Object managment
// ===========================================================================

- (void)showInProjectEditor:(PCProjectEditor *)pe
{
  [pe setEditorView:_iView];
}

- (void)show
{
  [_window makeKeyAndOrderFront:self];
}

- (BOOL)saveFileIfNeeded
{
  if ((_isEdited))
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

- (BOOL)saveFileTo:(NSString *)path
{
  // Operate on the text storage!
  return [[_storage string] writeToFile:path atomically:YES];
}

- (BOOL)revertFileToSaved
{
  NSString           *text = [NSString stringWithContentsOfFile:_path];
  NSAttributedString *as = nil;
  NSDictionary       *at = nil;
  NSFont             *ft = nil;

  // This is temporary
  ft = [NSFont userFixedPitchFontOfSize:0.0];
  at = [NSDictionary dictionaryWithObject:ft forKey:NSFontAttributeName];
  as = [[NSAttributedString alloc] initWithString:text attributes:at];

  [self setIsEdited:NO];

  // Operate on the text storage!
  [_storage setAttributedString:as];
  RELEASE(as);

  [_iView setNeedsDisplay:YES];
  [_eView setNeedsDisplay:YES];
  
  return YES;
}

- (BOOL)closeFile:(id)sender
{
  if ([self editorShouldClose])
    {
      // Close window first if visible
      if ([_window isVisible] && (sender != _window))
	{
	  [_window close];
	}

      // Remove internal editor view
      if ([_iView superview])
	{
	  [_iView removeFromSuperview];
	}

      // Inform delegate
      if (_delegate 
	  && [_delegate respondsToSelector:@selector(editorDidClose:)])
	{
	  [_delegate editorDidClose:self];
	}

      return YES;
    }
  return NO;
}

- (BOOL)editorShouldClose
{
  if (_isEdited)
    {
      BOOL ret;

      if ([_window isVisible])
	{
	  [_window makeKeyAndOrderFront:self];
	}

      ret = NSRunAlertPanel(@"Close File",
			    @"Save changes to\n%@?",
			    @"Save", @"Don't save", @"Cancel", _path);

      if (ret == YES)
	{
	  if ([self saveFile] == NO)
	    {
	      NSRunAlertPanel(@"Close File",
		    	      @"Save failed!\nCould not save file '%@'!",
		    	      @"OK", nil, nil, _path);
	      return NO;
	    }
	  else
	    {
	      return YES;
	    }
	}
      else if (ret == NO) // Close but don't save
	{
	  return YES;
	}
      else               // Cancel closing
	{
	  return NO;
	}

      [self setIsEdited:NO];
    }

  return YES;
}

// ===========================================================================
// ==== Window delegate
// ===========================================================================

- (BOOL)windowShouldClose:(id)sender
{
  if ([sender isEqual:_window])
    {
      if ([_iView superview] != nil) 
	{
	  // Just close if this file also displayed in internal view
	  return YES;
	}
      else
	{
	  return [self closeFile:_window];
	}
    }

  return NO;
}

- (void)windowDidBecomeKey:(NSNotification *)aNotification
{
  if( [[aNotification object] isEqual:_window] )
  {
    [[NSNotificationCenter defaultCenter] 
      postNotificationName:PCEditorDidBecomeKeyNotification object:self];
  }
}

- (void)windowDidResignKey:(NSNotification *)aNotification
{
  if( [[aNotification object] isEqual:_window] )
  {
    [[NSNotificationCenter defaultCenter] 
      postNotificationName:PCEditorDidResignKeyNotification object:self];
  }
}

// ===========================================================================
// ==== TextView (_iView, _eView) delegate
// ===========================================================================

- (void)textDidChange:(NSNotification *)aNotification
{
  [self setIsEdited:YES];
}

- (BOOL)becomeFirstResponder
{
  if (_delegate 
      && [_delegate respondsToSelector:@selector(setBrowserPath:category:)])
    {
      [_delegate setBrowserPath:[_path lastPathComponent] category:_category];
    }
  
  return YES;
}

@end

