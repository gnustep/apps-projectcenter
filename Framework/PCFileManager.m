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

#include <ProjectCenter/PCDefines.h>
#include <ProjectCenter/PCFileManager.h>
#include <ProjectCenter/PCFileCreator.h>
#include <ProjectCenter/PCProjectManager.h>
#include <ProjectCenter/PCProject.h>
#include <ProjectCenter/PCProjectBrowser.h>
#include <ProjectCenter/PCAddFilesPanel.h>

#include <ProjectCenter/PCLogController.h>

@implementation PCFileManager

// ===========================================================================
// ==== Class methods
// ===========================================================================

static PCFileManager *_mgr = nil;

+ (PCFileManager *)defaultManager
{
  if (_mgr == nil)
    {
      _mgr = [[self alloc] init];
    }

  return _mgr;
}

// ===========================================================================
// ==== Init and free
// ===========================================================================

- (id)initWithProjectManager:(PCProjectManager *)aProjectManager
{
  if ((self = [super init])) 
    {
      projectManager = aProjectManager;
      creators = [[PCFileCreator sharedCreator] creatorDictionary];
      RETAIN(creators);
    }
  return self;
}

- (void)dealloc
{
#ifdef DEVELOPMENT
  NSLog (@"PCFileManager: dealloc");
#endif

  RELEASE(creators);
  RELEASE(newFilePanel);

  if (addFilesPanel)
    {
      RELEASE(addFilesPanel);
    }
  
  [super dealloc];
}

// ===========================================================================
// ==== NSFileManager delegate methods
// ===========================================================================
- (BOOL)     fileManager:(NSFileManager *)manager 
 shouldProceedAfterError:(NSDictionary *)errorDict
{
  NSLog(@"FM error is: %@", [errorDict objectForKey:@"Error"]);

  return YES;
}

// ===========================================================================
// ==== File handling
// ===========================================================================
- (BOOL)createDirectoriesIfNeededAtPath:(NSString *)path
{
  NSString       *_path = [NSString stringWithString:path];
  NSString       *_oldPath = nil;
  NSMutableArray *pathArray = [NSMutableArray array];
  NSFileManager  *fm = [NSFileManager defaultManager];
  BOOL           isDir;
  int            i;

  /* We stop when we find a file, or when we can't remove any path
   * component any more.  Else, you may end up in an infinite loop if
   * _path = @"".
   */
  while (_path != nil  
	 &&  ![_path isEqualToString: _oldPath]
	 &&  ![fm fileExistsAtPath:_path isDirectory:&isDir])
    {
      [pathArray addObject:[_path lastPathComponent]];
      _oldPath = _path;
      _path = [_path stringByDeletingLastPathComponent];
    }

  if (!isDir)
    {
      return NO;
    }

  if ([_path length] != [path length])
    {
      for (i = [pathArray count]-1; i >= 0; i--)
	{
	  _path = 
	    [_path stringByAppendingPathComponent:[pathArray objectAtIndex:i]];
	  if ([fm createDirectoryAtPath:_path attributes:nil] == NO)
	    {
	      return NO;
	    }
	}
    }

  return YES;
}

- (BOOL)copyFile:(NSString *)file toFile:(NSString *)toFile
{
  NSFileManager *fm = [NSFileManager defaultManager];
  NSString      *directoryPath = nil;

  if (!file)
    {
      return NO;
    }

  if (![fm fileExistsAtPath:toFile]) 
    {
      directoryPath = [toFile stringByDeletingLastPathComponent];
      if ([self createDirectoriesIfNeededAtPath:directoryPath] == NO)
	{
	  NSLog(@"PCFileManager: createDirectoriesIfNeededAtPath: == NO");
	  return NO;
	}

      if ([fm copyPath:file toPath:toFile handler:self] == NO)
	{
	  NSLog(@"PCFileManager: copyPath:toPath: == NO");
	  return NO;
	}
    }

  return YES;
}

- (BOOL)copyFile:(NSString *)file intoDirectory:(NSString *)directory
{
  NSString *path = nil;

  if (!file)
    {
      return NO;
    }
    
  path = [directory stringByAppendingPathComponent:[file lastPathComponent]];

  if (![self copyFile:file toFile:path])
    {
      return NO;
    }

  return YES;
}

- (BOOL)copyFile:(NSString *)file 
   fromDirectory:(NSString *)fromDir
   intoDirectory:(NSString *)toDir
{
  NSString *path = nil;

  if (!file || !fromDir || !toDir)
    {
      return NO;
    }
    
  path = [fromDir stringByAppendingPathComponent:[file lastPathComponent]];

  if (![self copyFile:path intoDirectory:toDir])
    {
      return NO;
    }

  return YES;
}

- (BOOL)copyFiles:(NSArray *)files intoDirectory:(NSString *)directory
{
  NSEnumerator *enumerator = nil;
  NSString     *file = nil;

  if (!files)
    {
      return NO;
    }

  enumerator = [files objectEnumerator];
  while ((file = [enumerator nextObject]))
    {
      if ([self copyFile:file intoDirectory:directory] == NO)
	{
	  return NO;
	}
    }

  return YES;
}

- (BOOL)removeDirectoriesIfEmptyAtPath:(NSString *)path
{
  NSFileManager *fm = [NSFileManager defaultManager];

  while ([[fm directoryContentsAtPath:path] count] == 0)
    {
      if ([fm removeFileAtPath:path handler:nil] == NO)
	{
	  return NO;
	}
      path = [path stringByDeletingLastPathComponent];
    }

  return YES;
}

- (BOOL)removeFile:(NSString *)file
     fromDirectory:(NSString *)directory
 removeDirsIfEmpty:(BOOL)removeDirs
{
  NSString      *path = nil;
  NSFileManager *fm = [NSFileManager defaultManager];
  
  if (!file)
    {
      return NO;
    }

  path = [directory stringByAppendingPathComponent:file];
  if (![fm removeFileAtPath:path handler:nil])
    {
      NSLog(@"PCFileManager: removeFileAtPath: == NO");
      return NO;
    }

  if (removeDirs)
    {
      [self removeDirectoriesIfEmptyAtPath:directory];
    }

  return YES;
}

- (BOOL)removeFileAtPath:(NSString *)file removeDirsIfEmpty:(BOOL)removeDirs
{
  return [self removeFile:[file lastPathComponent]
	    fromDirectory:[file stringByDeletingLastPathComponent]
	removeDirsIfEmpty:removeDirs];
}

- (BOOL)removeFiles:(NSArray *)files
      fromDirectory:(NSString *)directory
  removeDirsIfEmpty:(BOOL)removeDirs
{
  NSEnumerator *filesEnum = nil;
  NSString     *file = nil;

  if (!files)
    {
      return NO;
    }

  filesEnum = [files objectEnumerator];
  while ((file = [filesEnum nextObject]))
    {
      if ([self removeFile:file 
	     fromDirectory:directory 
	 removeDirsIfEmpty:removeDirs] == NO)
	{
	  return NO;
	}
    }

  return YES;
}

- (BOOL)moveFile:(NSString *)file intoDirectory:(NSString *)directory
{
  if ([self copyFile:file intoDirectory:directory] == YES)
    {
      [self removeFileAtPath:file removeDirsIfEmpty:YES];
    }
  else
    {
      return NO;
    }

  return YES;
}

- (void)createFile
{
  NSString     *path = nil;
  NSString     *fileName = [nfNameField stringValue];
  NSString     *fileType = [nfTypePB titleOfSelectedItem];
  NSDictionary *theCreator = [creators objectForKey:fileType];
  NSString     *key = [theCreator objectForKey:@"ProjectKey"];

//  PCLogInfo(self, @"[createFile] %@", fileName);

  path = [projectManager fileManager:self 
                      willCreateFile:fileName
		             withKey:key];

//  PCLogInfo(self, @"creating file at %@", path);

  // Create file
  if (path) 
    {
      NSDictionary  *newFiles = nil;
      PCFileCreator *creator = nil;
      PCProject     *project = [projectManager activeProject];
      NSEnumerator  *enumerator;
      NSString      *aFile;

      creator = [theCreator objectForKey:@"Creator"];
      if (!creator) 
	{
	  NSRunAlertPanel(@"Attention!",
			  @"Could not create %@. The creator is missing!",
			  @"OK",nil,nil,fileName);
	  return;
	}

      // Do it finally...
      newFiles = [creator createFileOfType:fileType path:path project:project];

      // Key: name of file
      enumerator = [[newFiles allKeys] objectEnumerator]; 
      while ((aFile = [enumerator nextObject])) 
	{
	  fileType = [newFiles objectForKey:aFile];
	  theCreator = [creators objectForKey:fileType];
	  key = [theCreator objectForKey:@"ProjectKey"];
	   
	  [projectManager fileManager:self didCreateFile:aFile withKey:key];
	}
    }
}

@end

@implementation PCFileManager (UInterface)

// ===========================================================================
// ==== Panels
// ===========================================================================

- (id)_panelForOperation:(int)op
		   title:(NSString *)title
		 accView:(NSView *)accessoryView
{
  NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
  NSString       *lastOpenDir;
  id             panel;

  operation = op;

  switch (op)
    {
    case PCOpenFileOperation: 
      panel = [NSOpenPanel openPanel];
      [panel setCanChooseFiles:YES];
      [panel setCanChooseDirectories:NO];
      lastOpenDir = [ud objectForKey:@"FileOpenLastDirectory"];
      break;
    case PCSaveFileOperation: 
      panel = [NSSavePanel savePanel];
      lastOpenDir = [ud objectForKey:@"FileSaveLastDirectory"];
      break;
    case PCOpenProjectOperation: 
      panel = [NSOpenPanel openPanel];
      [panel setAllowsMultipleSelection:NO];
      [panel setCanChooseFiles:YES];
      [panel setCanChooseDirectories:YES];
      lastOpenDir = [ud objectForKey:@"ProjectOpenLastDirectory"];
      break;
    case PCAddFileOperation: 
      if (addFilesPanel == nil)
	{
	  addFilesPanel = [PCAddFilesPanel addFilesPanel];
	}
      panel = addFilesPanel;
      lastOpenDir = [ud objectForKey:@"FileAddLastDirectory"];
      break;
    default:
      return nil;
      break;
    }

  if (!lastOpenDir)
    {
      lastOpenDir = NSHomeDirectory();
    }
  [panel setDirectory:lastOpenDir];
  [panel setDelegate:self];

  if (title != nil)
    {
      [panel setTitle:title];
    }
  if (accessoryView != nil)
    {
      [panel setAccessoryView:accessoryView];
    }


  return panel;
}

- (void)_saveLastDirectoryForPanel:(id)panel
{
  NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
  NSString       *key = nil;

  switch (operation)
    {
    case PCOpenFileOperation: 
      key = @"FileOpenLastDirectory";
      break;
    case PCSaveFileOperation: 
      key = @"FileSaveLastDirectory";
      break;
    case PCOpenProjectOperation: 
      key = @"ProjectOpenLastDirectory";
      break;
    case PCAddFileOperation: 
      key = @"FileAddLastDirectory";
      break;
    default:
      break;
    }

  if (key != nil)
    {
      [ud setObject:[panel directory] forKey:key];
    }
}

- (NSMutableArray *)filesOfTypes:(NSArray *)types
		       operation:(int)op
			multiple:(BOOL)yn
			   title:(NSString *)title
			 accView:(NSView *)accessoryView
{
  id             panel;
  NSMutableArray *fileList = [[NSMutableArray alloc] init];
  NSString       *file;
  NSFileManager  *fm = [NSFileManager defaultManager];
  BOOL           isDir;
  int            result;

  panel = [self _panelForOperation:op title:title accView:accessoryView];

  if ((op == PCOpenFileOperation) || (op == PCOpenProjectOperation))
    {
      [panel setAllowsMultipleSelection:yn];

      if ((result = [panel runModalForTypes:types]) == NSOKButton) 
	{
	  [fileList addObjectsFromArray:[panel filenames]];

	  file = [fileList objectAtIndex:0];
	  if (op == PCOpenProjectOperation &&
	      [fm fileExistsAtPath:file isDirectory:&isDir] && isDir)
	    {
	      file = [file stringByAppendingPathComponent:@"PC.project"];
	      [fileList insertObject:file atIndex:0];
	    }
	}
    }
  else if (op == PCSaveFileOperation)
    {
      if ((result = [panel runModal]) == NSOKButton) 
	{
	  [fileList addObject:[panel filename]];
	}
    }
  else if (op == PCAddFileOperation)
    {
      PCProject *project = [projectManager activeProject];
      NSString  *selectedCategory = nil;

      [panel setCategories:[project rootCategories]];
      selectedCategory = [[project projectBrowser] nameOfSelectedCategory];
      [panel selectCategory:selectedCategory];

      if ((result = [panel runModalForTypes:types]) == NSOKButton) 
	{
	  [fileList addObjectsFromArray:[panel filenames]];
	}
    }

  if (result == NSOKButton)
    {
      [self _saveLastDirectoryForPanel:panel];
      return [fileList autorelease];
    }

  return nil;
}

// ============================================================================
// ==== "New File in Project" Panel
// ============================================================================
- (void)showNewFilePanel
{
  if (!newFilePanel)
    {
      if ([NSBundle loadNibNamed:@"NewFile" owner:self] == NO)
	{
	  PCLogError(self, @"error loading NewFile NIB!");
	  return;
	}
      [newFilePanel setFrameAutosaveName:@"NewFile"];
      if (![newFilePanel setFrameUsingName: @"NewFile"])
    	{
	  [newFilePanel center];
	}
      [newFilePanel center];
      [nfImage setImage:[NSApp applicationIconImage]];
      [nfTypePB setRefusesFirstResponder:YES];
      [nfTypePB removeAllItems];
      [nfTypePB addItemsWithTitles:
	[[creators allKeys] 
	  sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)]];
      [nfTypePB selectItemAtIndex:0];
      [nfCancleButton setRefusesFirstResponder:YES];
      [nfCreateButton setRefusesFirstResponder:YES];
    }

  [self newFilePopupChanged:nfTypePB];

  [newFilePanel makeKeyAndOrderFront:self];
  [nfNameField setStringValue:@""];
  [newFilePanel makeFirstResponder:nfNameField];
}

- (void)closeNewFilePanel:(id)sender
{
  [newFilePanel orderOut:self];
}

- (void)createFile:(id)sender
{
  [self createFile];
  [self closeNewFilePanel:self];
}

- (void)newFilePopupChanged:(id)sender
{
  NSString     *type = [sender titleOfSelectedItem];
  NSDictionary *creator = [creators objectForKey:type];

  if (type)
    {
      [nfDescriptionTV setString:[creator objectForKey:@"TypeDescription"]];
    }
}

- (void)controlTextDidChange:(NSNotification *)aNotif
{
  if ([aNotif object] != nfNameField)
    {
      return;
    }

  // TODO: Add check for valid file names
  if ([[nfNameField stringValue] length] > 0)
    {
      [nfCreateButton setEnabled:YES];
    }
  else
    {
      [nfCreateButton setEnabled:NO];
    }
}

// ============================================================================
// ==== PCAddFilesPanel delegate
// ============================================================================

- (void)categoryChangedTo:(NSString *)category
{
  PCProject        *project = [projectManager activeProject];
  NSArray          *fileTypes = nil;
  PCProjectBrowser *browser = [project projectBrowser];
  NSString         *path = [browser path];

  [addFilesPanel setTitle:[NSString stringWithFormat:@"Add %@",category]];

  fileTypes = [project 
    fileTypesForCategoryKey:[project keyForCategory:category]];
  [addFilesPanel setFileTypes:fileTypes];

  // Set project browser path
  path = [path stringByDeletingLastPathComponent];
  path = [path stringByAppendingPathComponent:category];
  [browser setPath:path];
}

// ============================================================================
// ==== NSOpenPanel and NSSavePanel delegate
// ============================================================================

// If file name already in project -- don't show it! 
- (BOOL)panel:(id)sender shouldShowFilename:(NSString *)filename
{
  NSFileManager *fileManager = [NSFileManager defaultManager];
  BOOL          isDir;
  PCProject     *project = nil;
  NSArray       *fileTypes = nil;
  NSString      *category = nil;
  NSString      *categoryKey = nil;

  [fileManager fileExistsAtPath:filename isDirectory:&isDir];
  
  if ([[filename pathExtension] isEqualToString:@"gorm"])
    {
      isDir = NO;
    }
    
  if (sender == addFilesPanel && !isDir)
    {
      project = [projectManager activeProject];
      category = [addFilesPanel selectedCategory];
      categoryKey = [project keyForCategory:category];
      fileTypes = [project fileTypesForCategoryKey:categoryKey];
      // Wrong file extension
      if (fileTypes 
	  && ![fileTypes containsObject:[filename pathExtension]])
	{
	  return NO;
	}
      // File is already in project
      if (![project doesAcceptFile:filename forKey:categoryKey])
	{
	  return NO;
	}
    }

  return YES;
}

// Test if we should accept file name selected or entered
- (BOOL)panel:(id)sender isValidFilename:(NSString *)filename
{
  NSFileManager *fm = [NSFileManager defaultManager];
  BOOL          isDir;
  NSString      *file;

  if (operation == PCOpenProjectOperation)
    {
      if ([fm fileExistsAtPath:filename isDirectory:&isDir] && isDir)
	{
	  file = [filename stringByAppendingPathComponent:@"PC.project"];
	  if ([fm fileExistsAtPath:file])
	    {
	      return YES;
	    }
	  return NO;
	}
    }

  return YES;
}

@end

@implementation PCFileManager (FileType)

/**
 * Returns YES if the file identified by `filename' is a text file,
 * otherwise returns NO.
 *
 * The test is one by reading the first 512 bytes of the file
 * and checking whether at least 90% of the data are printable
 * ASCII characters.
 *
 * Author Saso Kiselkov
 */
- (BOOL)isTextFile:(NSString *)filename
{
  NSFileHandle *fh;
  NSData       *data;
  unsigned int i, n;
  const char   *buf;
  unsigned int printable;

  fh = [NSFileHandle fileHandleForReadingAtPath:filename];
  if (fh == nil)
    {
      return NO;
    }

  data = [fh readDataOfLength:512];
  if ([data length] == 0)
    {
      return YES;
    }

  buf = [data bytes];
  for (i = printable = 0, n = [data length]; i < n; i++)
    {
      if (isprint(buf[i]) || isspace(buf[i]))
	{
	  printable++;
	}
    }

  return (((double) printable / n) > 0.9);
}

@end
