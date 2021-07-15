/*
**  GDBWrapper.m
**
**  Copyright (c) 2008-2021 Free Software Foundation
**
**  Author: Gregory Casamento <greg.casamento@gmail.com>
**          Riccardo Mottola <rm@gnu.org>
**
**  This program is free software; you can redistribute it and/or modify
**  it under the terms of the GNU General Public License as published by
**  the Free Software Foundation; either version 2 of the License, or
**  (at your option) any later version.
**
**  This program is distributed in the hope that it will be useful,
**  but WITHOUT ANY WARRANTY; without even the implied warranty of
**  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
**  GNU General Public License for more details.
**
**  You should have received a copy of the GNU General Public License
**  along with this program; if not, write to the Free Software
**  Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
*/



#include <sys/stat.h>
#include <signal.h>

#include <stdio.h> /* for stderr and perror*/
#include <errno.h> /* for int errno */
#include <fcntl.h>
#include <sys/types.h>

#include <unistd.h>
#include <stdlib.h>
#include <string.h>

#import "GDBWrapper.h"
#import "PCDebugger.h"

#ifndef NOTIFICATION_CENTER
#define NOTIFICATION_CENTER [NSNotificationCenter defaultCenter]
#endif

@implementation GDBWrapper


- (id)init
{
  if ((self = [super init]))
    {
      userInputColor = [[NSColor blueColor] retain];
      debuggerColor = [[NSColor blackColor] retain];
      messageColor = [[NSColor brownColor] retain];
      errorColor = [[NSColor redColor] retain];
      promptColor = [[NSColor purpleColor] retain];
      
      debuggerStarted = NO;
      debuggerVersion = 0.0;
    }
  return self;
}

- (NSTextView *)textView
{
  return tView;
}

- (void)setTextView: (NSTextView *)tv
{
  if (tView != tv)
    {
      [tView release];
      tView = tv;
      [tView retain];
    }
}

- (PCDebugger *)debugger
{
  return debugger;
}
  
- (void)setDebugger:(PCDebugger *)dbg
{
  if (debugger != dbg)
    {
      [debugger release];
      debugger = dbg;
      [debugger retain];
    }
}

- (BOOL)debuggerStarted
{
  return debuggerStarted;
}

- (void)setFont:(NSFont *)aFont
{
  if (font != aFont)
    {
      [font release];
      font = aFont;
      [font retain];
    }
}


- (NSColor *)userInputColor
{
  return userInputColor;
}

- (NSColor *)debuggerColor
{
  return debuggerColor;
}

- (NSColor *)messageColor
{
  return messageColor;
}

- (NSColor *)errorColor
{
  return errorColor;
}

- (float) debuggerVersion
{
  return debuggerVersion;
}

- (void) setDebuggerVersion:(float)ver
{
  debuggerVersion = ver;
}

/**
 * Log string to the view.
 */
- (void) logString:(NSString *)str
	   newLine:(BOOL)newLine
         withColor:(NSColor *)color
{
  NSMutableDictionary *textAttributes;
  NSAttributedString *attrStr;


  if (newLine)
    {
      str = [str stringByAppendingString:@"\n"];
    }

  textAttributes = [NSMutableDictionary dictionary];
  [textAttributes setObject:font forKey:NSFontAttributeName];
  if (color)
    {

      [textAttributes  setObject:color forKey:NSForegroundColorAttributeName];
    }

  attrStr = [[NSAttributedString alloc] initWithString: str
                                            attributes: textAttributes];
  
  [[tView textStorage] appendAttributedString: attrStr];
  [attrStr release];


  [tView scrollRangeToVisible:NSMakeRange([[tView string] length], 0)];
  [tView setNeedsDisplay:YES];
}

/* == parsing methods == */

- (NSString *) parseString: (NSScanner *)scanner
{
  NSString *str;

  [scanner scanString: @"\"" intoString: NULL];
  [scanner scanUpToString: @"\"" intoString: &str];
  [scanner scanString: @"\"" intoString: NULL];

  return str;
}

- (NSArray *) parseArray: (NSScanner *)scanner
{
  NSMutableArray *mArray;
  id value;
  NSString *string = [scanner string];
  BOOL elementEnd;

  //  NSLog(@"parseArray in: %@", [string substringFromIndex: [scanner scanLocation]]);
  mArray = [[NSMutableArray alloc] init];

  // we chomp up the first opening [
  if (![scanner isAtEnd])
    [scanner scanString: @"[" intoString: NULL];

  elementEnd = NO;
  value = nil;
  while([scanner isAtEnd] == NO  && elementEnd == NO)
    {
      if ([string characterAtIndex:[scanner scanLocation]] == '\"')
	{
	  value = [self parseString: scanner];
	}
      else if ([string characterAtIndex:[scanner scanLocation]] == '{')
	{
	  value = [self parseKeyValue: scanner];
	}
      else if ([string characterAtIndex:[scanner scanLocation]] == ']')
	{
	  [scanner scanString: @"]" intoString: NULL];
	  elementEnd = YES;
	}

      if (![scanner isAtEnd] && [string characterAtIndex:[scanner scanLocation]] == ',')
	{
	  [scanner scanString: @"," intoString: NULL];
	}

      //      NSLog(@"Array Element: %@", value);
      if (value)
	{
	  [mArray addObject: value];
	}
    }
  return [mArray autorelease];
}

/*
 parse subpart of the MI reply which may look like this:
 bkpt={number="1",type="breakpoint",disp="keep",enabled="y",addr="0x0804872c",func="main",file="main.m",fullname="/home/multix/code/gnustep-svc/DirectoryTest/main.m",line="23",thread-groups=["i1"],times="1",original-location="main.m:23"}
 */
- (NSDictionary *) parseKeyValue: (NSScanner *)scanner
{
  NSMutableDictionary *mdict;
  NSString *key = NULL;
  id value;
  NSString *string = [scanner string];
  BOOL elementEnd;

  //  NSLog(@"scanning KV: %@", [[scanner string] substringFromIndex:[scanner scanLocation]]);
  mdict = [[NSMutableDictionary alloc] init];

  value = nil;
  elementEnd = NO;

  // we chomp up the first opening { which may not be always present
  if (![scanner isAtEnd])
    [scanner scanString: @"{" intoString: NULL];

  while([scanner isAtEnd] == NO && elementEnd == NO)
    {
      [scanner scanUpToString: @"=" intoString: &key];
      [scanner scanString: @"=" intoString: NULL];
      //      NSLog(@"KV key found: %@", key);
      if ([string characterAtIndex:[scanner scanLocation]] == '\"')
	{
	  value = [self parseString: scanner];
	}
      else if ([string characterAtIndex:[scanner scanLocation]] == '[')
	{
	  value = [self parseArray: scanner];
	}
      else if ([string characterAtIndex:[scanner scanLocation]] == '{')
	{
	  value = [self parseKeyValue: scanner];
	}

      if (![scanner isAtEnd] && [string characterAtIndex:[scanner scanLocation]] == '}')
	{
	  [scanner scanString: @"}" intoString: NULL];
	  elementEnd = YES;
	}

      if (![scanner isAtEnd] && [string characterAtIndex:[scanner scanLocation]] == ',')
	{
	  [scanner scanString: @"," intoString: NULL];
	}

      if (key != nil && value != nil)
	[mdict setObject:value forKey:key];
    }
  return [mdict autorelease];
}

/*
  Parses a line coming from the debugger. It could be eiher a standard output or it may come from the machine
  interface of gdb.
 */
- (PCDebuggerOutputTypes) parseStringLine: (NSString *)stringInput
{
  NSScanner *stringScanner;
  NSString *prefix = NULL;

  if ([stringInput length] == 0)
    return PCDBEmptyRecord;

  stringScanner = [NSScanner scannerWithString: stringInput];

  NSLog(@"parsing: |%@|", stringInput);
  [stringScanner scanString: @"(gdb)" intoString: &prefix];
  if(prefix != nil)
    {
      if(debuggerStarted == NO)
	{
	  [NOTIFICATION_CENTER postNotificationName:PCDBDebuggerStartedNotification
	   object: nil];
	  debuggerStarted = YES;
	}
      return PCDBPromptRecord;
    }

  [stringScanner scanString: @"=" intoString: &prefix];
  if(prefix != nil)
    {
      NSString *dictionaryName = NULL;

      NSLog(@"scanning AsyncInfo |%@|", stringInput);
      
      [stringScanner scanUpToString: @"," intoString: &dictionaryName];

      if(dictionaryName != nil)
	{
	  id value = nil;
	  NSDictionary *dict;
	  
	  [stringScanner scanString: @"," intoString: NULL];
	  dict = [self parseKeyValue: stringScanner];
	  NSLog(@"type %@ value %@", dictionaryName, dict);

	  if([dict objectForKey:@"pid"] != nil && 
	     [dictionaryName isEqualToString: @"thread-group-started"])
	    {
	      [debugger setSubProcessId: [[dict objectForKey:@"pid"] intValue]];
	    }
	  else if ([dict objectForKey:@"bkpt"] != nil)
	    {
	      NSDictionary *bkpDict;
	      // gdb specific
	      NSString *fileName;
	      NSString *lineNum;

	      bkpDict = [value objectForKey:@"bkpt"];
	      fileName = [bkpDict objectForKey:@"fullname"];
	      lineNum = [bkpDict objectForKey:@"line"];
	      NSLog(@"parsed from GDB bkpt: %@:%@", fileName, lineNum);
	      if (fileName != nil && lineNum != nil)
		{
		  [debugger setLastFileNameParsed: fileName];
		  [debugger setLastLineNumberParsed: [lineNum intValue]];
		}
	      else
		{
		  [debugger setLastFileNameParsed: nil];
		  [debugger setLastLineNumberParsed: NSNotFound];
		}
	    }
	}
      else
	{
	  NSLog(@"error parsing type of: %@", stringInput);
	}
      return PCDBAsyncInfoRecord;
    }

  [stringScanner scanString: @"*" intoString: &prefix];
  if(prefix != nil)
    {
      NSString *dictionaryName = NULL;
      NSDictionary *dict = nil;

      NSLog(@"scanning AsyncStatus |%@|", stringInput);
      
      [stringScanner scanUpToString: @"," intoString: &dictionaryName];

      if(dictionaryName != nil)
	{
	  [stringScanner scanString: @"," intoString: NULL];
	  dict = [self parseKeyValue: stringScanner];
	  NSLog(@"type %@ value %@", dictionaryName, dict);
	}

      if ([dictionaryName isEqualToString:@"stopped"])
	{
	  [debugger setStatus:@"Stopped"];
	  if ([dict objectForKey:@"reason"] != nil)
	    {
	      NSDictionary *frameDict;
	      NSString *fileName;
	      NSString *lineNum;

	      frameDict = [dict objectForKey:@"frame"];
	      fileName = [frameDict objectForKey:@"fullname"];
	      lineNum = [frameDict objectForKey:@"line"];
	      NSLog(@"parsed from GDB %@ : %@:%@", [dict objectForKey:@"reason"], fileName, lineNum);
	      if (fileName != nil && lineNum != nil)
		{
		  [debugger setLastFileNameParsed: fileName];
		  [debugger setLastLineNumberParsed: [lineNum intValue]];
		}
	      else
		{
		  [debugger setLastFileNameParsed: nil];
		  [debugger setLastLineNumberParsed: NSNotFound];
		}
	      [debugger updateEditor];
	    }
	}
      return PCDBAsyncStatusRecord;
    }

  [stringScanner scanString: @"<-" intoString: &prefix];
  if(prefix != nil)
    {
      return PCDBBreakpointRecord;
    }
  
  [stringScanner scanString: @"->" intoString: &prefix];
  if(prefix != nil)
    {
      return PCDBBreakpointRecord;
    }

  [stringScanner scanString: @"~" intoString: &prefix];
  if(prefix != nil)
    {
      if (debuggerVersion == 0.0)
        {
          NSString *str1 = nil;
          NSString *str2 = nil;
          
          [stringScanner scanString: @"\"GNU gdb" intoString: &str1];
          if (str1 != nil)
            {
              [stringScanner scanString: @" (GDB)" intoString: &str2];
            }

          if (str2 != nil || str1 != nil)
            {
              float v;

              if ([stringScanner scanFloat:&v])
                {
                  NSLog(@"GDB version string: %f", v);
                  [self setDebuggerVersion:v];
                }
            }
        }
      if ((debuggerVersion < 7) && [debugger subProcessId] == 0)
        {
          NSString *str1;
          // we attempt to parse: [New thread 6800.0x18ec]
          [stringScanner scanString: @"\"[New thread" intoString: &str1];
          if (str1 != nil)
            {
              int v;
              if([stringScanner scanInt:&v])
                {
                  NSLog(@"sub process id: %d", v);
                  [debugger setSubProcessId:v];
                }
            }
        }
      return PCDBConsoleStreamRecord;
    }

  [stringScanner scanString: @"@" intoString: &prefix];
  if(prefix != nil)
    {
      return PCDBTargetStreamRecord;
    }

  [stringScanner scanString: @"&" intoString: &prefix];
  if(prefix != nil)
    {
      return PCDBDebugStreamRecord;
    }

  [stringScanner scanString: @"^" intoString: &prefix];
  if(prefix != nil)
    {
      NSString *result = nil;
      
      [stringScanner scanString: @"done" intoString: &result];
      if(result != nil)
	{
	  [debugger setStatus: @"Done"];
	  return PCDBResultRecord;
	}
      [stringScanner scanString: @"running" intoString: &result];
      if(result != nil)
	{
	  [debugger setStatus: @"Running"];
	  return PCDBResultRecord;
	}
      [stringScanner scanString: @"connected" intoString: &result];
      if(result != nil)
	{
	  [debugger setStatus: @"Connected"];
	  return PCDBResultRecord;
	}
      [stringScanner scanString: @"error" intoString: &result];
      if(result != nil)
	{
	  [debugger setStatus: @"Error"];
	  return PCDBResultRecord;
	}
      [stringScanner scanString: @"exit" intoString: &result];
      if(result != nil)
	{
	  [debugger setStatus: @"Exit"];
	  return PCDBResultRecord;
	}
      return PCDBResultRecord;
    }
  NSLog(@"No match found parsing: |%@|", stringInput);
  return PCDBNotFoundRecord;
}

- (NSString *)unescapeOutputRecord: (NSString *)recordString
{
  NSString *unescapedString = [recordString copy];

  if ([unescapedString hasPrefix:@"~\""])
    unescapedString = [unescapedString substringFromIndex:2];
  if ([unescapedString hasSuffix:@"\""])\
    unescapedString = [unescapedString substringToIndex: [unescapedString length] - 1];
  unescapedString = [unescapedString stringByReplacingOccurrencesOfString: @"\\\"" withString: @"\""];
  unescapedString = [unescapedString stringByReplacingOccurrencesOfString: @"\\n" withString: @"\n"];
  unescapedString = [unescapedString stringByReplacingOccurrencesOfString: @"\\t" withString: @"\t"];
  unescapedString = [unescapedString stringByReplacingOccurrencesOfString: @"\\032" withString: @" "];

  return unescapedString;
}

- (void) parseLine: (NSString *)inputString
{
  NSArray *components;
  NSEnumerator *en;
  NSString *item = nil;

#if defined(__MINGW32__)
  components = [inputString componentsSeparatedByString:@"\r\n"];
#else
  components = [inputString componentsSeparatedByString:@"\n"];
#endif
  en = [components objectEnumerator];
 
  while((item = [en nextObject]) != nil) 
    {
      PCDebuggerOutputTypes outtype = [self parseStringLine: item];
      if(outtype == PCDBConsoleStreamRecord || 
	 outtype == PCDBTargetStreamRecord) 
	{
	  NSString *unescapedString = [self unescapeOutputRecord: item];
	  [self logString: unescapedString newLine: NO withColor:debuggerColor];
	}
      else if(outtype == PCDBPromptRecord)
	{
	  [self logString: item newLine: NO withColor:promptColor];
	}
      /*
      else if(outtype == PCDBNotFoundRecord)
	{
	  [self logString: item newLine: NO withColor:promptColor];
	}
      */
    }
}

/* == end of parsing methods */

/**
 * Log standard out.
 */ 
- (void) logStdOut:(NSNotification *)aNotif
{
  NSData *data;
  NSFileHandle *handle = stdoutHandle;

  if ((data = [handle availableData]) && [data length] > 0)
    {
      NSString *dataString;
      dataString = [[NSString alloc] 
                     initWithData:data 
                         encoding:[NSString defaultCStringEncoding]];
      
      // if( !
      [self parseLine: dataString]; // )
    // {
    //	  [self logString: dataString newLine: NO withColor:debuggerColor];
    //	}
      RELEASE(dataString);
    }
  
  if (task)
    {
      [handle waitForDataInBackgroundAndNotify];
    }
  else
    {
      [NOTIFICATION_CENTER removeObserver: self 
			   name: NSFileHandleDataAvailableNotification
			   object: handle];
    }
}

/**
 * Log error out.
 */ 
- (void) logErrOut:(NSNotification *)aNotif
{
  NSData *data;
  NSFileHandle *handle = error_handle;

  if ((data = [handle availableData]) && [data length] > 0)
    {
      NSString *dataString;
  
      dataString = [[NSString alloc] 
                     initWithData:data
                         encoding:[NSString defaultCStringEncoding]];

      // if(![self parseString: dataString])
	{
	  [self logString: dataString newLine: NO withColor:errorColor];
	}
      RELEASE(dataString);
    }

  if (task)
    {
      [handle waitForDataInBackgroundAndNotify];
    }
  else
    {
      [NOTIFICATION_CENTER removeObserver:self 
			   name: NSFileHandleDataAvailableNotification
			   object: handle];
    }
}

/**
 * Notified when the task is completed.
 */
- (void) taskDidTerminate: (NSNotification *)notif
{
  NSLog(@"Task Terminated...");
  [self logString: [self stopMessage]
	newLine:YES
        withColor:messageColor];
}

/**
 * Message to print when the task starts
 */
- (NSString *) startMessage
{
  return @"=== Task Started ===";
}

/**
 * Message to print when the task stops
 */
- (NSString *) stopMessage
{
  return @"\n=== Task Stopped ===";
}

/**
 * Start the program.
 */
- (void) runProgram: (NSString *)path
 inCurrentDirectory: (NSString *)directory
      withArguments: (NSArray *)array
   logStandardError: (BOOL)logError
{
  NSPipe *inPipe;
  NSPipe *outPipe;
  
  task = [[NSTask alloc] init];
  [task setArguments: array];
  [task setCurrentDirectoryPath: directory];
  [task setLaunchPath: path];

  inPipe = [NSPipe pipe];
  outPipe = [NSPipe pipe];
  stdinHandle = [[inPipe fileHandleForWriting] retain];
  stdoutHandle = [[outPipe fileHandleForReading] retain];
  [task setStandardOutput: outPipe];
  [task setStandardInput: inPipe];

  [stdoutHandle waitForDataInBackgroundAndNotify];

  // Log standard error, if requested.
  if(logError)
    {
      [task setStandardError: [NSPipe pipe]];
      error_handle = [[task standardError] fileHandleForReading];
      [error_handle waitForDataInBackgroundAndNotify];

      [NOTIFICATION_CENTER addObserver:self 
			      selector:@selector(logErrOut:)
				  name:NSFileHandleDataAvailableNotification
				object:error_handle];
    }

  // set up notifications to get data.
  [NOTIFICATION_CENTER addObserver:self 
			  selector:@selector(logStdOut:)
			      name:NSFileHandleDataAvailableNotification
			    object:stdoutHandle];


  [NOTIFICATION_CENTER addObserver:self 
			  selector:@selector(taskDidTerminate:) 
			      name:NSTaskDidTerminateNotification
			    object:task];

  // run the task...
  NS_DURING
    {
      [self logString: [self startMessage]
	      newLine:YES
            withColor:messageColor];
      [task launch];
    }
  NS_HANDLER
    {
      NSRunAlertPanel(@"Problem Launching Debugger",
		      [localException reason],
		      @"OK", nil, nil, nil);
	      
	      
      NSLog(@"Task Terminated Unexpectedly...");
      [self logString: @"\n=== Task Terminated Unexpectedly ===\n" 
	      newLine:NO
            withColor:messageColor];      
	      
      //Clean up after task is terminated
      [[NSNotificationCenter defaultCenter] 
		postNotificationName: NSTaskDidTerminateNotification
			      object: task];
    }
  NS_ENDHANDLER

}

- (void) terminate
{
  if(task)
    {
      [task terminate];
    }
}

- (void) dealloc
{
  [NOTIFICATION_CENTER removeObserver: self]; 
  [self terminate];
  [userInputColor release];
  [debuggerColor release];
  [messageColor release];
  [errorColor release];
  [debugger release];
  [tView release];
  [super dealloc];
}

- (void) putString: (NSString *)string;
{
  unichar *str = (unichar *)[string cStringUsingEncoding: [NSString defaultCStringEncoding]];
  int len = strlen((char *)str);
  NSData *data = [NSData dataWithBytes: str length: len];
  [stdinHandle writeData: data];
  [stdinHandle synchronizeFile];
}

/* for input as typed from the user */
- (void) typeString: (NSString *)string
{
  NSUInteger strLen;

  strLen = [string length];
  [self putString:string];

  // if we have a single backspace or delete character
  if (strLen == 1 && [string characterAtIndex:strLen-1] == '\177')
    {
      NSUInteger textLen;

      textLen = [[tView string] length];
      [tView setSelectedRange:NSMakeRange(textLen-1, 1)];
      [tView delete:nil];
      return;
    }
  
  [self logString:string newLine:NO withColor:userInputColor];
}

/**
 * Put a single character into the stream.
 */
- (void) putChar:(unichar)ch
{
  NSData *data = [NSData dataWithBytes: &ch length: 1];
  [stdinHandle writeData: data];
} 

- (void) interrupt
{
  [task interrupt];
}

/** 
 * Respond to key events and pipe them down to the debugger 
 */ 
- (void) keyDown: (NSEvent*)theEvent
{
    NSString *chars;

    chars = [theEvent characters];
    if ([chars length] == 0)
      {
      }
    else if ([chars length] == 1)
      {
        unichar c;
        c = [chars characterAtIndex: 0];
        //NSLog(@"char: %d", c);

	if (c == 3) // ETX, Control-C
	  {
	    [self interrupt];  // send the interrupt signal to the subtask
	  }
        else if (c == 13) // CR
          {
            [self typeString: @"\n"];
          }
	else if (c == 127) // del (usually backspace)
          {
	    NSString *tss = [[tView textStorage] string];
	    if (![tss hasSuffix:@"\n"] && ![tss hasSuffix:@"(gdb) "])
	      {
		chars = @"\x08";
		[self typeString: chars];
	      }
          }
	else
	  {
	    [self typeString: chars];
	  }
      }
    else
      NSLog(@"characters: |%@|", chars);
}

- (void) setBreakpoints:(NSArray *)breakpoints
{
  NSDictionary *bp;
  NSEnumerator *e;
  
  // TODO
  e = [breakpoints objectEnumerator];
  while ((bp = [e nextObject]))
    {
      NSString *bpType;
      NSString *bpString;

      bpType = [bp objectForKey:PCBreakTypeKey];
      bpString = nil;
      if ([bpType isEqualToString:PCBreakTypeByLine])
        {
          NSString *fileName;
          NSNumber *lineNumber;

          fileName = [bp objectForKey:PCBreakFilename];
          lineNumber = [bp objectForKey:PCBreakLineNumber];
	  bpString = [NSString stringWithFormat:@"-break-insert -f %@:%@\n", fileName, lineNumber];
        }
      else if ([bpType isEqualToString:PCBreakTypeMethod])
        {
          NSString *methodName;

          methodName = [bp objectForKey:PCBreakMethod];
          bpString = [NSString stringWithFormat:@"-interpreter-exec console \"break %@\"\n", methodName];
        }
      else
        {
          NSLog(@"Unknown breakpoint type: %@", bpType);
        }
      if (bpString)
	{
	  NSString *command;

	  /* TODO: split into a separate insert function */
	  command = bpString;
	  NSLog(@"gdb mi command is: %@", command);
	  [self putString: command];
	}
    }
}

- (void) debuggerSetup
{
  NSString *command = @"set confirm off\n";
  
  [self putString: command];
}
@end
