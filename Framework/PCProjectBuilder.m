/*
   GNUstep ProjectCenter - http://www.gnustep.org/experience/ProjectCenter.html

   Copyright (C) 2000-2004 Free Software Foundation

   Authors: Philippe C.D. Robert
            Serg Stoyan

   This file is part of GNUstep.

   This application is free software; you can redistribute it and/or
   modify it under the terms of the GNU General Public
   License as published by the Free Software Foundation; either
   version 2 of the License, or (at your option) any later version.

   This application is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
   Library General Public License for more details.

   You should have received a copy of the GNU General Public
   License along with this library; if not, write to the Free
   Software Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111 USA.
*/

#include <AppKit/AppKit.h>

#include <ProjectCenter/PCDefines.h>
#include <ProjectCenter/PCSplitView.h>
#include <ProjectCenter/PCButton.h>

#include <ProjectCenter/PCFileManager.h>

#include <ProjectCenter/PCProjectManager.h>
#include <ProjectCenter/PCProject.h>
#include <ProjectCenter/PCProjectBuilder.h>

#include <ProjectCenter/PCLogController.h>
#include <ProjectCenter/PCPrefController.h>

#ifndef IMAGE
#define IMAGE(X) [NSImage imageNamed: X]
#endif

#ifndef NOTIFICATION_CENTER
#define NOTIFICATION_CENTER [NSNotificationCenter defaultCenter]
#endif

@implementation PCProjectBuilder

- (id)initWithProject:(PCProject *)aProject
{
  NSAssert(aProject, @"No project specified!");

//  PCLogInfo(self, @"initWithProject %@", [aProject projectName]);
  
  if ((self = [super init]))
    {
      project = aProject;
      buildTarget = [[NSMutableString alloc] initWithString:@"Default"];
      buildArgs = [[NSMutableArray array] retain];
      postProcess = NULL;
      makeTask = nil;
      _isBuilding = NO;
      _isCleaning = NO;
      _isCVLoaded = NO;

      if ([NSBundle loadNibNamed:@"Builder" owner:self] == NO)
	{
	  PCLogError(self, @"error loading Builder NIB file!");
	  return nil;
	}
    }

  return self;
}

- (void)dealloc
{
#ifdef DEVELOPMENT
  NSLog (@"PCProjectBuilder: dealloc");
#endif

  [buildTarget release];
  [buildArgs release];
  [makePath release];

//  PCLogInfo(self, @"componentView RC: %i", [componentView retainCount]);
//  PCLogInfo(self, @"RC: %i", [self retainCount]);
  [componentView release];
  [errorArray release];
  [errorString release];

  [super dealloc];
}

- (void)awakeFromNib
{
  NSScrollView *errorScroll; 
  NSScrollView *logScroll;

  if (_isCVLoaded)
    {
      return;
    }

  NSLog(@"ProjectBuilder awakeFromNib");

  [componentView retain];
  [componentView removeFromSuperview];

  /*
   * 4 build Buttons
   */
  [buildButton setToolTip:@"Build"];
  [buildButton setImage:IMAGE(@"Build")];

  [cleanButton setToolTip:@"Clean"];
  [cleanButton setImage:IMAGE(@"Clean")];

  [installButton setToolTip:@"Install"];
  [installButton setImage:IMAGE(@"Install")];

  [optionsButton setToolTip:@"Build Options"];
  [optionsButton setImage:IMAGE(@"Options")];
  
  [errorsCountField setStringValue:@""];

  /*
   *  Error output
   */
  errorArray = [[NSMutableArray alloc] initWithCapacity:0];
  errorString = [[NSMutableString alloc] initWithString:@""];

  errorImageColumn = [[NSTableColumn alloc] initWithIdentifier:@"ErrorImage"];
  [errorImageColumn setEditable:NO];
  [errorImageColumn setWidth:20.0];
  errorColumn = [[NSTableColumn alloc] initWithIdentifier:@"Error"];
  [errorColumn setEditable:NO];

  errorOutput = [[NSTableView alloc]
    initWithFrame:NSMakeRect(0,0,209,111)];
  [errorOutput setAllowsMultipleSelection:NO];
  [errorOutput setAllowsColumnReordering:NO];
  [errorOutput setAllowsColumnResizing:NO];
  [errorOutput setAllowsEmptySelection:YES];
  [errorOutput setAllowsColumnSelection:NO];
  [errorOutput setRowHeight:19.0];
  [errorOutput setCornerView:nil];
  [errorOutput setHeaderView:nil];
  [errorOutput addTableColumn:errorImageColumn];
  [errorOutput addTableColumn:errorColumn];
  [errorOutput setDataSource:self];
  [errorOutput setBackgroundColor:[NSColor colorWithDeviceRed:0.88
                                                             green:0.76 
                                                              blue:0.60 
                                                             alpha:1.0]];
  [errorOutput setDrawsGrid:NO];
  [errorOutput setTarget:self];
  [errorOutput setAction:@selector(errorItemClick:)];

  errorScroll = [[NSScrollView alloc] initWithFrame:NSMakeRect(0,0,464,120)];
  [errorScroll setHasHorizontalScroller:NO];
  [errorScroll setHasVerticalScroller:YES];
  [errorScroll setBorderType:NSBezelBorder];
  [errorScroll setAutoresizingMask:(NSViewWidthSizable | NSViewHeightSizable)];

  [errorScroll setDocumentView:errorOutput];
  RELEASE(errorOutput);

  /*
   *  Log output
   */
  logScroll = [[NSScrollView alloc] 
    initWithFrame:NSMakeRect (0, 0, 480, 133)];
  [logScroll setHasHorizontalScroller:NO];
  [logScroll setHasVerticalScroller:YES];
  [logScroll setBorderType:NSBezelBorder];
  [logScroll setAutoresizingMask:(NSViewWidthSizable | NSViewHeightSizable)];

  logOutput = [[NSTextView alloc] 
    initWithFrame:[[logScroll contentView] frame]];
  [logOutput setRichText:NO];
  [logOutput setEditable:NO];
  [logOutput setSelectable:YES];
  [logOutput setAutoresizingMask:NSViewWidthSizable | NSViewHeightSizable];
  [logOutput setBackgroundColor:[NSColor lightGrayColor]];
  [[logOutput textContainer] setWidthTracksTextView:YES];
  [[logOutput textContainer] setHeightTracksTextView:YES];
  [logOutput setHorizontallyResizable:NO];
  [logOutput setVerticallyResizable:YES];
  [logOutput setMinSize:NSMakeSize(0, 0)];
  [logOutput setMaxSize:NSMakeSize(1E7, 1E7)];
  [[logOutput textContainer] setContainerSize: 
    NSMakeSize ([logOutput frame].size.width, 1e7)];
  [[logOutput textContainer] setWidthTracksTextView:YES];

  [logScroll setDocumentView:logOutput];
  RELEASE(logOutput);

  /*
   * Split view
   */
  [split addSubview:errorScroll];
  RELEASE (errorScroll);
  [split addSubview:logScroll];
  RELEASE (logScroll);

//  [split adjustSubviews];
//  [componentView addSubview:split];
//  RELEASE (split);

  _isCVLoaded = YES;
}

- (NSView *)componentView
{
  return componentView;
}

- (BOOL)setMakePath
{
  makePath = [[NSUserDefaults standardUserDefaults] objectForKey:BuildTool];

  if (!makePath || ![[NSFileManager defaultManager] fileExistsAtPath:makePath])
    {
      NSRunAlertPanel(@"Build terminated",
  		      @"Build tool not found.\nFile \"%@\" doesn't exist!",
  		      @"OK", nil, nil, makePath);
      return NO;
    }

  return YES;
}

// --- Accessory
- (BOOL)isBuilding
{
  return _isBuilding;
}

- (BOOL)isCleaning
{
  return _isCleaning;
}

- (void)performStartBuild
{
  if (!_isBuilding && !_isCleaning)
    {
      [buildButton performClick:self];
    }
}

- (void)performStartClean
{
  if (!_isCleaning && !_isBuilding)
    {
      [cleanButton performClick:self];
    }
}

- (void)performStopBuild
{
  if (_isBuilding)
    {
      [buildButton performClick:self];
    }
  else if (_isCleaning)
    {
      [cleanButton performClick:self];
    }
}

// --- GUI Actions
- (void)startBuild:(id)sender
{
  NSString *tFString = [targetField stringValue];
  NSArray  *tFArray = [tFString componentsSeparatedByString:@" "];

  if ([self stopMake:self] == YES)
    {// We've just stopped build process
      return;
    }
  [buildTarget setString:[tFArray objectAtIndex:0]];

  // Set build arguments
  if ([buildTarget isEqualToString:@"Debug"])
    {
      [buildArgs addObject:@"debug=yes"];
    }
  else if ([buildTarget isEqualToString:@"Profile"])
    {
      [buildArgs addObject:@"profile=yes"];
      [buildArgs addObject:@"static=yes"];
    }
  else if ([buildTarget isEqualToString:@"Tarball"])
    {
      [buildArgs addObject:@"dist"];
    }

  currentEL = ELNone;
  lastEL = ELNone;
  nextEL = ELNone;
  lastIndentString = @"";

  currentBuildPath = [[NSMutableArray alloc] initWithCapacity:1];
  [currentBuildPath addObject:[project projectPath]];
  currentBuildFile = [[NSMutableString alloc] initWithString:@""];

  statusString = [NSString stringWithString:@"Building..."];
  [buildTarget setString:@"Build"];
  [cleanButton setEnabled:NO];
  [installButton setEnabled:NO];
  [self build:self];
  _isBuilding = YES;
}

- (void)startClean:(id)sender
{
  if ([self stopMake:self] == YES)
    {// We've just stopped build process
      return;
    }

  if ([[[[NSUserDefaults standardUserDefaults] dictionaryRepresentation]
      objectForKey:PromptOnClean] isEqualToString:@"YES"])
    {
      if (NSRunAlertPanel(@"Clean Project?",
			  @"Do you really want to clean project '%@'?",
			  @"Yes", @"No", nil, [project projectName])
	  == NSAlertAlternateReturn)
	{
	  [cleanButton setState:NSOffState];
	  return;
	}
    }

  statusString = [NSString stringWithString:@"Cleaning..."];
  [buildTarget setString:@"Clean"];
  [buildArgs addObject:@"clean"];
  [buildButton setEnabled:NO];
  [installButton setEnabled:NO];
  [self build:self];
  _isCleaning = YES;
}

- (void)startInstall:(id)sender
{
  if ([self stopMake:self] == YES)
    {// We've just stopped build process
      return;
    }

  [buildTarget setString:@"Install"];
  statusString = [NSString stringWithString:@"Installing..."];
  [buildArgs addObject:@"install"];
  [buildButton setEnabled:NO];
  [cleanButton setEnabled:NO];
  [self build:self];
}

- (BOOL)stopMake:(id)sender
{
  // [makeTask isRunning] doesn't work here.
  // "waitpid 7045, result -1, error No child processes" is printed.
  if (makeTask)
    {
      PCLogStatus(self, @"task will terminate");
      NS_DURING
	{
	  [makeTask terminate];
	}
      NS_HANDLER
	{
	  return NO;
	}
      NS_ENDHANDLER
      return YES;
    }

  return NO;
}

- (void)cleanupAfterMake
{
  if (_isBuilding || _isCleaning)
    {
      [buildStatusField setStringValue:[NSString stringWithFormat: 
	@"%@ - %@ terminated", [project projectName], buildTarget]];
    }

  // Restore buttons state
  if ([buildTarget isEqualToString:@"Build"])
    {
      [buildButton setState:NSOffState];
      [cleanButton setEnabled:YES];
      [installButton setEnabled:YES];
    }
  else if ([buildTarget isEqualToString:@"Clean"])
    {
      [cleanButton setState:NSOffState];
      [buildButton setEnabled:YES];
      [installButton setEnabled:YES];
    }
  else if ([buildTarget isEqualToString:@"Install"])
    {
      [installButton setState:NSOffState];
      [buildButton setEnabled:YES];
      [cleanButton setEnabled:YES];
    }

  [buildArgs removeAllObjects];
  [buildTarget setString:@"Default"];

  if (_isBuilding)
    {
      [currentBuildPath release];
      [currentBuildFile release];
    }

  _isBuilding = NO;
  _isCleaning = NO;
}

// --- Actions

- (BOOL)prebuildCheck
{
  PCPrefController *prefs = [PCPrefController sharedPCPreferences];
  PCFileManager    *pcfm = [PCFileManager defaultManager];
  NSFileManager    *fm = [NSFileManager defaultManager];
  NSString         *buildDir = [prefs objectForKey:RootBuildDirectory];
  NSString         *projectBuildDir;

  // Checking prerequisites
  if ([project isProjectChanged])
    {
      if (NSRunAlertPanel(@"Project Changed!",
			  @"Should it be saved first?",
			  @"Yes", @"No", nil) == NSAlertDefaultReturn) 
	{
	  [project save];
	}
    }
  else
    {
      // Synchronize PC.project and generated files just for case
      [project save];
    }

  // Get make tool path
  makePath = [[NSUserDefaults standardUserDefaults] objectForKey:BuildTool];

  if (!makePath || ![[NSFileManager defaultManager] fileExistsAtPath:makePath])
    {
      NSRunAlertPanel(@"Build terminated",
  		      @"Build tool not found.\nFile \"%@\" doesn't exist!",
  		      @"OK", nil, nil, makePath);
      return NO;
    }

  // Create root build directory if not exist
  projectBuildDir = [NSString stringWithFormat:@"%@.build", 
		  [project projectName]];
  projectBuildDir = [buildDir stringByAppendingPathComponent:projectBuildDir];
  if (![fm fileExistsAtPath:buildDir] ||
      ![fm fileExistsAtPath:projectBuildDir])
    {
      [pcfm createDirectoriesIfNeededAtPath:projectBuildDir];
    }

  return YES;
}

- (void)build:(id)sender
{
  NSPipe *logPipe;
  NSPipe *errorPipe;

  // TODO: Support build options!!!
  //  NSDictionary        *optionDict = [project buildOptions];

  // Checking build conditions
  if ([self prebuildCheck] == NO)
    {
      [self cleanupAfterMake];
      return;
    }

  // Prepearing to building
  logPipe = [NSPipe pipe];
  readHandle = [logPipe fileHandleForReading];
  [readHandle waitForDataInBackgroundAndNotify];

  [NOTIFICATION_CENTER addObserver:self 
                          selector:@selector(logStdOut:)
			      name:NSFileHandleDataAvailableNotification
			    object:readHandle];
  _isLogging = YES;

  errorPipe = [NSPipe pipe];
  errorReadHandle = [errorPipe fileHandleForReading];
  [errorReadHandle waitForDataInBackgroundAndNotify];

  [NOTIFICATION_CENTER addObserver:self 
                          selector:@selector(logErrOut:) 
			      name:NSFileHandleDataAvailableNotification
			    object:errorReadHandle];
  _isErrorLogging = YES;
  [errorsCountField setStringValue:[NSString stringWithString:@""]];
  errorsCount = 0;
  warningsCount = 0;

  [buildStatusField setStringValue:statusString];

  // Run make task
  [logOutput setString:@""];
  [errorArray removeAllObjects];
  [errorOutput reloadData];

  [NOTIFICATION_CENTER addObserver:self 
                          selector:@selector(buildDidTerminate:) 
			      name:NSTaskDidTerminateNotification
			    object:nil];

  makeTask = [[NSTask alloc] init];
  [makeTask setArguments:buildArgs];
  [makeTask setCurrentDirectoryPath:[project projectPath]];
  [makeTask setLaunchPath:makePath];
  [makeTask setStandardOutput:logPipe];
  [makeTask setStandardError:errorPipe];

  NS_DURING
    {
      [makeTask launch];
    }
  NS_HANDLER
    {
      NSRunAlertPanel(@"Problem Launching Build Tool",
		      [localException reason],
		      @"OK", nil, nil, nil);
		      
      //Clean up after task is terminated
      [[NSNotificationCenter defaultCenter] 
	postNotificationName:NSTaskDidTerminateNotification
	              object:makeTask];
    }
  NS_ENDHANDLER
}

- (void)buildDidTerminate:(NSNotification *)aNotif
{
  int status;

  if ([aNotif object] != makeTask)
    {
      return;
    }

  NSLog(@"task did terminate");

  [NOTIFICATION_CENTER removeObserver:self 
			         name:NSTaskDidTerminateNotification
			       object:nil];

  // If task was not launched catch exception
  NS_DURING
    {
      status = [makeTask terminationStatus];
    }
  NS_HANDLER
    {
      status = 1;
    }
  NS_ENDHANDLER
 
  // Finish task
  RELEASE(makeTask);
  makeTask = nil;

  // Wait for logging end
  while (_isLogging || _isErrorLogging) 
    {
      [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode
			       beforeDate:[NSDate distantFuture]];
    }
    
  [self updateErrorsCountField];

  if (status == 0)
    {
      [self logString: 
	[NSString stringWithFormat:@"=== %@ succeeded! ===", buildTarget] 
	                     error:NO
			   newLine:YES];
      [buildStatusField setStringValue:[NSString stringWithFormat: 
	@"%@ - %@ succeeded", [project projectName], buildTarget]];
    } 
  else
    {
      [self logString: 
	[NSString stringWithFormat:@"=== %@ terminated! ===", buildTarget]
	                     error:NO
			   newLine:YES];
      if (errorsCount > 0)
	{
	  [buildStatusField setStringValue:[NSString stringWithFormat: 
	    @"%@ - %@ failed (%i errors)", 
	    [project projectName], buildTarget, errorsCount]];
	}
      else
	{
	  [buildStatusField setStringValue:[NSString stringWithFormat: 
	    @"%@ - %@ failed", 
	    [project projectName], buildTarget]];
	}
    }

  // Run post process if configured
/*  if (status && postProcess)
    {
      [self performSelector:postProcess];
      postProcess = NULL;
    }*/

  _isBuilding = NO;
  _isCleaning = NO;
  [self cleanupAfterMake];
}

- (void)logStdOut:(NSNotification *)aNotif
{
  NSData *data;

//  NSLog(@"logStdOut");

  if ((data = [readHandle availableData]) && [data length] > 0)
    {
      [self logData:data error:NO];
    }

  if (makeTask)
    {
      [readHandle waitForDataInBackgroundAndNotify];
    }
  else
    {
      _isLogging = NO;
      [NOTIFICATION_CENTER removeObserver:self 
			             name:NSFileHandleDataAvailableNotification
			           object:readHandle];
    }
}

- (void)logErrOut:(NSNotification *)aNotif
{
  NSData *data;

//  NSLog(@"logErrOut");
  
  if ((data = [errorReadHandle availableData]) && [data length] > 0)
    {
      [self logData:data error:YES];
    }

  if (makeTask)
    {
      [errorReadHandle waitForDataInBackgroundAndNotify];
    }
  else
    {
      _isErrorLogging = NO;
      [NOTIFICATION_CENTER removeObserver:self 
			             name:NSFileHandleDataAvailableNotification
			           object:errorReadHandle];
    }
}

- (void)updateErrorsCountField
{
  NSString *string;
  NSString *errorsString = [NSString stringWithString:@""];;
  NSString *warningsString = [NSString stringWithString:@""];

  if (errorsCount > 0)
    {
      if (errorsCount > 1)
	{
	  errorsString = [NSString stringWithFormat:@"%i errors", 
		       errorsCount];
	}
      else
	{
	  errorsString = [NSString stringWithString:@"1 error"];
	}
    }

  if (warningsCount > 0)
    {
      if (warningsCount > 1)
	{
	  warningsString = [NSString stringWithFormat:@"%i warnings", 
			 warningsCount];
	}
      else
	{
	  warningsString = [NSString stringWithString:@"1 warning"];
	}
    }

  string = [NSString stringWithFormat:@"%@ %@", errorsString, warningsString];
  [errorsCountField setStringValue:string];
}

@end

@implementation PCProjectBuilder (BuildLogging)

- (void)logString:(NSString *)str
            error:(BOOL)yn
	  newLine:(BOOL)newLine
{
//  NSTextView *out = (yn) ? errorOutput : logOutput;
  NSTextView *out = logOutput;

  [out replaceCharactersInRange:
    NSMakeRange([[out string] length],0) withString:str];

  if (newLine)
    {
      [out replaceCharactersInRange:
	NSMakeRange([[out string] length], 0) withString:@"\n"];
    }
  else
    {
      [out replaceCharactersInRange:
	NSMakeRange([[out string] length], 0) withString:@" "];
    }

  [out scrollRangeToVisible:NSMakeRange([[out string] length], 0)];
  [out setNeedsDisplay:YES];
}

- (void)logData:(NSData *)data
          error:(BOOL)yn
{
  NSString *dataString;
  NSRange  newLineRange;
  NSRange  lineRange;
  NSString *lineString;

  dataString = [[NSString alloc] 
    initWithData:data 
	encoding:[NSString defaultCStringEncoding]];
			    
  // Process new data
  lineRange.location = 0;
  [errorString appendString:dataString];
  while (newLineRange.location != NSNotFound)
    {
      newLineRange = [errorString rangeOfString:@"\n"];
/*      NSLog(@"Line(%i) new line range: %i,%i for string\n<--|%@|-->", 
	    [errorString length],
	    newLineRange.location, newLineRange.length, 
	    errorString);*/

      if (newLineRange.location < [errorString length])
	{
//  	  NSLog(@"<------%@------>", errorString);

	  lineRange.length = newLineRange.location+1;
	  lineString = [errorString substringWithRange:lineRange];
	  [errorString deleteCharactersInRange:lineRange];

	  // Send it
	  if (_isBuilding)
	    {
	      [self parseBuildLine:lineString];
	      if (yn)
		{
		  [self logErrorString:lineString];
		}
	    }
	  [self logString:lineString error:yn newLine:NO];
	}
      else
	{
	  newLineRange.location = NSNotFound;
	  continue;
	}
    }

  RELEASE(dataString);
}

- (void)parseBuildLine:(NSString *)string
{
  NSArray  *components = [string componentsSeparatedByString:@" "];

  if (!components)
    {
      return;
    }

  if ([components containsObject:@"Compiling"] &&
      [components containsObject:@"file"])
    {
      NSLog(@"Current build file: %@", [components objectAtIndex:3]);
      [currentBuildFile setString:[components objectAtIndex:3]];
    }
  else if ([components containsObject:@"Entering"] &&
	   [components containsObject:@"directory"])
    {
      NSString *path;
      NSString *pathComponent = [components objectAtIndex:3];

      NSLog(@"Go down to %@", pathComponent);
      path = [pathComponent
	substringWithRange:NSMakeRange(1,[pathComponent length]-3)]; 
      [currentBuildPath addObject:path];
      NSLog(@"%@", [currentBuildPath lastObject]);
    }
  else if ([components containsObject:@"Leaving"] &&
	   [components containsObject:@"directory"])
    {
      NSLog(@"Go up from %@", [components objectAtIndex:3]);
      [currentBuildPath removeLastObject];
      NSLog(@"%@", [currentBuildPath lastObject]);
    }
}

@end

@implementation PCProjectBuilder (ErrorLogging)

- (void)logErrorString:(NSString *)string
{
  NSArray *items;

  items = [self parseErrorLine:string];
  if (items)
    {
      [errorArray addObjectsFromArray:items];
      [errorOutput reloadData];
      [errorOutput scrollRowToVisible:[errorArray count]-1];
    }
}


- (NSString *)lineTail:(NSString*)line afterString:(NSString*)string
{
  NSRange substrRange;

  substrRange = [line rangeOfString:string];
/*  NSLog(@"In function ':%i:%i", 
	substrRange.location, substrRange.length);*/
  substrRange.location += substrRange.length;
  substrRange.length = [line length] - (substrRange.location);
/*  NSLog(@"In function ':%i:%i", 
	substrRange.location, substrRange.length);*/

  return [line substringWithRange:substrRange];
}

- (NSArray *)parseErrorLine:(NSString *)string
{
  NSArray             *components = [string componentsSeparatedByString:@":"];
  NSString            *file = [NSString stringWithString:@""];
  NSString            *includedFile = [NSString stringWithString:@""];
  NSString            *position = [NSString stringWithString:@"{x=0; y=0}"];
  NSString            *type = [NSString stringWithString:@""];
  NSString            *message = [NSString stringWithString:@""];
  NSMutableArray      *items = [NSMutableArray arrayWithCapacity:1];
  NSMutableDictionary *errorItem;
  NSString            *indentString = @"\t";
  NSString            *lastFile = @"";
  NSString            *lastIncludedFile = @"";

  NSAttributedString  *attributedString;
  NSMutableDictionary *attributes = [NSMutableDictionary new];
  NSFont              *font = [NSFont boldSystemFontOfSize:12.0];

  [attributes setObject:font forKey:NSFontAttributeName];
  [attributes setObject:[NSNumber numberWithInt:NSSingleUnderlineStyle] 
		 forKey:NSUnderlineStyleAttributeName];

  lastEL = currentEL;

/*  if (lastEL == ELFile) NSLog(@"+++ELFile");
  if (lastEL == ELFunction) NSLog(@"+++ELFunction");
  if (lastEL == ELIncluded) NSLog(@"+++ELIncluded");
  if (lastEL == ELError) NSLog(@"+++ELError");
  if (lastEL == ELNone) NSLog(@"+++ELNone");*/

  if ([errorArray count] > 0)
    {
      lastFile = [[errorArray lastObject] objectForKey:@"File"];
      lastIncludedFile = [[errorArray lastObject] objectForKey:@"IncludedFile"];
    }

  if ([string rangeOfString:@"In file included from "].location != NSNotFound)
    {
//      NSLog(@"In file included from ");
      currentEL = ELIncluded;
      return nil;
      file = [self lineTail:[components objectAtIndex:0]
		afterString:@"In file included from "];
      file = [[currentBuildPath lastObject]
	stringByAppendingPathComponent:file];
      if ([file isEqualToString:lastFile])
	{
	  return nil;
	}
      position = [NSString stringWithFormat:@"{x=0; y=%f}", 
	       [components objectAtIndex:1]];
      message = [components objectAtIndex:0];
    }
  else if ([string rangeOfString:@"In function '"].location != NSNotFound)
    {
      return nil;
      file = [components objectAtIndex:0];
      message = [self lineTail:string afterString:@"In function "];
      currentEL = ELFunction;
    }
  else if ([string rangeOfString:@" At top level:"].location != NSNotFound)
    {
      currentEL = ELFile;
      return nil;
    }
  else if ([components count] > 3)
    {
      unsigned typeIndex;
      NSString *substr;

      // file and includedFile
//      file = [components objectAtIndex:0];
      file = [[currentBuildPath lastObject] 
	stringByAppendingPathComponent:currentBuildFile];
      if (lastEL == ELIncluded 
	  || [[components objectAtIndex:0] isEqualToString:lastIncludedFile])
	{// first message after "In file included from"
//	  NSLog(@"Inlcuded File: %@", file);
	  includedFile = [components objectAtIndex:0];
      	  file = includedFile;
	  currentEL = ELIncludedError;
	}
      else
	{
	  currentEL = ELError;
	}

      // type
      if ((typeIndex = [components indexOfObject:@" warning"]) != NSNotFound)
	{
	  type = [components objectAtIndex:typeIndex];
	  warningsCount++;
	}
      else if ((typeIndex = [components indexOfObject:@" error"]) != NSNotFound)
	{
	  type = [components objectAtIndex:typeIndex];
	  errorsCount++;
	}
      // position
      if (typeIndex == 2) // :line:
	{
	  position = [NSString stringWithFormat:@"{x=0; y=%f}", 
		   [components objectAtIndex:1]];
	}
      else if (typeIndex == 3) // :line:column:
	{
	  position = [NSString stringWithFormat:@"{x=%f; y=%f}", 
	      	   [components objectAtIndex:2], [components objectAtIndex:1]];
	}
      // message
      substr = [NSString stringWithFormat:@"%@:", type];
      message = [self lineTail:string afterString:substr];
    }
  else
    {
      return nil;
    }

  // Insert indentation
  if (currentEL == ELError)
    {
      if (lastEL == ELFunction)
	{
	  indentString = @"\t\t";
	}
      else if (lastEL == ELError)
	{
	  indentString = [NSString stringWithString:lastIndentString];
	}
    }
  else if (currentEL == ELIncluded)
    {
      indentString = @"";
    }
/*  else if (currentEL == ELIncludedError)
    {
      indentString = @"\t\t";
    }*/

  message = [NSString stringWithFormat:@"%@%@", indentString, message];
  lastIndentString = [indentString copy];

  // Create array items
/*  else if ((lastEL == ELNone 
	    || ![file isEqualToString:lastFile] 
	    || lastEL == ELIncludedError)
	   && currentEL != ELIncluded
	   && currentEL != ELIncludedError)*/
  if ((lastEL == ELNone || ![file isEqualToString:lastFile]) 
      && [includedFile isEqualToString:@""])
    {
//      NSLog(@"lastEL == ELNone (%@)", includedFile);
//      NSLog(@"File: %@ != %@", file, lastFile);
      errorItem = [NSMutableDictionary dictionaryWithCapacity:1];
      [errorItem setObject:@"" forKey:@"ErrorImage"];
      [errorItem setObject:[file copy] forKey:@"File"];
      [errorItem setObject:[includedFile copy] forKey:@"IncludedFile"];
      [errorItem setObject:@"" forKey:@"Position"];
      [errorItem setObject:@"" forKey:@"Type"];
  
      attributedString = [[NSAttributedString alloc] 
	initWithString:[file lastPathComponent]
	    attributes:attributes];
      [errorItem setObject:[attributedString copy] forKey:@"Error"];
      [attributedString release];

      [items addObject:errorItem];
    }

  if ((lastEL == ELIncluded || currentEL == ELIncludedError)
      && ![includedFile isEqualToString:lastIncludedFile])
    {
      NSString *incMessage = [NSString stringWithFormat:@"%@", includedFile];

//      NSLog(@"Included: %@ != %@", includedFile, lastIncludedFile);
      errorItem = [NSMutableDictionary dictionaryWithCapacity:1];
      [errorItem setObject:@"" forKey:@"ErrorImage"];
      [errorItem setObject:[file copy] forKey:@"File"];
      [errorItem setObject:[includedFile copy] forKey:@"IncludedFile"];
      [errorItem setObject:@"" forKey:@"Position"];
      [errorItem setObject:@"" forKey:@"Type"];

      attributedString = [[NSAttributedString alloc] initWithString:incMessage
							 attributes:attributes];
      [errorItem setObject:[attributedString copy] forKey:@"Error"];
      [attributedString release];

      [items addObject:errorItem];
    }

  errorItem = [NSMutableDictionary dictionaryWithCapacity:1];
  [errorItem setObject:@"" forKey:@"ErrorImage"];
  [errorItem setObject:[file copy] forKey:@"File"];
  [errorItem setObject:[includedFile copy] forKey:@"IncludedFile"];
  [errorItem setObject:[position copy] forKey:@"Position"];
  [errorItem setObject:[type copy] forKey:@"Type"];
  [errorItem setObject:[message copy] forKey:@"Error"];

//  NSLog(@"Parsed message:%@ (%@)", message, includedFile);

  [items addObject:errorItem];

  return items;
}

- (int)numberOfRowsInTableView:(NSTableView *)aTableView
{
  if (errorArray != nil && aTableView == errorOutput)
    {
      return [errorArray count];
    }

  return 0;
}
    
- (id)            tableView:(NSTableView *)aTableView
  objectValueForTableColumn:(NSTableColumn *)aTableColumn
                        row:(int)rowIndex
{
  NSDictionary *errorItem;

  if (errorArray != nil && aTableView == errorOutput)
    {
      errorItem = [errorArray objectAtIndex:rowIndex];

      return [errorItem objectForKey:[aTableColumn identifier]];
    }

  return nil;
}

- (void)errorItemClick:(id)sender
{
  int          rowIndex = [errorOutput selectedRow];
  NSDictionary *error = [errorArray objectAtIndex:rowIndex];

  NSLog(@"%i: %@(%@): %@", 
	rowIndex, 
	[error objectForKey:@"File"], 
	[error objectForKey:@"IncludedFile"],
	[error objectForKey:@"Error"]);
}

@end

@implementation PCProjectBuilder (Options)

- (void)showOptionsPanel:(id)sender
{
  if (!optionsPanel)
    {
      if ([NSBundle loadNibNamed:@"BuilderOptions" owner:self] == NO)
	{
	  PCLogError(self, @"error loading BuilderOptions NIB file!");
	  return;
	}
      [targetPopup addItemsWithTitles:[project buildTargets]];
    }

  [optionsPanel makeKeyAndOrderFront:nil];
}

- (void)popupChanged:(id)sender
{
  NSString *target = [targetField stringValue];

  target = [NSString stringWithFormat: 
            @"%@ with args ' %@ '", 
            [targetPopup titleOfSelectedItem], 
            [buildArgsField stringValue]];

  [targetField setStringValue:target];
}

@end
