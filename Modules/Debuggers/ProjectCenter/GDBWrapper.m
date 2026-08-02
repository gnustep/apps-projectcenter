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
**  Foundation, Inc., 31 Milk Street #960789 Boston, MA 02196 USA
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

#import <ProjectCenter/PCDefines.h>

#ifndef NOTIFICATION_CENTER
#define NOTIFICATION_CENTER [NSNotificationCenter defaultCenter]
#endif

@implementation GDBWrapper


- (id)init
{
  if ((self = [super init]))
    {
      userInputColor = RETAIN([NSColor blueColor]);
      debuggerColor = RETAIN([NSColor blackColor]);
      messageColor = RETAIN([NSColor brownColor]);
      errorColor = RETAIN([NSColor redColor]);
      promptColor = RETAIN([NSColor purpleColor]);
      
      debuggerStarted = NO;
      debuggerVersion = 0.0;
      singleInputLine = [[NSMutableString alloc] init];
      pendingOutput = [[NSMutableString alloc] init];
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
      RELEASE(tView);
      tView = tv;
      RETAIN(tView);
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
      RELEASE(debugger);
      debugger = dbg;
      RETAIN(debugger);
    }
}

- (NSString *)debuggerPath
{
  return debuggerPath;
}

- (void)setDebuggerPath:(NSString *)path
{
  if (debuggerPath != path)
    {
      RELEASE(debuggerPath);
      debuggerPath = path;
      RETAIN(debuggerPath);
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
      RELEASE(font);
      font = aFont;
      RETAIN(font);
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
  RELEASE(attrStr);


  [tView scrollRangeToVisible:NSMakeRange([[tView string] length], 0)];
  [tView setNeedsDisplay:YES];
}

- (void) logPrompt:(NSString *)prompt
{
  NSString *currentString;

  currentString = [tView string];
  if ([currentString hasSuffix:@"(gdb)"] ||
      [currentString hasSuffix:@"(gdb) "])
    {
      [self logString:@"\n" newLine:NO withColor:promptColor];
    }

  [self logString:prompt newLine:NO withColor:promptColor];
}

/* == parsing methods == */

- (NSString *) parseString: (NSScanner *)scanner
{
  NSMutableString *str;
  NSString *string;
  NSUInteger location;
  NSUInteger length;

  [scanner scanString: @"\"" intoString: NULL];
  string = [scanner string];
  location = [scanner scanLocation];
  length = [string length];
  str = [NSMutableString string];

  while (location < length)
    {
      unichar ch = [string characterAtIndex:location++];

      if (ch == '\\' && location < length)
        {
          ch = [string characterAtIndex:location++];
          if (ch == 'n')
            {
              [str appendString:@"\n"];
            }
          else if (ch == 't')
            {
              [str appendString:@"\t"];
            }
          else
            {
              [str appendFormat:@"%C", ch];
            }
        }
      else if (ch == '"')
        {
          break;
        }
      else
        {
          [str appendFormat:@"%C", ch];
        }
    }

  [scanner setScanLocation:location];

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
      value = nil;
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
  return AUTORELEASE(mArray);
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
      key = nil;
      value = nil;
      [scanner scanUpToString: @"=" intoString: &key];
      if (![scanner scanString: @"=" intoString: NULL] || [scanner isAtEnd])
        {
          break;
        }
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
  return AUTORELEASE(mdict);
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

  // notify-async-output
  [stringScanner scanString: @"=" intoString: &prefix];
  if(prefix != nil)
    {
      NSString *dictionaryName = NULL;

      [stringScanner scanUpToString: @"," intoString: &dictionaryName];

      if(dictionaryName != nil)
	{
	  NSDictionary *dict;
	  
	  [stringScanner scanString: @"," intoString: NULL];
	  dict = [self parseKeyValue: stringScanner];
	  ASSIGN(lastMIDictionary, dict);

	  if([dict objectForKey:@"pid"] != nil && 
	     [dictionaryName isEqualToString: @"thread-group-started"])
	    {
	      [debugger setSubProcessId: [[dict objectForKey:@"pid"] intValue]];
	    }
	  else if ([dictionaryName isEqualToString:@"breakpoint-deleted"])
	    {
	      [debugger removeBreakpointNumber:[dict objectForKey:@"id"]];
	    }
	  else if ([dict objectForKey:@"bkpt"] != nil)
	    {
	      NSDictionary *bkpDict;
	      // gdb specific
	      NSString *fileName;
	      NSString *lineNum;
	      NSString *number;

	      bkpDict = [dict objectForKey:@"bkpt"];
	      fileName = [bkpDict objectForKey:@"fullname"];
	      lineNum = [bkpDict objectForKey:@"line"];
	      number = [bkpDict objectForKey:@"number"];
	      if (fileName != nil && lineNum != nil)
		{
		  [debugger recordBreakpointNumber:number
					      file:fileName
					      line:[lineNum intValue]];
		  [debugger setLastFileNameParsed: fileName];
		  [debugger setLastLineNumberParsed: [lineNum intValue]];
		}
	      else
		{
		  [debugger setLastFileNameParsed: nil];
		  [debugger setLastLineNumberParsed: NSNotFound];
		}
	    }

	  if ([dictionaryName isEqualToString: @"thread-selected"])
	    {
	      NSDictionary *d = [dict objectForKey: @"frame"];
	      NSString *fileName;
	      NSString *lineNum;
	      
	      fileName = [d objectForKey:@"fullname"];
	      lineNum = [d objectForKey:@"line"];

	      if (fileName != nil && lineNum != nil)
		{
		  [debugger setLastFileNameParsed: fileName];
		  [debugger setLastLineNumberParsed: [lineNum intValue]];
		  [debugger updateEditor];
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
	}
      return PCDBAsyncNotifyRecord;
    }

  // exec-async-output
  [stringScanner scanString: @"*" intoString: &prefix];
  if(prefix != nil)
    {
      NSString *dictionaryName = NULL;
      NSDictionary *dict = nil;

      [stringScanner scanUpToString: @"," intoString: &dictionaryName];

      if(dictionaryName != nil)
	{
	  [stringScanner scanString: @"," intoString: NULL];
	  dict = [self parseKeyValue: stringScanner];
	  ASSIGN(lastMIDictionary, dict);
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
	      if (fileName != nil && lineNum != nil)
		{
		  [debugger setLastFileNameParsed: fileName];
		  [debugger setLastLineNumberParsed: [lineNum intValue]];
		  [debugger updateEditor];
		}
	      else
		{
		  [debugger setLastFileNameParsed: nil];
		  [debugger setLastLineNumberParsed: NSNotFound];
		}
	    }
	}
      return PCDBAsyncExecRecord;
    }

  // status-async-output
  [stringScanner scanString: @"+" intoString: &prefix];
  if(prefix != nil)
    {
      return PCDBAsyncStatusRecord;
    }

  // console-stream-output
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
                  [debugger setSubProcessId:v];
                }
            }
        }
      return PCDBConsoleStreamRecord;
    }

  // target-stream-output
  [stringScanner scanString: @"@" intoString: &prefix];
  if(prefix != nil)
    {
      ASSIGN(lastMIString, [[stringScanner string] substringFromIndex: [stringScanner scanLocation]]);
      return PCDBTargetStreamRecord;
    }

  // log-stream-output
  [stringScanner scanString: @"&" intoString: &prefix];
  if(prefix != nil)
    {
      ASSIGN(lastMIString, [[stringScanner string] substringFromIndex: [stringScanner scanLocation]]);
      return PCDBLogStreamRecord;
    }

  // result-record
  [stringScanner scanString: @"^" intoString: &prefix];
  if(prefix != nil)
    {
      NSString *result = nil;

      [stringScanner scanString: @"done" intoString: &result];
      if(result != nil)
	{
	  NSDictionary *dict = nil;

	  if (![stringScanner isAtEnd] &&
	      [[stringScanner string] characterAtIndex:[stringScanner scanLocation]] == ',')
	    {
	      [stringScanner scanString:@"," intoString:NULL];
	      dict = [self parseKeyValue:stringScanner];
	      if ([dict objectForKey:@"bkpt"] != nil)
		{
		  NSDictionary *bkpDict;
		  NSString *fileName;
		  NSString *lineNum;
		  NSString *number;

		  bkpDict = [dict objectForKey:@"bkpt"];
		  fileName = [bkpDict objectForKey:@"fullname"];
		  lineNum = [bkpDict objectForKey:@"line"];
		  number = [bkpDict objectForKey:@"number"];
		  if (fileName != nil && lineNum != nil)
		    {
		      [debugger recordBreakpointNumber:number
						  file:fileName
						  line:[lineNum intValue]];
		    }
		}
	    }
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


  [stringScanner scanString: @"<-" intoString: &prefix];
  if(prefix != nil)
    {
      ASSIGN(lastMIString, [[stringScanner string] substringFromIndex: [stringScanner scanLocation]]);
      return PCDBBreakpointRecord;
    }
  
  [stringScanner scanString: @"->" intoString: &prefix];
  if(prefix != nil)
    {
      ASSIGN(lastMIString, [[stringScanner string] substringFromIndex: [stringScanner scanLocation]]);
      return PCDBBreakpointRecord;
    }

  return PCDBNotFoundRecord;
}

- (NSString *)unescapeOutputRecord: (NSString *)recordString
{
  NSString *unescapedString = recordString;

  if ([unescapedString hasPrefix:@"~\""])
    unescapedString = [unescapedString substringFromIndex:2];
  if ([unescapedString hasPrefix:@"@\""] || [unescapedString hasPrefix:@"&\""])
    unescapedString = [unescapedString substringFromIndex:2];
  if ([unescapedString hasSuffix:@"\""])
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
  NSString *item = nil;
  BOOL endsWithNewline;
  unsigned int idx;

  if ([inputString length] == 0)
    {
      return;
    }

  endsWithNewline = [inputString hasSuffix:@"\n"];
  [pendingOutput appendString:inputString];

#if defined(__MINGW32__)
  components = [pendingOutput componentsSeparatedByString:@"\r\n"];
#else
  components = [pendingOutput componentsSeparatedByString:@"\n"];
#endif
  [pendingOutput setString:@""];

  for (idx = 0; idx < [components count]; idx++)
    {
      PCDebuggerOutputTypes outtype;

      item = [components objectAtIndex:idx];
      if ([item length] == 0)
        {
          continue;
        }
      if (!endsWithNewline && idx == [components count] - 1 &&
          ![item hasPrefix:@"(gdb)"])
        {
          [pendingOutput appendString:item];
          continue;
        }
      outtype = [self parseStringLine:item];
      if(outtype == PCDBConsoleStreamRecord || 
	 outtype == PCDBTargetStreamRecord) 
	{
	  NSString *unescapedString = [self unescapeOutputRecord: item];
	  [self logString: unescapedString newLine: NO withColor:debuggerColor];
	}
      else if(outtype == PCDBPromptRecord)
	{
	  [self logPrompt:item];
	}
      else if(outtype == PCDBAsyncStatusRecord ||
	      outtype == PCDBAsyncExecRecord ||
	      outtype == PCDBAsyncNotifyRecord ||
	      outtype == PCDBResultRecord ||
	      outtype == PCDBBreakpointRecord)
	{
	  /* MI bookkeeping records are parsed for state, but kept out of the user console. */
	}
      else if(outtype == PCDBLogStreamRecord)
	{
	  /* gdb log-stream records are internal command/status chatter. */
	}
      else if(outtype == PCDBNotFoundRecord)
	{
	  [self logString: item newLine: NO withColor:errorColor];
	}
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
  NSFileHandle *handle = errorHandle;

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
   logStandardError: (BOOL)logError
{
  NSPipe *inPipe;
  NSPipe *outPipe;
  NSArray *argArray;

  argArray = [[NSArray alloc] initWithObjects: @"--interpreter=mi", @"-f", path, nil];
  
  task = [[NSTask alloc] init];
  [task setArguments: argArray];
  RELEASE(argArray);
  [task setCurrentDirectoryPath: directory];
  [task setLaunchPath: debuggerPath];

  inPipe = [NSPipe pipe];
  outPipe = [NSPipe pipe];
  stdinHandle = RETAIN([inPipe fileHandleForWriting]);
  stdoutHandle = RETAIN([outPipe fileHandleForReading]);
  [task setStandardOutput: outPipe];
  [task setStandardInput: inPipe];

  [stdoutHandle waitForDataInBackgroundAndNotify];

  // Log standard error, if requested.
  if(logError)
    {
      [task setStandardError: [NSPipe pipe]];
      errorHandle = [[task standardError] fileHandleForReading];
      [errorHandle waitForDataInBackgroundAndNotify];

      [NOTIFICATION_CENTER addObserver:self 
			      selector:@selector(logErrOut:)
				  name:NSFileHandleDataAvailableNotification
				object:errorHandle];
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
  RELEASE(userInputColor);
  RELEASE(debuggerColor);
  RELEASE(messageColor);
  RELEASE(errorColor);
  RELEASE(promptColor);
  RELEASE(font);
  RELEASE(debuggerPath);
  RELEASE(debugger);
  RELEASE(tView);
  RELEASE(singleInputLine);
  RELEASE(pendingOutput);
  RELEASE(lastMIDictionary);
  RELEASE(lastMIString);
  [super dealloc];
}

- (void) putString: (NSString *)string;
{
  NSData *data;

  if (stdinHandle == nil || [string length] == 0)
    {
      return;
    }

  data = [string dataUsingEncoding:[NSString defaultCStringEncoding]];
  if (data != nil)
    {
      [stdinHandle writeData:data];
      [stdinHandle synchronizeFile];
    }
}

/* for input as typed from the user */
/* since the underlying tty to gdb doesn't handle control characters,
   we fake editing with a single line of text being a buffer, it is displayed
   but sent complete to gdb only on Enter, backspace being handled */
- (void) typeString: (NSString *)string
{
  NSUInteger strLen;

  strLen = [string length];
  if (strLen == 1)
    {
      // if we have a single backspace or delete character
      if([string characterAtIndex:0] == '\177') // del (maybe backspace)
	{
	  if ([singleInputLine length])
	    {
	      NSUInteger textLength;

	      [singleInputLine deleteCharactersInRange: NSMakeRange([singleInputLine length]-1, 1)];
	      textLength = [[tView string] length];
	      if (textLength > 0)
		{
		  [tView setSelectedRange:NSMakeRange(textLength - 1, 1)];
		  [tView delete:nil];
		}
	      return;
	    }
	}
      else if([string characterAtIndex:0] == '\n')
	{
	  // we end our single line and pipe it down
	  [singleInputLine appendString:string];
	  [self putString:singleInputLine];
	  [singleInputLine setString:@""];
	}
      else
	{
	  [singleInputLine appendString:string];
	}
    }
  else
    {
      [singleInputLine appendString:string];
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
	//        NSLog(@"char: %o", c);

	if (c == 3) // ETX, Control-C
	  {
	    [self interrupt];  // send the interrupt signal to the subtask
	  }
        else if (c == 13) // CR
          {
            [self typeString: @"\n"];
          }
	else if (c < 255)  // helps ignoring arrows, pgup/pgdown which gets 2-byte chars
	  {
	    [self typeString: chars];
	  }
      }
    else
      {
      }
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
	  bpString = [NSString stringWithFormat:@"-break-insert -f \"%@:%@\"\n", fileName, lineNumber];
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
	  [self putString: command];
	}
    }
}

- (void) debuggerSetup
{
  NSString *command = @"-gdb-set confirm off\n";
  
  [self putString: command];
}
@end
