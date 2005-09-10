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

#include "PCBundleLoader.h"
#include "PCDefines.h"

#include "PCLogController.h"

@implementation PCBundleLoader

//----------------------------------------------------------------------------
// Init and free methods
//----------------------------------------------------------------------------

- (id)init
{
  if ((self = [super init]))
    {
      loadedBundles = [[NSMutableArray alloc] init];
    }

  return self;
}

- (void)dealloc
{
  RELEASE(loadedBundles);

  [super dealloc];
}

- (id)delegate
{
  return delegate;
}

- (void)setDelegate:(id)aDelegate
{
  delegate = aDelegate;
}

- (void)loadBundlesWithExtension:(NSString *)extension
{
  NSString *path = [[NSBundle mainBundle] resourcePath];

  // Load bundles that comes with ProjectCenter
  if (![[NSFileManager defaultManager] fileExistsAtPath:path]) 
    {
      [NSException raise:@"PCBundleLoaderPathException" 
	          format:@"ProjectCenter installed incorrectly"];
      return;
    }

  [self loadBundlesAtPath:path withExtension:extension];
 
  // Load third party bundles
  path = [[NSUserDefaults standardUserDefaults] objectForKey:BundlePaths];
  if (!path || [path isEqualToString: @""]) 
    {
      NSDictionary *env = [[NSProcessInfo processInfo] environment];
      NSString     *prefix = [env objectForKey: @"GNUSTEP_SYSTEM_ROOT"];

      path = [prefix stringByAppendingPathComponent:
 	      @"Library/ApplicationSupport/ProjectCenter"];

      [[NSUserDefaults standardUserDefaults] setObject:path 
                                                forKey:BundlePaths];
      [[NSUserDefaults standardUserDefaults] synchronize];
    }

  if (![[NSFileManager defaultManager] fileExistsAtPath:path]) 
    {
      PCLogInfo(self, @"No third party bundles at %@", path);
      return;
    }
  else 
    {
      PCLogInfo(self, @"Loading bundles at %@", path);
      [self loadBundlesAtPath:path withExtension:extension];
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

- (void)loadBundleWithFullPath:(NSString *)path
{
  NSBundle *bundle = nil;
  SEL      bundleDidLoadedSel = @selector(bundleLoader:didLoadBundle:);

  if ((bundle = [NSBundle bundleWithPath:path])) 
    {
      [loadedBundles addObject:bundle];

      PCLogInfo(self, @"Bundle %@ successfully loaded!", path);

      if (delegate && [delegate respondsToSelector:bundleDidLoadedSel]) 
	{
	  [delegate bundleLoader:self didLoadBundle:bundle];
	}
    }
  else 
    {
      NSRunAlertPanel(@"Attention!",
		      @"Could not load %@!",
		      @"OK", nil, nil, path);
    }
}

- (NSArray *)loadedBundles
{
  return loadedBundles;
}

@end
