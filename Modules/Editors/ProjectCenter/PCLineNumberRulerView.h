/*
   GNUstep ProjectCenter - line number ruler for the editor.
*/

#import <AppKit/AppKit.h>

@class PCEditorView;

@interface PCLineNumberRulerView : NSRulerView
{
  PCEditorView *_textView;
  NSDictionary *_attributes;
  NSMutableSet *_breakpoints;
  BOOL _showsLineNumbers;
}

- (id)initWithScrollView:(NSScrollView *)scrollView textView:(PCEditorView *)textView;
- (void)invalidateLineNumbers:(NSNotification *)notification;
- (void)setShowsLineNumbers:(BOOL)flag;
- (BOOL)showsLineNumbers;

@end
