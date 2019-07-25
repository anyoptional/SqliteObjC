## Introduction
SqliteObjC is a database abstraction layer, build-in thread-safe, inspired by JDBC.

## How to use
There are usually 6 steps while using this lib.
- 1 Create a `DataSouce` object
- 2 Retrieve `Connection` object from `DataSouce`
- 3 Prepare `Statement` object from `Connection`. There are two kinds of statements here, 
`Statement`  and  `PreparedStatement`, the difference is that `PreparedStatement` can
take placeholder arguments, which is `?` actually.
- 4 Execute the sql statement through `Statement` , get `ResultSet` after executing
- 5 Process `ResultSet`
- 6 Release resources

Here is a example:
```
// 1 Create a `DataSouce` object
NSString *path = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents/test.db"];
id<DataSource> dataSouce = [SqliteDataSource dataSourceWithPath:path];

// 2 Retrieve `Connection` object from `DataSouce`
id<Connection> connection = [dataSouce getConnection];

// 3 Create a Statement object to execute static sql statement
id<Statement> stmt = [connection createStatement];
// - Create a database table
[stmt executeUpdate:@"create table if not exists goods_t(id int primary key, name text, price real)"];
// - Insert a row into table
[stmt executeUpdate:@"insert into goods_t(name, price) values('Archer', 21.5)"];

// Create a `PreparedStatement` object to execute sql statement with `?` placeholders
id<PreparedStatement> pStmt0 = [connection prepareStatement:@"insert into goods_t(name, price) values(?, ?)"];
// - Binding values to `?` placeholders in the sql statement
[pStmt0 setString:@"Saber" atIndex:0];
[pStmt0 setDouble:36.8 atIndex:1];
// - Execute sql statement, this method can be called multiple times
[pStmt0 executeUpdate];

// - This method can also bind values to `?` placeholders in the sql statement
[pStmt0 executeUpdateWithArguments:@[@"Lancer", @(42.6)]];

// 4 Execute the sql statement, get `ResultSet`
id<PreparedStatement> pStmt1 = [connection prepareStatement:@"select * from goods_t where name=?"];
[pStmt1 setString:@"Archer" atIndex:0];
id<ResultSet> rs = [pStmt1 executeQuery];

// 5 Prosess `ResultSet`
while ([rs next]) {
    NSLog(@"%d %@ %.2f", [rs intForColumnIndex:0], [rs stringForColumnIndex:1], [rs doubleForColumnIndex:2]);
}

// 6 Release resources
[rs close];
[stmt close];
[pStmt0 close];
[pStmt1 close];
[connection close];
```

## Example

To run the example project, clone the repo, and run `pod install` from the Example directory first.

## License

SqliteObjC is available under the MIT license. See the LICENSE file for more info.
