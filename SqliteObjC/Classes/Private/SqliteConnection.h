//
//  SqliteConnection.h
//  SqliteObjC
//
//  Created by Archer on 2019/7/16.
//

#import <Foundation/Foundation.h>
#import "Connection.h"
#import <sqlite3.h>

@protocol SqliteConnectionDelegate;

NS_ASSUME_NONNULL_BEGIN

/**
 DO NOT USE.
 */
@interface SqliteConnection : NSObject <Connection>

@property (nonatomic, readonly) dispatch_semaphore_t lock;
@property (nonatomic, readonly, assign) sqlite3 *database;
@property (nonatomic, readonly, copy) NSString *databasePath;
@property (nullable, nonatomic, weak) id<SqliteConnectionDelegate> delegate;

+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithPath:(NSString *)path;

@end

@protocol SqliteConnectionDelegate <NSObject>
- (void)sqliteConnectionDidClose:(SqliteConnection *)conn;
@end

FOUNDATION_EXTERN BOOL SQLiteConnectionIsClosed(id<Connection> conn);

NS_ASSUME_NONNULL_END
