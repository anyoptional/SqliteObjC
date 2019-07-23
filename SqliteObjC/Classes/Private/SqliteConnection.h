//
//  SqliteConnection.h
//  SqliteObjC
//
//  Created by Archer on 2019/7/16.
//

#import <Foundation/Foundation.h>
#import "Connection.h"
#import <sqlite3.h>

NS_ASSUME_NONNULL_BEGIN

/**
 DO NOT USE.
 */
@interface SqliteConnection : NSObject <Connection>

@property (nonatomic, readonly) dispatch_semaphore_t lock;
@property (nonatomic, readonly, assign) sqlite3 *database;
@property (nonatomic, readonly, copy) NSString *databasePath;

+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithPath:(NSString *)path;

@end

FOUNDATION_EXTERN BOOL SQLiteConnectionIsClosed(id<Connection> conn);

NS_ASSUME_NONNULL_END
