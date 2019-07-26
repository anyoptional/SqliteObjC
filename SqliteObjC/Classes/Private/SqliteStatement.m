//
//  SqliteStatement.m
//  SqliteObjC
//
//  Created by Archer on 2019/7/16.
//

#import "SqliteStatement.h"
#import "SqliteResultSet.h"
#import "SqliteConnection.h"

@implementation SqliteStatement

- (instancetype)initWithConnection:(SqliteConnection *)connection {
    if (self = [super init]) {
        _connection = connection;
    }
    return self;
}

- (void)dealloc {
    [self close];
}

- (BOOL)close {
    dispatch_semaphore_wait(_connection.lock, DISPATCH_TIME_FOREVER);
    if (!_pStmt) {
        dispatch_semaphore_signal(_connection.lock);
        return YES;
    }
    int result = sqlite3_finalize(_pStmt);
    _pStmt = NULL;
    dispatch_semaphore_signal(_connection.lock);
    return result == SQLITE_OK || result == SQLITE_DONE;
}

- (BOOL)isClosed {
    dispatch_semaphore_wait(_connection.lock, DISPATCH_TIME_FOREVER);
    BOOL closed = _pStmt == NULL;
    dispatch_semaphore_signal(_connection.lock);
    return closed;
}

- (NSInteger)changes {
    if (SQLiteConnectionIsClosed(_connection)) return -1;
    dispatch_semaphore_wait(_connection.lock, DISPATCH_TIME_FOREVER);
    NSInteger changes = sqlite3_changes(_connection.database);
    dispatch_semaphore_signal(_connection.lock);
    return changes;
}

- (BOOL)executeUpdate:(NSString *)sql {
    SqliteResultSet *resultSet = (SqliteResultSet *)[self executeQuery:sql];
    if (!resultSet) return NO;
    int result = [resultSet step];
    [resultSet close];
    if (result == SQLITE_DONE) {
        return YES;
    } else if (result == SQLITE_ROW) {
        NSLog(@"WARNING: %s line:%d please use executeQuery instead.", __FUNCTION__, __LINE__);
        return NO;
    }
    NSLog(@"WARNING: %s line:%d sqlite execute failed (%d).", __FUNCTION__, __LINE__, result);
    return NO;
}

- (id<ResultSet>)executeQuery:(NSString *)sql {
    if (SQLiteConnectionIsClosed(_connection)) return nil;
    dispatch_semaphore_wait(_connection.lock, DISPATCH_TIME_FOREVER);
    [self prepareStatementIfNeeded:sql];
    if (sqlite3_bind_parameter_count(_pStmt) > 0) {
        dispatch_semaphore_signal(_connection.lock);
        NSLog(@"WARNING: %s line:%d Statement may not contain `?` placeholders, use preparedStatement instead.", __FUNCTION__, __LINE__);
        return nil;
    }
    dispatch_semaphore_signal(_connection.lock);
    return [[SqliteResultSet alloc] initWithStatement:self];
}

- (void)prepareStatementIfNeeded:(NSString *)sql {
    if (_pStmt) {
        sqlite3_reset(_pStmt);
    } else {
        int result = sqlite3_prepare_v2(_connection.database, sql.UTF8String, -1, &_pStmt, 0);
        if (result != SQLITE_OK) {
            sqlite3_finalize(_pStmt);
            _pStmt = NULL;
        }
    }
}

@end
