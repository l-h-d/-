//
//  TNViewController.h
//  TNSQLDB
//
//  Created by l-h-d on 04/27/2017.
//  Copyright (c) 2017 l-h-d. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "TNDBBaseObject.h"
#import "TNDBBaseManager.h"

@interface TNViewController : UIViewController

@end

@interface TestDBObject : TNDBBaseObject
@property(nonatomic, copy) NSString *primaryKey_1;
@property(nonatomic, copy) NSString *primaryKey_2;
@property(nonatomic, copy) NSString *testStr;
@property(nonatomic, assign) NSInteger testBase;
@property(nonatomic, strong) NSNumber *testNumber;
@property(nonatomic, strong) NSDictionary *testDict;
@end

@interface TestTwoDBObject : TNDBBaseObject
@property(nonatomic, copy) NSString *primarykey;
@property(nonatomic, copy) NSString *data;
@end

@interface TestDBManager : TNDBBaseManager

@end
