//
//  SqliteDataSource.h
//  SqliteObjC
//
//  Created by Archer on 2019/7/16.
//

#import <Foundation/Foundation.h>
#import "DataSource.h"

NS_ASSUME_NONNULL_BEGIN

/**
 A factory for connections to the physical data source that this
 DataSource object represents.
 */
@interface SqliteDataSource : NSObject <DataSource>

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

@end

NS_ASSUME_NONNULL_END
