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

#import <Foundation/Foundation.h>

@interface PCMakefileFactory : NSObject
{
    NSMutableString *mfile;
    NSString        *pnme;
}

+ (PCMakefileFactory *)sharedFactory;

- (void)createMakefileForProject:(NSString *)prName;

- (void)appendString:(NSString *)aString;

- (void)appendApplication;

- (void)appendHeaders:(NSArray *)array;
- (void)appendClasses:(NSArray *)array;
- (void)appendCFiles:(NSArray *)array;

- (void)appendResources;
- (void)appendResourceItems:(NSArray *)array;

- (void)appendInstallDir:(NSString*)dir;
- (void)appendAppIcon:(NSString*)icn;

- (void)appendSubprojects:(NSArray*)array;
- (void)appendGuiLibraries:(NSArray*)array;

- (void)appendTailForApp;
- (void)appendTailForLibrary;
- (void)appendTailForTool;
- (void)appendTailForBundle;
- (void)appendTailForGormApp;

- (NSData *)encodedMakefile;

@end

#endif // _PCMAKEFILEFACTORY_H_

