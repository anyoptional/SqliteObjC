//
//  DataSource.h
//  SqliteObjC
//
//  Created by Archer on 2019/7/16.
//

#import <Foundation/Foundation.h>
#import "Connection.h"

NS_ASSUME_NONNULL_BEGIN

/**
 A factory for connections to the physical data source that this
 DataSource object represents.
 */
@protocol DataSource <NSObject>

/**
 Creates a DataSource with the specified database file path.

 @param path File path of database file.
 @return The DataSouce object that produce connections.
 */
- (instancetype)initWithPath:(NSString *)path;

/**
 Creates a DataSource with the specified database file path.
 
 @param path File path of database file.
 @return The DataSouce object that produce connections.
 */
+ (instancetype)dataSourceWithPath:(NSString *)path;

/**
 File path of database file. Setting this property will affect
 next result from getConnection method call.
 */
@property (nonatomic, copy) NSString *path;

/**
 Attempts to establish a connection with the data source that
 DataSource object represents.
 
 Multiple connection with the same name will make the database unstable.

 @return A connection to the data source, opened already.
 */
- (nullable id<Connection>)getConnection;

@end

NS_ASSUME_NONNULL_END
