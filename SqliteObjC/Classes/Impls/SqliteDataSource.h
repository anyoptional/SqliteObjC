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
 File path of database file. Setting this property will affect
 next result from getConnection method call.
 */
@property (nonatomic, copy) NSString *path;

@end

NS_ASSUME_NONNULL_END
