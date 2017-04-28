//
//  TNDBBaseObject.h
//  Pods
//
//  Created by l-h-d on 4/5/17.
//

#import <Foundation/Foundation.h>

@interface TNDBBaseObject : NSObject

/*
 *Multiple keys can be combined to act as primary keys, and keys are separated by commas
 *
 *Use like this: @"key" or @"key1,key2,key3,..."
 *
 */
+ (NSString *)primaryKey;

/*
 *Must ensure the value type is correct if setting, especically the mutable property.
 *
 */
+ (NSDictionary *)defaultPropertyValues;

@end
