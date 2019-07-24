//
//  SqliteDatabaseMetaData.h
//  SqliteObjC
//
//  Created by Archer on 2019/7/24.
//

#import <Foundation/Foundation.h>
#import "DatabaseMetaData.h"

@class SqliteConnection;

NS_ASSUME_NONNULL_BEGIN

@interface SqliteDatabaseMetaData : NSObject <DatabaseMetaData>

@property (nonatomic, readonly, strong) SqliteConnection *connection;

+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithConnection:(SqliteConnection *)connection;

@end

NS_ASSUME_NONNULL_END
