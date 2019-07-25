//
//  FDViewController.m
//  SqliteObjC
//
//  Created by code4archer@163.com on 07/23/2019.
//  Copyright (c) 2019 code4archer@163.com. All rights reserved.
//

#import "FDViewController.h"

@import SqliteObjC;

@interface FDViewController ()

@end

@implementation FDViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // 1 获取数据源
    NSString *path = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents/test.db"];
    id<DataSource> dataSouce = [SqliteDataSource dataSourceWithPath:path];
    
    // 2 通过数据源获取数据库连接
    id<Connection> connection = [dataSouce getConnection];
    
    // 3 通过Connection获取SQL执行语句，不带占位参数的简单语句使用Statement
    id<Statement> stmt = [connection createStatement];
    // - 创建表
    [stmt executeUpdate:@"create table if not exists goods_t(id int primary key, name text, price real)"];
    // - 插入数据，参数写定
    [stmt executeUpdate:@"insert into goods_t(name, price) values('Archer', 21.5)"];
    // 关闭
    [stmt close];
    
    // 参数要动态配置，使用PreparedStatement
    id<PreparedStatement> pStmt = [connection prepareStatement:@"insert into goods_t(name, price) values(?, ?)"];
    // 第一种配置方式 通过setXXX:atIndex:
    [pStmt setString:@"Saber" atIndex:0];
    [pStmt setDouble:36.8 atIndex:1];
    // 调用executeUpdate执行，可以调用多次
    [pStmt executeUpdate];
    
    // 第二种方式 调用executeUpdateWithArguments
    [pStmt executeUpdateWithArguments:@[@"Lancer", @(42.6)]];
    // 关闭
    [pStmt close];
    
    // 4 查询
    pStmt = [connection prepareStatement:@"select * from goods_t where name=?"];
    [pStmt setString:@"Archer" atIndex:0];
    // - 执行executeQuery获取ResultSet
    id<ResultSet> rs = [pStmt executeQuery];
    
    // - 获取ResultSet元数据
    id<ResultSetMetaData> rsmd = rs.metaData;
    
    NSLog(@"column count = %ld", rsmd.columnCount);
    for (NSInteger i = 0; i < rsmd.columnCount; ++i) {
        NSLog(@"column name = %@", [rsmd columnNameForIndex:i]);
    }
    
    while ([rs next]) {
        for (NSInteger i = 0; i < rsmd.columnCount; ++i) {
            /// 游标移动到当前行才能获取类型
            NSLog(@"column type is %ld", [rsmd columnTypeForIndex:1]);
        }
        NSLog(@"%d %@ %.2f", [rs intForColumnIndex:0], [rs stringForColumnIndex:1], [rs doubleForColumnIndex:2]);
    }
    
    // 关闭
    [rs close];
    [pStmt close];
    [connection close];
}


@end
