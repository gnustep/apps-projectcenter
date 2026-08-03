/*
   GNUstep ProjectCenter - character ruler for the editor.
*/

#import <AppKit/AppKit.h>

@class PCEditorView;

@interface PCCharacterRulerView : NSRulerView
{
  PCEditorView *_textView;
  NSDictionary *_attributes;
}

- (id)initWithScrollView:(NSScrollView *)scrollView textView:(PCEditorView *)textView;
- (void)invalidateCharacterRuler:(NSNotification *)notification;

@end
