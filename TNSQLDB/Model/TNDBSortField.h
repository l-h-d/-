//
//  TNDBSortObject.h
//  Pods
//
//  Created by l-h-d on 4/6/17.
//
//

#import <Foundation/Foundation.h>

@interface TNDBSortField : NSObject

/*
 * If multiple table have the same field, use like this: "TableName.filed"
 */
@property(nonatomic, copy) NSString *fieldName;

//Default value is Yes
@property(nonatomic, assign) BOOL ascing;

@end
