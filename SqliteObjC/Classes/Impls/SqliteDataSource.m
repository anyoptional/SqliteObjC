//
//  SqliteDataSource.m
//  SqliteObjC
//
//  Created by Archer on 2019/7/16.
//

#import "SqliteDataSource.h"
#import "SqliteConnection.h"

@interface SqliteDataSource () <SqliteConnectionDelegate>
@property (nonatomic, strong) NSMutableDictionary<NSString *, id<Connection>> *connectionPool;
@end

@implementation SqliteDataSource

@synthesize path = _path;

+ (instancetype)dataSourceWithPath:(NSString *)path {
    return [[self.class alloc] initWithPath:path];
}

- (instancetype)initWithPath:(NSString *)path {
    NSParameterAssert(path);
    if (self = [super init]) {
        _path = [path copy];
        _connectionPool = @{}.mutableCopy;
    }
    return self;
}

- (void)setPath:(NSString *)path {
    NSParameterAssert(path);
    @synchronized (self) {
        _path = [path copy];
    }
}

- (NSString *)path {
    @synchronized (self) {
        return _path;
    }
}

- (id<Connection>)getConnection {
    NSString *path = self.path;
    SqliteConnection *conn = nil;
    @synchronized (self) {
        conn = [_connectionPool objectForKey:path];
    }
    if (!conn) {
        conn = [[SqliteConnection alloc] initWithPath:path];
    }
    if ([conn open]) {
        conn.delegate = self;
        @synchronized (self) {
            [_connectionPool setObject:conn forKey:path];
        }
        return conn;
    }
    return nil;
}

- (void)sqliteConnectionDidClose:(SqliteConnection *)conn {
    NSString *key = conn.databasePath;
    @synchronized (self) {
        [_connectionPool removeObjectForKey:key];
    }
}

@end
