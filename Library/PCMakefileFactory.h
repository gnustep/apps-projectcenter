/* 
 * PCMakefileFactory.h created by probert on 2002-02-28 22:16:26 +0000
 *
 * Project ProjectCenter
 *
 * Created with ProjectCenter - http://www.gnustep.org
 *
 * $Id$
 */

#ifndef _PCMAKEFILEFACTORY_H_
#define _PCMAKEFILEFACTORY_H_

#include <Foundation/Foundation.h>

@interface PCMakefileFactory : NSObject
{
    NSMutableString *mfile;
    NSString        *pnme;
}

+ (PCMakefileFactory *)sharedFactory;

- (void)createMakefileForProject:(NSString *)prName;

- (void)appendString:(NSString *)aString;

- (void)appendHeaders:(NSArray *)array;
- (void)appendHeaders:(NSArray *)array forTarget: (NSString *)target;
- (void)appendClasses:(NSArray *)array;
- (void)appendClasses:(NSArray *)array forTarget: (NSString *)target;
- (void)appendOtherSources:(NSArray *)array;
- (void)appendOtherSources:(NSArray *)array forTarget: (NSString *)target;
- (void)appendResources;
- (void)appendResourceItems:(NSArray *)array;

- (void)appendSubprojects:(NSArray*)array;

- (NSData *)encodedMakefile;

- (void)appendTailForBundle;
- (void)appendTailForLibrary;
- (void)appendTailForTool;

@end

@interface PCMakefileFactory (BundleProject)

- (void)appendBundle;
- (void)appendPrincipalClass:(NSString *)cname;
- (void)appendBundleInstallDir:(NSString*)dir;
- (void)appendLibraries:(NSArray*)array;

@end

@interface PCMakefileFactory (LibraryProject)

- (void)appendLibrary;
- (void)appendLibraryInstallDir:(NSString*)dir;
- (void)appendLibraryLibraries:(NSArray*)array;
- (void)appendLibraryHeaders:(NSArray*)array;
- (void)appendLibraryClasses:(NSArray *)array;
- (void)appendLibraryOtherSources:(NSArray *)array;

@end

@interface PCMakefileFactory (ToolProject)

- (void)appendTool;
- (void)appendToolIcon:(NSString*)icn;
- (void)appendToolLibraries:(NSArray*)array;

@end

#endif // _PCMAKEFILEFACTORY_H_

