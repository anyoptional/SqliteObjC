//
//  SqliteDataSource.m
//  SqliteObjC
//
//  Created by Archer on 2019/7/16.
//

#import "SqliteDataSource.h"
#import "SqliteConnection.h"

@implementation SqliteDataSource

+ (instancetype)dataSourceWithPath:(NSString *)path {
    return [[self.class alloc] initWithPath:path];
}

- (instancetype)initWithPath:(NSString *)path {
    if (self = [super init]) {
        _path = [path copy];
    }
    return self;
}

- (id<Connection>)getConnection {
    id<Connection> conn = [[SqliteConnection alloc] initWithPath:_path];
    return [conn open] ? conn : nil;
}

@end
