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

#include <ProjectCenter/PCBundleManager.h>
#include <ProjectCenter/PCDefines.h>

#include <ProjectCenter/PCLogController.h>

@implementation PCBundleManager

//----------------------------------------------------------------------------
// Init and free methods
//----------------------------------------------------------------------------

- (id)init
{
  if ((self = [super init]))
    {
      loadedBundles = [[NSMutableDictionary alloc] init];
      bundlesInfo = [[NSMutableDictionary alloc] init];
    }

  return self;
}

- (void)dealloc
{
  RELEASE(loadedBundles);
  RELEASE(bundlesInfo);

  [super dealloc];
}

//
- (NSString *)resourcePath
{
  NSString *path = [[NSBundle mainBundle] resourcePath];

  if (![[NSFileManager defaultManager] fileExistsAtPath:path]) 
    {
      [NSException raise:@"PCBundleManagerPathException" 
	          format:@"ProjectCenter installed incorrectly"];
      return nil;
    }

  return path;
}

//
// bundlesInfo is a dictionary. key/value pair is the following:
// "full path of a bundle" = "Info.table contents"
// propertyValueOfClass:withKey:
- (NSDictionary *)infoForBundlesOfType:(NSString *)extension
{
  NSArray             *bundles;
  NSEnumerator        *enumerator;
  NSString            *bundlePath;
  NSString            *infoTablePath;
  NSDictionary        *infoTable;
  NSMutableDictionary *reqBundlesInfo;

  reqBundlesInfo = [NSMutableDictionary dictionary];
  bundles = [NSBundle pathsForResourcesOfType:extension 
                                  inDirectory:[self resourcePath]];
  enumerator = [bundles objectEnumerator];

  while ((bundlePath = [enumerator nextObject]))
    {
      infoTablePath = [NSString 
	stringWithFormat:@"%@/Resources/Info.table", bundlePath];
      infoTable = [NSDictionary dictionaryWithContentsOfFile:infoTablePath];
      [reqBundlesInfo setObject:infoTable forKey:bundlePath];
      [bundlesInfo setObject:infoTable forKey:bundlePath];
    }

  return reqBundlesInfo;
}

- (NSString *)bundlePathWithName:(NSString *)bundleName
{
  NSArray      *bundlePaths = nil;
  NSString     *bundleFullPath = nil;
  NSEnumerator *enumerator = nil;

  // Search for bundle full path in bundlesInfo dictionary
  bundlePaths = [bundlesInfo allKeys];
  enumerator = [bundlePaths objectEnumerator];

  while ((bundleFullPath = [enumerator nextObject]))
    {
      if ([[bundleFullPath lastPathComponent] isEqualToString:bundleName])
	{
	  break;
	}
    }

  return bundleFullPath;
}

- (NSBundle *)bundleOfType:(NSString *)type forClassName:(NSString *)className
{
  NSArray      *bundlePaths = nil;
  NSDictionary *infoTable = nil;
  NSString     *bundleFullPath = nil;
  NSEnumerator *enumerator = nil;
  NSString     *bundleName = nil;
  NSString     *principalClass;

  // Search for bundle full path in bundlesInfo dictionary
  bundlePaths = [bundlesInfo allKeys];
  enumerator = [bundlePaths objectEnumerator];
  
  while ((bundleFullPath = [enumerator nextObject]))
    {

      if ([[bundleFullPath pathExtension] isEqualToString:type])
	{
	  infoTable = [bundlesInfo objectForKey:bundleFullPath];
	  principalClass = [infoTable objectForKey:@"PrincipalClassName"];
	  if ([className isEqualToString:principalClass])
	    {
	      break;
	    }
	}
    }

//  NSLog(@"bundleForClassName: %@ path %@", className, bundleFullPath);

  // Extract from full bundle path it's name and extension
  bundleName = [bundleFullPath lastPathComponent];
  if (![self loadBundleIfNeededWithName:bundleName])
    {
      return nil;
    }

  return [loadedBundles objectForKey:bundleFullPath];
}

- (id)objectForClassName:(NSString *)className
	    withProtocol:(Protocol *)proto
	    inBundleType:(NSString *)type
{
  Class objectClass;

  if ([self bundleOfType:type forClassName:className] == nil)
    {
      NSLog(@"Bundle for class %@ NOT FOUND!", className);
      return nil;
    }

  objectClass = NSClassFromString(className);

  if (proto != nil && ![objectClass conformsToProtocol:proto])
    {
      [NSException raise:NOT_A_PROJECT_TYPE_EXCEPTION 
	          format:@"%@ does not conform to protocol!", className];
      return nil;
    }

  return [[objectClass alloc] init];
}

- (BOOL)loadBundleIfNeededWithName:(NSString *)bundleName
{
  NSString *bundleFullPath;

  bundleFullPath = [self bundlePathWithName:bundleName];

  // Check if bundle allready loaded
  if ([[loadedBundles allKeys] containsObject:bundleFullPath] == NO)
    {
      return [self loadBundleWithFullPath:bundleFullPath];
    }
  
  return YES;
}

// ---
- (void)loadBundlesWithExtension:(NSString *)extension
{
  NSEnumerator	*enumerator;
  NSFileManager	*fileManager = [NSFileManager defaultManager];
  BOOL 		isDir;
  NSString      *path = [self resourcePath];

  if (path)
    {
      [self loadBundlesAtPath:path withExtension:extension];
    }
 
  // Load third party bundles
  enumerator = [NSSearchPathForDirectoriesInDomains
		 (NSApplicationSupportDirectory, NSAllDomainsMask, YES) 
		 objectEnumerator];
  while ((path = [enumerator nextObject]) != nil)
    {
      path = [path stringByAppendingPathComponent: @"ProjectCenter"];

      if ([fileManager fileExistsAtPath: path  isDirectory: &isDir]  
	  &&  isDir)
	{
	  PCLogInfo(self, @"Loading bundles at %@", path);
	  [self loadBundlesAtPath:path withExtension:extension];
	}
    }
}

- (void)loadBundlesAtPath:(NSString *)path withExtension:(NSString *)extension
{
  NSEnumerator *enumerator;
  NSString     *bundleName;
  NSArray      *dir;

  dir = [[NSFileManager defaultManager] directoryContentsAtPath:path];
  enumerator = [dir objectEnumerator];

  while ((bundleName = [enumerator nextObject]))
    {
      if ([[bundleName pathExtension] isEqualToString:extension]) 
	{
	  NSString *fullPath = nil;

	  fullPath = [NSString stringWithFormat:@"%@/%@", path, bundleName];

	  [self loadBundleWithFullPath:fullPath];
	}
    }
}

- (BOOL)loadBundleWithFullPath:(NSString *)path
{
  NSBundle *bundle = nil;

  if ((bundle = [NSBundle bundleWithPath:path]) && [bundle load])
    {
      [loadedBundles setObject:bundle forKey:path];

      PCLogInfo(self, @"Bundle %@ successfully loaded!", path);
    }
  else 
    {
      NSRunAlertPanel(@"Load Bundle",
		      @"Could not load bundle %@!",
		      @"OK", nil, nil, path);
      return NO;
    }

  return YES;
}

- (NSDictionary *)loadedBundles
{
  return loadedBundles;
}

@end
