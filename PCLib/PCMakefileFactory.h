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
- (void)appendClasses:(NSArray *)array;
- (void)appendCFiles:(NSArray *)array;

- (void)appendInstallDir:(NSString*)dir;

- (void)appendResources;
- (void)appendResourceItems:(NSArray *)array;

- (void)appendSubprojects:(NSArray*)array;

- (void)appendTailForApp;
- (void)appendTailForLibrary;
- (void)appendTailForTool;
- (void)appendTailForBundle;
- (void)appendTailForGormApp;

- (NSData *)encodedMakefile;

@end

@interface PCMakefileFactory (ApplicationProject)

- (void)appendApplication;
- (void)appendAppIcon:(NSString*)icn;
- (void)appendGuiLibraries:(NSArray*)array;

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
- (void)appendLibraryCFiles:(NSArray *)array;

@end

@interface PCMakefileFactory (ToolProject)

- (void)appendTool;
- (void)appendToolIcon:(NSString*)icn;
- (void)appendToolLibraries:(NSArray*)array;

@end

#endif // _PCMAKEFILEFACTORY_H_

