/* 
 * PCTextFinder.m created by probert on 2002-02-03 13:22:59 +0000
 *
 * Project ProjectCenter
 *
 * Created with ProjectCenter - http://www.gnustep.org
 *
 * $Id$
 */

/*
 * This code is heavily based on Ali Ozers TextFinder. All credits belong
 * to Ali!
 *
 */

#include "PCTextFinder.h"
#include "PCDefines.h"

#include "PCTextFinder+UInterface.h"

#define Forward YES
#define Backward NO

#define ReplaceAllScopeEntireFile 42
#define ReplaceAllScopeSelection 43

@interface NSString (NSStringTextFinding)

- (NSRange)findString:(NSString *)string 
        selectedRange:(NSRange)selectedRange 
	      options:(unsigned)options 
	         wrap:(BOOL)wrap;

@end

@implementation NSString (NSStringTextFinding)

- (NSRange)findString:(NSString *)string 
        selectedRange:(NSRange)selectedRange 
	      options:(unsigned)options 
	         wrap:(BOOL)wrap
{
    BOOL forwards = (options & NSBackwardsSearch) == 0;
    unsigned length = [self length];
    NSRange searchRange, range;

    if (forwards) 
    {
        searchRange.location = NSMaxRange(selectedRange);
        searchRange.length = length - searchRange.location;
        range = [self rangeOfString:string options:options range:searchRange];

        if ((range.length == 0) && wrap) 
	{
            searchRange.location = 0;
            searchRange.length = selectedRange.location;
            range=[self rangeOfString:string options:options range:searchRange];
        }
    } 
    else 
    {
        searchRange.location = 0;
        searchRange.length = selectedRange.location;
        range = [self rangeOfString:string options:options range:searchRange];

        if ((range.length == 0) && wrap) 
	{
            searchRange.location = NSMaxRange(selectedRange);
            searchRange.length = length - searchRange.location;
            range=[self rangeOfString:string options:options range:searchRange];
        }
    }
    return range;
}

@end

@implementation PCTextFinder

static PCTextFinder *_finder = nil;

+ (PCTextFinder*)sharedFinder
{
    if( _finder == nil )
    {
        _finder = [[PCTextFinder alloc] init];
    }

    return _finder;
}

- (id)init
{
    if((self = [super init]))
    {
	shouldReplaceAll = YES;
        shouldIgnoreCase = YES;

        [self setFindString:@""];
	[self loadFindStringFromPasteboard];
    }
    return self;
}

- (void)dealloc
{
    if( panel != nil )
    {
        RELEASE(panel);
    }

    [super dealloc];
}

- (NSPanel *)findPanel
{
    if( panel == nil )
    {
        [self _initUI];
    }

    return panel;
}

- (void)showFindPanel:(id)sender
{
    if( panel == nil )
    {
        [self _initUI];
    }

    [panel orderFront:self];
}

- (void)buttonPressed:(id)sender
{
    switch([[sender selectedCell] tag] )
    {
        case 0:
	    [self replaceAll:sender];
	    break;
        case 1:
	    [self replace:sender];
	    break;
        case 2:
	    [self findPrevious:sender];
	    break;
        case 3:
	    [self findNext:sender];
	    break;
    }
}

- (void)setReplaceAllScope:(id)sender
{
    switch([[sender selectedCell] tag] )
    {
        case 0:
	    shouldReplaceAll = YES;
	    break;
        case 1:
	    shouldReplaceAll = NO;
	    break;
    }
}

- (void)setIgnoreCase:(id)sender
{
    if( [ignoreCaseButton state] )
    {
        shouldIgnoreCase = YES;
    }
    else
    {
        shouldIgnoreCase = NO;
    }
}

- (BOOL)find:(BOOL)direction
{
    NSTextView *text = [self textObjectToSearchIn];
    lastFindWasSuccessful = NO;

    if (text) 
    {
        NSString *textContents = [text string];
        unsigned textLength;

        if (textContents && (textLength = [textContents length])) 
        {
            NSRange range;
            unsigned options = 0;

            if (direction == Backward) options |= NSBackwardsSearch;
            if (shouldIgnoreCase) options |= NSCaseInsensitiveSearch;

            range = [textContents findString:[self findString] 
                               selectedRange:[text selectedRange] 
                                     options:options 
                                        wrap:YES];

            if (range.length) 
            {
                [text setSelectedRange:range];
                [text scrollRangeToVisible:range];
                lastFindWasSuccessful = YES;
            }
        }
    }

    if (!lastFindWasSuccessful) 
    {
        NSBeep();

        [statusField setStringValue:@"Not found"];
    } 
    else 
    {
        [statusField setStringValue:@""];
    }

    return lastFindWasSuccessful;
}

- (NSTextView *)textObjectToSearchIn
{
    id obj = [[NSApp mainWindow] firstResponder];
    return (obj && [obj isKindOfClass:[NSTextView class]]) ? obj : nil;
}

- (NSString *)findString
{
    return findString;
}

- (void)setFindString:(NSString *)string
{
    if ([string isEqualToString:findString]) return;

    AUTORELEASE(findString);
    findString = [string copyWithZone:[self zone]];

    if (findTextField) 
    {
        [findTextField setStringValue:string];
        [findTextField selectText:nil];
    }
    findStringChangedSinceLastPasteboardUpdate = YES;
}
    
- (void)loadFindStringFromPasteboard
{
    NSPasteboard *pasteboard = [NSPasteboard pasteboardWithName:NSFindPboard];

    if ([[pasteboard types] containsObject:NSStringPboardType]) 
    {
        NSString *string = [pasteboard stringForType:NSStringPboardType];

        if (string && [string length]) 
	{
            [self setFindString:string];
            findStringChangedSinceLastPasteboardUpdate = NO;
        }
    }
}

- (void)loadFindStringToPasteboard
{
    NSPasteboard *pasteboard = [NSPasteboard pasteboardWithName:NSFindPboard];

    if (findStringChangedSinceLastPasteboardUpdate) 
    {
        [pasteboard declareTypes:[NSArray arrayWithObject:NSStringPboardType] 
	                   owner:nil];
        [pasteboard setString:[self findString] forType:NSStringPboardType];

        findStringChangedSinceLastPasteboardUpdate = NO;
    }
}


- (void)findNext:(id)sender
{
    if (findTextField) 
    {
        [self setFindString:[findTextField stringValue]];        
    }

    [self find:Forward];
}

- (void)findPrevious:(id)sender
{
    if (findTextField) 
    {
        [self setFindString:[findTextField stringValue]];        
    }

    [self find:Backward];
}

- (void)findNextAndOrderFindPanelOut:(id)sender;
{
}

- (void)replace:(id)sender
{
    NSTextView *text = [self textObjectToSearchIn];

    if (!text) 
    {
        NSBeep();
	[statusField setStringValue:@"No text!"];
    } 
    else 
    {
        [[text textStorage] replaceCharactersInRange:[text selectedRange] 
                                          withString:[replaceTextField stringValue]];
        [text didChangeText];
    }

    [statusField setStringValue:@""];
}

- (void)replaceAll:(id)sender;
{
    NSTextView *text = [self textObjectToSearchIn];

    if (!text) 
    {
        NSBeep();
    } 
    else 
    {
        NSTextStorage *textStorage = [text textStorage];
        NSString *textContents = [text string];
        NSString *replaceString = [replaceTextField stringValue];
        unsigned replaced = 0;
        NSRange replaceRange = shouldReplaceAll 
	                       ? NSMakeRange(0, [textStorage length]) 
			       : [text selectedRange];
        unsigned options = NSBackwardsSearch |
	                   ( shouldIgnoreCase ? NSCaseInsensitiveSearch : 0);

        if (findTextField) [self setFindString:[findTextField stringValue]];

        while (1) 
	{
            NSRange foundRange = [textContents rangeOfString:[self findString] 
	                                             options:options 
						       range:replaceRange];

            if (foundRange.length == 0) 
	    {
	        break;
	    }

            if ([text shouldChangeTextInRange:foundRange replacementString:replaceString]) 
	    {
                if (replaced == 0) 
		{
		    [textStorage beginEditing];
		}

                replaced++;
                [textStorage replaceCharactersInRange:foundRange 
		                           withString:replaceString];
                replaceRange.length = foundRange.location - replaceRange.location;
            }
        }

	// There was at least one replacement
        if (replaced > 0) 
	{     
            [textStorage endEditing];   
            [text didChangeText];       

            [statusField setStringValue:[NSString stringWithFormat:@"%d replaced", replaced]];
        } 
	else 
	{        
            NSBeep();
            [statusField setStringValue:@"Not found"];
        }
    }
}

@end
