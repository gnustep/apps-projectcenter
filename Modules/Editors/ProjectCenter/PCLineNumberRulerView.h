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
}

- (id)initWithScrollView:(NSScrollView *)scrollView textView:(PCEditorView *)textView;
- (void)invalidateLineNumbers:(NSNotification *)notification;

@end
