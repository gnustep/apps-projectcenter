/*
   GNUstep ProjectCenter - http://www.gnustep.org

   Copyright (C) 2000-2002 Free Software Foundation

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
//#include "PreferenceController.h"
#include "ProjectEditor.h"
#include "ProjectDebugger.h"

#include "PCLogController.h"

@interface PCBundleLoader (PrivateLoader)

- (void)loadAdditionalBundlesAt:(NSString *)path;

@end

@implementation PCBundleLoader (PrivateLoader)

- (void)loadAdditionalBundlesAt:(NSString *)path
{
  NSBundle *bundle;

  NSAssert(path,@"No valid bundle path specified!");

  PCLogInfo(self, @"Loading bundle %@...", path);

  if ((bundle = [NSBundle bundleWithPath:path])) 
    {
      [loadedBundles addObject:bundle];
      PCLogInfo(self, @"Bundle %@ successfully loaded!", path);

      if (delegate 
	  && 
	  [delegate respondsToSelector:@selector(bundleLoader:didLoadBundle:)]) 
	{
	  [delegate bundleLoader:self didLoadBundle:bundle];
	}
    }
  else 
    {
      NSRunAlertPanel(@"Attention!",
		      @"Could not load %@!",
		      @"OK",nil,nil,path);
    }
}

@end

@implementation PCBundleLoader

//----------------------------------------------------------------------------
// Init and free methods
//----------------------------------------------------------------------------

- (id)init
{
    if ((self = [super init])) {
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

- (void) loadBundles
{
  NSString *path = nil;

  // Load bundles that comes with ProjectCenter
  path = [[NSBundle mainBundle] resourcePath];
  if (![[NSFileManager defaultManager] fileExistsAtPath: path]) 
    {
      [NSException raise: @"PCBundleLoaderPathException" 
	          format: @"No valid bundles at path:\n%@", path];
      return;
    }
  [self loadBundlesAtPath: path];
 
  // Load third party bundles
  path = [[NSUserDefaults standardUserDefaults] objectForKey:BundlePaths];
  if (!path || [path isEqualToString: @""]) 
    {
      NSDictionary *env = [[NSProcessInfo processInfo] environment];
      NSString     *prefix = [env objectForKey: @"GNUSTEP_SYSTEM_ROOT"];

      path = [prefix stringByAppendingPathComponent:
 	      @"Library/ApplicationSupport/ProjectCenter"];

      [[NSUserDefaults standardUserDefaults] setObject: path 
                                                forKey: BundlePaths];
      [[NSUserDefaults standardUserDefaults] synchronize];
    }

  if (![[NSFileManager defaultManager] fileExistsAtPath: path]) 
    {
      PCLogInfo(self, @"No third party bundles at %@", path);
      return;
    }
  else 
    {
      PCLogInfo(self, @"Loading bundles at %@", path);
    }
    
  [self loadBundlesAtPath: path];
}

- (void) loadBundlesAtPath: (NSString *)path
{
  NSEnumerator *enumerator;
  NSString     *bundleName;
  NSArray      *dir;

  dir = [[NSFileManager defaultManager] directoryContentsAtPath: path];
  enumerator = [dir objectEnumerator];

  while ((bundleName = [enumerator nextObject]))
    {
      if ([[bundleName pathExtension] isEqualToString:@"bundle"]) 
	{
	  NSString *fullPath;

	  fullPath = [NSString stringWithFormat:@"%@/%@",path,bundleName];
	  [self loadAdditionalBundlesAt:fullPath];
	}
    }
}

- (NSArray *)loadedBundles
{
    return loadedBundles;
}

@end
