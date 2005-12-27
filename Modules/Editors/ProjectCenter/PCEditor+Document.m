
// TODO: Needs checking
@implementation PCEditor (Document)

#import "CommandQueryPanel.h"
#import "LineQueryPanel.h"
#import "TextFinder.h"
#import "EditorRulerView.h"
#import "EditorTextView.h"
#import "SyntaxHighlighter.h"

/**
 * Checks whether a character is a delimiter.
 *
 * This function checks whether `character' is a delimiter character,
 * (i.e. one of "(", ")", "[", "]", "{", "}") and returns YES if it
 * is and NO if it isn't. Additionaly, if `character' is a delimiter,
 * `oppositeDelimiter' is set to a string denoting it's opposite
 * delimiter and `searchBackwards' is set to YES if the opposite
 * delimiter is located before the checked delimiter character, or
 * to NO if it is located after the delimiter character.
 */
static inline BOOL CheckDelimiter(unichar character,
                                  unichar * oppositeDelimiter,
                                  BOOL * searchBackwards)
{
  if (character == '(')
    {
      *oppositeDelimiter = ')';
      *searchBackwards = NO;

      return YES;
    }
  else if (character == ')')
    {
      *oppositeDelimiter = '(';
      *searchBackwards = YES;

      return YES;
    }
  else if (character == '[')
    {
      *oppositeDelimiter = ']';
      *searchBackwards = NO;

      return YES;
    }
  else if (character == ']')
    {
      *oppositeDelimiter = '[';
      *searchBackwards = YES;

      return YES;
    }
  else if (character == '{')
    {
      *oppositeDelimiter = '}';
      *searchBackwards = NO;

      return YES;
    }
  else if (character == '}')
    {
      *oppositeDelimiter = '{';
      *searchBackwards = YES;

      return YES;
    }
  else
    {
      return NO;
    }
}

/**
 * Attempts to find a delimiter in a certain string around a certain location.
 *
 * Attempts to locate `delimiter' in `string', starting at
 * location `startLocation' a searching forwards (backwards if
 * searchBackwards = YES) at most 1000 characters. The argument
 * `oppositeDelimiter' denotes what is considered to be the opposite
 * delimiter of the one being search for, so that nested delimiters
 * are ignored correctly.
 *
 * @return The location of the delimiter if it is found, or NSNotFound
 *      if it isn't.
 */
unsigned int FindDelimiterInString(NSString * string,
                                   unichar delimiter,
                                   unichar oppositeDelimiter,
                                   unsigned int startLocation,
                                   BOOL searchBackwards)
{
  unsigned int i;
  unsigned int length;
  unichar (*charAtIndex)(id, SEL, unsigned int);
  SEL sel = @selector(characterAtIndex:);
  int nesting = 1;

  charAtIndex = (unichar (*)(id, SEL, unsigned int)) [string
    methodForSelector: sel];

  if (searchBackwards)
    {
      if (startLocation < 1000)
        length = startLocation;
      else
        length = 1000;

      for (i=1; i <= length; i++)
        {
          unichar c;

          c = charAtIndex(string, sel, startLocation - i);
          if (c == delimiter)
            nesting--;
          else if (c == oppositeDelimiter)
            nesting++;

          if (nesting == 0)
            break;
        }

      if (i > length)
        return NSNotFound;
      else
        return startLocation - i;
    }
  else
    {
      if ([string length] < startLocation + 1000)
        length = [string length] - startLocation;
      else
        length = 1000;

      for (i=1; i < length; i++)
        {
          unichar c;

          c = charAtIndex(string, sel, startLocation + i);
          if (c == delimiter)
            nesting--;
          else if (c == oppositeDelimiter)
            nesting++;

          if (nesting == 0)
            break;
        }

      if (i == length)
        return NSNotFound;
      else
        return startLocation + i;
    }
}

- (void)pipeOutputOfCommand:(NSString *)command
{
  NSTask * task;
  NSPipe * inPipe, * outPipe;
  NSString * inString, * outString;
  NSFileHandle * inputHandle;

  inString = [[textView string] substringWithRange:
    [textView selectedRange]];
  inPipe = [NSPipe pipe];
  outPipe = [NSPipe pipe];

  task = [[NSTask new] autorelease];

  [task setLaunchPath: @"/bin/sh"];
  [task setArguments: [NSArray arrayWithObjects: @"-c", command, nil]];
  [task setStandardInput: inPipe];
  [task setStandardOutput: outPipe];
  [task setStandardError: outPipe];

  inputHandle = [inPipe fileHandleForWriting];

  [task launch];
  [inputHandle writeData: [inString
    dataUsingEncoding: NSUTF8StringEncoding]];
  [inputHandle closeFile];
  [task waitUntilExit];
  outString = [[[NSString alloc]
    initWithData: [[outPipe fileHandleForReading] availableData]
        encoding: NSUTF8StringEncoding]
    autorelease];
  if ([task terminationStatus] != 0)
    {
      if (NSRunAlertPanel(_(@"Error running command"),
        _(@"The command returned with a non-zero exit status"
          @" -- aborting pipe.\n"
          @"Do you want to see the command's output?\n"),
        _(@"No"), _(@"Yes"), nil) == NSAlertAlternateReturn)
        {
          NSRunAlertPanel(_(@"The command's output"),
            outString, nil, nil, nil);
        }
    }
  else
    {
      [textView replaceCharactersInRange:[textView selectedRange]
                              withString:outString];
      [self textDidChange: nil];
    }
}

- (void) updateMiniwindowIconToEdited: (BOOL) flag
{
  NSImage * icon;

  if (flag)
    {
      icon = [NSImage imageNamed:
        [NSString stringWithFormat: @"File_%@_mod", [self fileType]]];
    }
  else
    {
      icon = [NSImage imageNamed:
        [NSString stringWithFormat: @"File_%@", [self fileType]]];
    }

  [myWindow setMiniwindowImage: icon];
}

- (void) unhighlightCharacter
{
  if (isCharacterHighlit)
    {
      NSTextStorage * textStorage = [textView textStorage];
      NSRange r = NSMakeRange(highlitCharacterLocation, 1);

      isCharacterHighlit = NO;

      [textStorage beginEditing];

      // restore the character's color and font attributes
      if (previousFont != nil)
        {
          [textStorage addAttribute: NSFontAttributeName
                              value: previousFont
                              range: r];
        }
      else
        {
          [textStorage removeAttribute: NSFontAttributeName range: r];
        }

      if (previousFGColor != nil)
        {
          [textStorage addAttribute: NSForegroundColorAttributeName
                              value: previousFGColor
                              range: r];
        }
      else
        {
          [textStorage removeAttribute: NSForegroundColorAttributeName
                                 range: r];
        }

      if (previousBGColor != nil)
        {
          [textStorage addAttribute: NSBackgroundColorAttributeName
                              value: previousBGColor
                              range: r];
        }
      else
        {
          [textStorage removeAttribute: NSBackgroundColorAttributeName
                                 range: r];
        }

      [textStorage endEditing];
    }
}

- (void) highlightCharacterAt: (unsigned int) location
{
  if (isCharacterHighlit == NO)
    {
      NSTextStorage * textStorage = [textView textStorage];
      NSRange r = NSMakeRange(location, 1);
      NSRange tmp;

      highlitCharacterLocation = location;

      isCharacterHighlit = YES;

      [textStorage beginEditing];

      // store the previous character's attributes
      ASSIGN(previousFGColor,
        [textStorage attribute: NSForegroundColorAttributeName
                       atIndex: location
                effectiveRange: &tmp]);
      ASSIGN(previousBGColor,
        [textStorage attribute: NSBackgroundColorAttributeName
                       atIndex: location
                effectiveRange: &tmp]);
      ASSIGN(previousFont, [textStorage attribute: NSFontAttributeName
                                          atIndex: location
                                   effectiveRange: &tmp]);

      [textStorage addAttribute: NSFontAttributeName
                          value: highlightFont
                          range: r];
      [textStorage addAttribute: NSForegroundColorAttributeName
                          value: highlightColor
                          range: r];

      [textStorage removeAttribute: NSBackgroundColorAttributeName
                             range: r];

      [textStorage endEditing];
    }
}

- (void) computeNewParenthesisNesting
{
  NSRange selectedRange;
  NSString * myString;

  if ([[NSUserDefaults standardUserDefaults] boolForKey: @"DontTrackNesting"])
    {
      return;
    }

  selectedRange = [textView selectedRange];

  // make sure we un-highlight a previously highlit delimiter
  [self unhighlightCharacter];

  // if we have a character at the selected location, check
  // to see if it is a delimiter character
  myString = [textView string];
  if (selectedRange.length <= 1 && [myString length] > selectedRange.location)
    {
      unichar c;
      // we must initialize these explicitly in order to make
      // gcc shut up about flow control
      unichar oppositeDelimiter = 0;
      BOOL searchBackwards = NO;

      c = [myString characterAtIndex: selectedRange.location];

      // if it is, search for the opposite delimiter in a range
      // of at most 1000 characters around it in either forward
      // or backward direction (depends on the kind of delimiter
      // we're searching for).
      if (CheckDelimiter(c, &oppositeDelimiter, &searchBackwards))
        {
          unsigned int result;

          result = FindDelimiterInString(myString,
                                         oppositeDelimiter,
                                         c,
                                         selectedRange.location,
                                         searchBackwards);

          // and in case a delimiter is found, highlight it
          if (result != NSNotFound)
            {
              [self highlightCharacterAt: result];
            }
        }
    }
}



- (void)goToLine:sender
{
/*  LineQueryPanel * lqp = [LineQueryPanel shared];

  if ([lqp runModal] == NSOKButton)
    {
      [self goToLineNumber: (unsigned int) [lqp unsignedIntValue]];
    }*/
}

- (void)goToLineNumber:(unsigned int)lineNumber
{
/*  unsigned int offset;
  unsigned int i;
  NSString * line;
  NSEnumerator * e;
  NSArray * lines = [[textView string] componentsSeparatedByString: @"\n"];
  e = [lines objectEnumerator];
  NSRange r;

  for (offset = 0, i=1;
       (line = [e nextObject]) != nil && i < lineNumber;
       i++, offset += [line length] + 1);

  if (line != nil)
    {
      r = NSMakeRange(offset, [line length]);
    }
  else
    {
      r = NSMakeRange([[textView string] length], 0);
    }
  [textView setSelectedRange: r];
  [textView scrollRangeToVisible: r];*/
}

- (void)textViewDidChangeSelection:(NSNotification *)notification
{
  if (editorTextViewIsPressingKey == NO)
    {
      [self computeNewParenthesisNesting];
    }
  [(EditorRulerView *) [[textView enclosingScrollView] horizontalRulerView]
    refreshHighlightedArea];
  [(EditorRulerView *) [[textView enclosingScrollView] verticalRulerView]
    refreshHighlightedArea];
}

- (void) textDidChange: (NSNotification *) notif
{

  if (![self isDocumentEdited])
    {
      [self updateMiniwindowIconToEdited: YES];
    }

  [self updateChangeCount: NSChangeDone];
}

- (void) editorTextViewWillPressKey: sender
{
  editorTextViewIsPressingKey = YES;

  [self unhighlightCharacter];
}

- (void) editorTextViewDidPressKey: sender
{
  [self computeNewParenthesisNesting];

  editorTextViewIsPressingKey = NO;
}

- (void) findNext: sender
{
  [[TextFinder sharedInstance] findNext: self];
}

- (void) findPrevious: sender
{
  [[TextFinder sharedInstance] findPrevious: self];
}

- (void) jumpToSelection: sender
{
  [textView scrollRangeToVisible: [textView selectedRange]];
}

@end

