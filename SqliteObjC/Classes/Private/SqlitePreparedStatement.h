//
//  SqlitePreparedStatement.h
//  SqliteObjC
//
//  Created by Archer on 2019/7/16.
//

#import <Foundation/Foundation.h>
#import "PreparedStatement.h"
#import "SqliteStatement.h"

NS_ASSUME_NONNULL_BEGIN

/**
 DO NOT USE.
 */
@interface SqlitePreparedStatement : SqliteStatement <PreparedStatement>

@property (nonatomic, readonly, copy) NSString *sql;
 
- (instancetype)initWithConnection:(SqliteConnection *)connection NS_UNAVAILABLE;
- (instancetype)initWithConnection:(SqliteConnection *)connection associatedQuery:(NSString *)sql;

@end

NS_ASSUME_NONNULL_END
