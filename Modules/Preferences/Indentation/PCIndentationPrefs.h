/* All rights reserved */

#include <AppKit/AppKit.h>

@interface PCIndentationPrefs : NSObject
{
  id _indentWhenTyping;
  id _indentForOpenCurly;
  id _indentForCloseCurly;
  id _indentForSemicolon;
  id _indentForColon;
  id _indentForHash;
  id _indentForReturn;
  id _indentForSoloOpenCurly;
  id _indentNumberOfSpaces;
}
- (void) setIndentWhenTyping: (id)sender;
- (void) setIndentForOpenCurlyBrace: (id)sender;
- (void) setIndentForCloseCurlyBrace: (id)sender;
- (void) setIndentForSemicolon: (id)sender;
- (void) setIndentForColon: (id)sender;
- (void) setIndentForHash: (id)sender;
- (void) setIndentForReturn: (id)sender;
- (void) setIndentForSoloOpenBrace: (id)sender;
@end
