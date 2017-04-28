#ifdef __OBJC__
#import <UIKit/UIKit.h>
#else
#ifndef FOUNDATION_EXPORT
#if defined(__cplusplus)
#define FOUNDATION_EXPORT extern "C"
#else
#define FOUNDATION_EXPORT extern
#endif
#endif
#endif

#import "TNDBBaseManager.h"
#import "TNDBBaseObject.h"
#import "TNDBSortField.h"
#import "TNDBBaseUtils.h"

FOUNDATION_EXPORT double TNSQLDBVersionNumber;
FOUNDATION_EXPORT const unsigned char TNSQLDBVersionString[];

