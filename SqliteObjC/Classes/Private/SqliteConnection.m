//
//  SqliteConnection.m
//  SqliteObjC
//
//  Created by Archer on 2019/7/16.
//

#import "SqlitePreparedStatement.h"
#import "SqliteConnection.h"
#import "SqliteStatement.h"
#import <sqlite3.h>

BOOL SQLiteConnectionIsClosed(id<Connection> conn) {
    if ([conn isClosed]) {
        NSLog(@"WARNING: sqlite connection is closed.");
        return YES;
    }
    return NO;
}

@interface SqliteConnection ()
/// Only caches `PreparedStatement`
@property (nonatomic, strong) NSMutableDictionary *statementsCache;
@end

@implementation SqliteConnection

- (instancetype)initWithPath:(NSString *)path {
    if (self = [super init]) {
        _database = NULL;
        _databasePath = [path copy];
        _statementsCache = @{}.mutableCopy;
        _lock = dispatch_semaphore_create(1);
    }
    return self;
}

- (void)dealloc {
    [self close];
}

- (BOOL)open {
    dispatch_semaphore_wait(_lock, DISPATCH_TIME_FOREVER);
    if (!_database) {
        int result = sqlite3_open(_databasePath.UTF8String, &_database);
        if (result != SQLITE_OK) {
            NSLog(@"WARNING: %s line:%d sqlite open failed (%d).", __FUNCTION__, __LINE__, result);
            _database = NULL;
            dispatch_semaphore_signal(_lock);
            return NO;
        }
    }
    dispatch_semaphore_signal(_lock);
    return YES;
}

- (BOOL)close {
    [self _clearCachedStatements];
    dispatch_semaphore_wait(_lock, DISPATCH_TIME_FOREVER);
    if (_database) {
        int  result = 0;
        BOOL retry = NO;
        BOOL stmtFinalized = NO;
        do {
            retry = NO;
            result = sqlite3_close(_database);
            if (result == SQLITE_BUSY || result == SQLITE_LOCKED) {
                if (!stmtFinalized) {
                    stmtFinalized = YES;
                    sqlite3_stmt *stmt;
                    while ((stmt = sqlite3_next_stmt(self.database, nil)) != NULL) {
                        sqlite3_finalize(stmt);
                        retry = YES;
                    }
                }
            } else if (result != SQLITE_OK) {
                NSLog(@"WARNING: %s line:%d sqlite close failed (%d).", __FUNCTION__, __LINE__, result);
            }
        } while (retry);
        _database = NULL;
    }
    [_delegate sqliteConnectionDidClose:self];
    dispatch_semaphore_signal(_lock);
    return YES;
}

- (BOOL)isClosed {
    dispatch_semaphore_wait(_lock, DISPATCH_TIME_FOREVER);
    BOOL closed = _database == NULL;
    dispatch_semaphore_signal(_lock);
    return closed;
}

- (id<Statement>)createStatement {
    if (SQLiteConnectionIsClosed(self)) return nil;
    return [[SqliteStatement alloc] initWithConnection:self];;
}

- (id<PreparedStatement>)prepareStatement:(NSString *)sql {
    if (!sql || sql.length == 0) return nil;
    if (SQLiteConnectionIsClosed(self)) return nil;
    id<PreparedStatement> preparedStatement = [self _cachedStatementForQuery:sql];
    if (!preparedStatement) {
        preparedStatement = [[SqlitePreparedStatement alloc] initWithConnection:self associatedQuery:sql];
        [self _cacheStatement:preparedStatement forQuery:sql];
    }
    [preparedStatement clearParameters];
    return preparedStatement;
}

- (BOOL)beginTransaction {
    return [[self createStatement] executeUpdate:@"BEGIN EXCLUSIVE TRANSACTION"];
}

- (BOOL)commit {
    return [[self createStatement] executeUpdate:@"COMMIT TRANSACTION"];
}

- (BOOL)rollback {
    return [[self createStatement] executeUpdate:@"ROLLBACK TRANSACTION"];
}

static NSString *SqliteEscapeSavePointName(NSString *savepointName) {
    return [savepointName stringByReplacingOccurrencesOfString:@"'" withString:@"''"];
}

- (BOOL)setSavePoint:(NSString *)name {
    if (!name || name.length == 0) return NO;
    NSString *sql = [NSString stringWithFormat:@"SAVEPOINT '%@';", SqliteEscapeSavePointName(name)];
    return [[self createStatement] executeUpdate:sql];
}

- (BOOL)releaseSavePoint:(NSString *)name {
    if (!name || name.length == 0) return NO;
    NSString *sql = [NSString stringWithFormat:@"RELEASE SAVEPOINT '%@';", SqliteEscapeSavePointName(name)];
    return [[self createStatement] executeUpdate:sql];
}

- (BOOL)rollbackToSavePoint:(NSString *)name {
    if (!name || name.length == 0) return NO;
    NSString *sql = [NSString stringWithFormat:@"ROLLBACK TRANSACTION TO SAVEPOINT '%@';", SqliteEscapeSavePointName(name)];
    return [[self createStatement] executeUpdate:sql];
}

#pragma mark - Statement cache

- (void)_clearCachedStatements {
    @synchronized (self) {
        for (id<PreparedStatement> pStmt in _statementsCache.allValues) {
            [pStmt close];
        }
        [_statementsCache removeAllObjects];
    }
}

- (id<PreparedStatement>)_cachedStatementForQuery:(NSString *)sql {
    @synchronized (self) {
        return _statementsCache[sql];
    }
}

- (void)_cacheStatement:(id<PreparedStatement>)pStmt forQuery:(NSString *)sql {
    @synchronized (self) {
        _statementsCache[sql] = pStmt;
    }
}

@end

