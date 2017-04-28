//
//  TNViewController.m
//  TNSQLDB
//
//  Created by l-h-d on 04/27/2017.
//  Copyright (c) 2017 l-h-d. All rights reserved.
//

#import "TNViewController.h"

#import <FMDB/FMDatabaseAdditions.h>
#import "TNDBBaseUtils.h"
#import "TNDBSortField.h"
#import <objc/runtime.h>

@interface TNViewController ()

@property(nonatomic, strong) TestDBManager *manager;

@end

@implementation TNViewController

- (void)viewDidLoad {
    [super viewDidLoad];
#if 0
    NSMutableArray *list = [NSMutableArray array];
    for (NSInteger i = 0; i < 1000; i++) {
        TestDBObject *objc = [TestDBObject new];
        objc.primaryKey_1 = [NSString stringWithFormat:@"pri_%ld", i];
        objc.primaryKey_2 = [NSString stringWithFormat:@"pri_%ld", i % 10];
        objc.testBase = i;
        objc.testStr = [NSString stringWithFormat:@"%@ %@",objc.primaryKey_1, objc.primaryKey_2];
        objc.testDict = [@{@"test num":@(i)} mutableCopy];
        [list addObject:objc];
    }
    NSLog(@"aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa:2");
    [self.manager saveItems:list];
    
    list = [NSMutableArray array];
    for (NSInteger i = 1000; i >= 0; i--) {
        TestTwoDBObject *objc = [TestTwoDBObject new];
        objc.primarykey = [NSString stringWithFormat:@"pri_%ld", i];
        objc.data = [NSString stringWithFormat:@"data %ld", i];
        [list addObject:objc];
    }
    [self.manager saveItems:list];
    NSLog(@"aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa:3");
#elif 0
    NSArray *list = [self.manager queryItemsInTable:[TestDBObject class] where:@"primaryKey_2 in %@", @[@"pri_1",@"pri_2"], nil];
    NSLog(@"aaaaaaaaaaaaaaaaaaaaaaaaaaa:%@",list);
    TNDBSortField *filed1 = [TNDBSortField new];
    filed1.fieldName = @"TestDBObject.primaryKey_1";
    filed1.ascing = NO;
    TNDBSortField *field2 = [TNDBSortField new];
    field2.fieldName = @"testBase";
    list = [self.manager queryItemJSONInTable:[TestDBObject class] sortFields:@[filed1, field2] where:@"primaryKey_1 in %@", @[@"pri_1",@"pri_2"], nil];
    NSLog(@"aaaaaaaaaaaaaaaaaaaaaaaaaaa sort :%@",list);
    list = [self.manager queryItemsInTables:@[[TestDBObject class], [TestTwoDBObject class]] tableFields:@[@"*"] sortFields:@[field2] where:@"TestTwoDBObject.primarykey = TestDBObject.primaryKey_2", nil, nil];
    NSLog(@"aaaaaaaaaaaaaaaaaaaaaaaaaaa union :%@",list);
#elif 0
    [self.manager updateItemsInTable:[TestDBObject class] withContent:@{@"testStr":@"ccc", @"testNumber":@(1000000000000)} where:@"primaryKey_1 IN %@", @[@"pri_3", @"pri_4"], nil];
#elif 1
    [self.manager deleteItemsInTable:[TestDBObject class] where:@"testBase = %@", @(4), nil];
    [self.manager deleteItemsInTable:[TestTwoDBObject class] where:@"primarykey LIKE '%@'", @"%4", nil];
#endif
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (TestDBManager *)manager {
    if (_manager == nil) {
        _manager = [[TestDBManager alloc] init];
        [_manager setupDBBaseManagerWithDBName:@"Test" withVersion:@"1" withUId:@"1" withDelegate:(id<TNDBBaseManagerDelegate>)_manager];
    }
    
    return _manager;
}
@end

@implementation TestDBObject
+ (NSString *)primaryKey {
    return @"primaryKey_1,primaryKey_2";
}

+ (NSDictionary *)defaultPropertyValues {
    return @{@"testDict":[@{@"111":@"111"} mutableCopy], @"testNumber":@(1)};
}
@end

@interface TestDBManager() <TNDBBaseManagerDelegate>

@end

@implementation TestDBManager
- (NSArray *)registerTableClasses {
    return @[[TestDBObject class], [TestTwoDBObject class]];
}
@end

@implementation TestTwoDBObject
+ (NSString *)primaryKey {
    return @"primarykey";
}

+ (NSDictionary *)defaultPropertyValues {
    return @{};
}

@end
