# 一、数据库驱动

客户端连接到数据库是典型的CS编程，服务器端被动等待客户端建立TCP连接，并在此连接上进行特定的应用层协议。但一般用户并不需要了解这些细节，这些都被打包到了驱动库当中，只需要简单的调用打开就可以指定协议连接到指定的数据库。

数据库的种类和产品太多，协议太多，Go官方很难提供针对不同数据库的驱动程序，往往由各数据库官方或第三方给出不同开发语言的驱动库。但是，Go语言可以提前定义操作一个数据库的所有行为（接 口）和数据（结构体）的规范，这些定义在`database/sql`下。

## 1.1 驱动安装

MySQL常用驱动：

- https://github.com/go-sql-driver/mysql：支持 database/sql，推荐
- https://github.com/ziutek/mymysql：支持 database/sql，支持自定义接口
- https://github.com/Philio/GoMySQL：不支持 database/sql，支持自定义接口

驱动下载

```go
go get -u github.com/go-sql-driver/mysql
```

导入驱动

```go
import _ "github.com/go-sql-driver/mysql"
```

## 1.2 DSN 连接配置

Data Source Name 连接格式如下：

```go
[username[:password]@][protocol[(address)]]/dbname[?param1=value1&...&paramN=valueN]
```

实例：

```go
// 初始化 DSN
var db *sql.DB

func init() {
	var err error
	dsn := "root:123456Aa.@tcp(127.0.0.1:3306)/test" 	// 数据库信息
	db, err = sql.Open("mysql", dsn)                    // 连接数据库
	if err != nil {
		log.Panicln(err)
	}
	db.SetConnMaxLifetime(time.Second * 300) // 设置最大连接超时时间
	db.SetMaxOpenConns(0)                    // 设置最大连接数，0 表示不限制
	db.SetMaxIdleConns(10)                   // 设置最大空闲连接数
}
```

## 1.3 基本查询用法

```go
// 和字段对应的结构体定义，最好和数据库中表字段顺序对应，用来承载查询的结果
type Employees struct {
	emp_no                int
	birth_date            string
	first_name, last_name string
	gender                int
	hire_date             string
}
```

- 单行查询

```go
func main() {
	// 查询语句,? 代表参数的占位符，有参数几个就用几个？
	query := "select * from employees where emp_no = ? and last_name = ?"
	arg := []any{10010, "Piveteau"}
	// QueryRow 单行查询
	row := db.QueryRow(query, arg...)
	// 结构体实例化
	var e Employees
	// 查询到的数据使用Scan写入结构体实例
	err := row.Scan(&e.emp_no, &e.birth_date, &e.first_name, &e.last_name, &e.gender, &e.hire_date)
	if err != nil {
		log.Fatal(err)
	}
	fmt.Println(e)
}
```

- 多行查询

```go
func main() {
	// 查询语句,? 代表参数的占位符，有参数几个就用几个？
	query := "select * from employees where emp_no between ? and ?"
	arg := []any{10005, 10010}
	// Query 多行查询
	rows, err := db.Query(query, arg...)
	if err != nil {
		log.Fatal(err)
	}
	// 结构体实例化
	var e Employees
	//  遍历，每一趟rows内部指向当前行
	for rows.Next() {
		// rows每行数据使用Scan写入结构体实例
		err := rows.Scan(&e.emp_no, &e.birth_date, &e.first_name, &e.last_name, &e.gender, &e.hire_date)
		if err != nil {
			log.Fatal(err)
		}
		fmt.Println(e)
	}
}
```

## 1.4 SQL 预编译

Prepare 预编译功能：

1. 对预编译的SQL语句进行缓存，省去了每次解析优化该SQL语句的过程

2. 防止SQL注入攻击

后续操作尽量使用预编译功能，操作数据库

- 单行查询

```go
func main() {
	// 查询语句,? 代表参数的占位符，有参数几个就用几个？
	query := "select * from employees where emp_no = ? and last_name = ?"
	arg := []any{10010, "Piveteau"}

	// 使用db.Prepare预编译并使用参数化查询，可防止SQL注入攻击
	stmt, err := db.Prepare(query)
	if err != nil {
		log.Fatal(err)
	}
	row := stmt.QueryRow(arg...)
	// 查询完成后关闭预编译
	defer stmt.Close()

	// 结构体实例化
	var e Employees
	// 查询到的数据使用Scan写入结构体实例
	err = row.Scan(&e.emp_no, &e.birth_date, &e.first_name, &e.last_name, &e.gender, &e.hire_date)
	if err != nil {
		log.Fatal(err)
	}
	fmt.Println(e)
}
```

- 多行查询

```go
func main() {
	// 查询语句,? 代表参数的占位符，有参数几个就用几个？
	query := "select * from employees where emp_no between ? and ?"
	arg := []any{10005, "10010 or 1 = 1"}

	// 使用db.Prepare预编译并使用参数化查询
	stmt, err := db.Prepare(query)
	if err != nil {
		log.Fatal(err)
	}
	rows, err := stmt.Query(arg...)
	if err != nil {
		log.Fatal(err)
	}
	// 查询完成后关闭预编译
	defer stmt.Close()

	// 结构体实例化
	var e Employees
	//  遍历，每一趟rows内部指向当前行
	for rows.Next() {
		// rows每行数据使用Scan写入结构体实例
		err := rows.Scan(&e.emp_no, &e.birth_date, &e.first_name, &e.last_name, &e.gender, &e.hire_date)
		if err != nil {
			log.Fatal(err)
		}
		fmt.Println(e)
	}
}
```

- 插入数据

```go
func main() {
	// 插入语句,? 代表参数的占位符，有参数几个就用几个？
	insert := "insert into employees values (?,?,?,?,?,?)"
	arg := []any{10021, "1955-01-01", "Tom", "Peac", 1, "1975-01-01"}
	// 使用db.Prepare预编译并传参
	stmt, err := db.Prepare(insert)
	if err != nil {
		log.Fatal(err)
	}
	defer stmt.Close()
	result, err := stmt.Exec(arg...)
	if err != nil {
		log.Fatal(err)
	}
    // 查看插入结果
	affectRow, err := result.RowsAffected()
	if err != nil {
		log.Fatal(err)
	}
	fmt.Println("插入成功，受影响的行数：", affectRow)
}
```

- 更新数据

```go
func main() {
	// 更新语句,? 代表参数的占位符，有参数几个就用几个？
	update := "update employees set first_name = ? where emp_no = ?"
	arg := []any{"Tome", 10021}
	// 使用db.Prepare预编译并传参
	stmt, err := db.Prepare(update)
	if err != nil {
		log.Fatal(err)
	}
	defer stmt.Close()
	result, err := stmt.Exec(arg...)
	if err != nil {
		log.Fatal(err)
	}
	// 查看更新结果
	affectRow, err := result.RowsAffected()
	if err != nil {
		log.Fatal(err)
	}
	fmt.Println("更新成功，受影响的行数：", affectRow)
}
```

- 删除数据

```go
func main() {
	// 更新语句,? 代表参数的占位符，有参数几个就用几个？
	delete := "delete from employees where emp_no = ?"
	arg := []any{10021}
	// 使用db.Prepare预编译并传参
	stmt, err := db.Prepare(delete)
	if err != nil {
		log.Fatal(err)
	}
	defer stmt.Close()
	result, err := stmt.Exec(arg...)
	if err != nil {
		log.Fatal(err)
	}
	// 查看删除结果
	affectRow, err := result.RowsAffected()
	if err != nil {
		log.Fatal(err)
	}
	fmt.Println("删除成功，受影响的行数：", affectRow)
}
```

# 二、GORM

## 2.1 ORM 介绍

对象关系映射（Object Relational Mapping，简称ORM）模式，指的是对象和关系之间的映射，使用面向对象的方式操作数据库。

```go
// 关系模型和Go对象之间的映射
table 	=> 	struct    表映射为结构体
row   	=> 	object    行映射为实例
column 	=> 	property  字段映射为属性
```

如下有一张student表：

| id(int) | name(string) | age(int) |
| ------- | ------------ | -------- |
| 100     | Tom          | 25       |
| 101     | Jerry        | 18       |
| 102     | Jack         | 20       |

将它做ORM映射则转换成：

```go
// 表 -> 结构体
type student struct {
    // 字段 -> 属性
    id 		int
    name 	string
    age 	int
}
// 行 -> 实例
student{100,"Tom",25}
student{101,"Jerry",18}
student{102,"Jack",20}
```

GORM 是使用 Go 语言开发的友好的 ORM 库。官方文档：https://gorm.io/zh_CN/docs/

```go
go get -u gorm.io/gorm
go get -u gorm.io/driver/mysql
```

## 2.2 模型定义约束

**表名**：默认情况下，GORM 将结构体名称转换为蛇形命名 `snake_case` 并为表名加上复数形式。

-  `User` 结构体在数据库中的表名变为 `users` ：

  ```go
  // 结构体 -> 表名
  User -> users
  UserAccount -> user_accounts
  ```

- 您可以实现 `Tabler` 接口来更改默认表名，例如：

  ```go
  type Tabler interface {
      TableName() string
  }
  
  // TableName 会将 UserAccount 的表名重写为 `useraccount`
  func (UserAccount) TableName() string {
    return "useraccount"
  }
  ```

**列名**：默认情况下，GORM 自动将结构体字段名称转换为 `snake_case` 作为数据库中的列名。

- 默认将结构体属性的大驼峰转换成蛇形列名

  ```go
  type User struct {
    ID        uint      // 列名是 `id`
    Name      string    // 列名是 `name`
    Birthday  time.Time // 列名是 `birthday`
    CreatedAt time.Time // 列名是 `created_at`
  }
  ```

- 可以使用 `column` 标签来覆盖列名

  ```go
  type Animal struct {
    AnimalID int64     `gorm:"column:beast_id"`         // 将列名设为 `beast_id`
    Birthday time.Time `gorm:"column:day_of_the_beast"` // 将列名设为 `day_of_the_beast`
    Age      int64     `gorm:"column:age_of_the_beast"` // 将列名设为 `age_of_the_beast`
  }
  ```

**主键**：默认情况下，GORM 使用一个名为`ID` 的字段作为每个模型的默认主键。

- GORM 会使用 `ID` 作为表的主键。

  ```go
  type User struct {
    ID   string // 默认情况下，名为 `ID` 的字段会作为表的主键
    Name string
  }
  ```

- 你可以通过标签 `primaryKey` 将其它字段设为主键

  ```go
  // 将 `UUID` 设为主键
  type Animal struct {
    ID     int64
    UUID   string `gorm:"primaryKey"`
    Name   string
    Age    int64
  }
  ```

**时间戳字段**：GORM使用字段 `CreatedAt` 和 `UpdatedAt` 来自动跟踪记录的创建和更新时间。

- 对于有 `CreatedAt` 字段的模型，创建记录时，如果该字段值为零值，则将该字段的值设为当前时间
- 对于有 `UpdatedAt` 字段的模型，更新记录时，将该字段的值设为当前时间。创建记录时，如果该字段值为零值，则将该字段的值设为当前时间

## 2.3 连接数据库

```go
var db *gorm.DB

func init() {
	var err error
	dsn := "root:123456Aa.@tcp(127.0.0.1:3306)/test" // 数据库信息
	db, err = gorm.Open(mysql.Open(dsn), &gorm.Config{
		Logger: logger.Default.LogMode(logger.Info)}) // 连接数据库，设置日志等级
	if err != nil {
		log.Panicln(err)
	}
}
```



## 2.4 迁移

### 2.4.1 建表

`Migrator()`接口中的`CreateTable()`来将结构体转换成数据库中的表。

```go
type UserAccount struct {
	ID         int       // id 默认被 GORM 设置成primaryKey
	UserNo     int       `gorm:"not null;type:int"` // user_no
	Birth_date time.Time // birth_date
	FirstName  string    `gorm:"type:varchar(48)"` // first_name
	LastName   string    `gorm:"type:varchar(48)"` // last_name
	Gender     int       `gorm:"size:3"`           // gender
	HireDate   time.Time // hire_date
}

func main() {
	err := db.Migrator().CreateTable(&UserAccount{})
	if err != nil {
		log.Fatal(err)
	}
}
```

GORM生成的建表语句

```sql
CREATE TABLE `user_accounts` (
	`id` BIGINT AUTO_INCREMENT,
	`user_no` BIGINT NOT NULL,
	`birth_date` datetime ( 3 ) NULL,
	`first_name` VARCHAR ( 48 ),
	`last_name` VARCHAR ( 48 ),
	`gender` TINYINT,
	`hire_date` datetime ( 3 ) NULL,
PRIMARY KEY ( `id` ))
```

### 2.4.2 删表 

`Migrator()`接口中的`DropTable()`来将对应结构体的表名从数据库中删除。删除时会忽略、删除外键约束。

```go
func main() {
    err := db.Migrator().DropTable(&UserAccount{})  // 默认删除 user_accounts 表
	if err != nil {
		log.Fatal(err)
	}
}
```

## 2.5 查询

```go
// employees 表的结构体
type Employee struct {
	EmpNo     int    // emp_no
	BirthDate string // birth_date
	FirstName string // first_name
	LastName  string // last_name
	Gender    int    // gender
	HireDate  string // hire_date
}
```

### 2.5.1 单行查询

GORM 提供了 `First`、`Take`、`Last` 方法，以便从数据库中检索单个对象。

```go
func main() {
	var e Employee
	// result := db.First(&e) 		// SELECT * FROM `employees` ORDER BY `employees`.`emp_no` LIMIT 1
	// result := db.Last(&e)  		// SELECT * FROM `employees` ORDER BY `employees`.`emp_no` DESC LIMIT 1
	// result := db.Take(&e) 		// SELECT * FROM `employees` LIMIT 1
	// result := db.Take(&e, 10010) // SELECT * FROM `employees` WHERE `employees`.`emp_no` = 10010 LIMIT 1
	result := db.Take(&e, "last_name = ?", "Simmel") // SELECT * FROM `employees` WHERE last_name = 'Simmel' LIMIT 1

	if result.Error != nil {
		log.Fatal(result.Error) // returns error or nil
	}
	fmt.Println(result.RowsAffected) // 返回找到的记录数
	fmt.Println(e)
}
```

### 2.5.2 多行查询

使用 `Find()` 方法，查询全表，返回多个结果集。可使用切片结构承载。

```go
func main() {
	var e []Employee
	result := db.Find(&e) // SELECT * FROM `employees`

	if result.Error != nil {
		log.Fatal(result.Error) // returns error or nil
	}

	fmt.Println(result.RowsAffected) // 返回找到的记录数
	fmt.Println(e)
}
```

### 2.5.3 条件查询

使用 `Where()`方法加上字符串参数化查询。

```go
func main() {
	var e []Employee

	// SELECT * FROM `employees` WHERE last_name = 'Peha'
	// result := db.Where("last_name = ?", "Peha").Find(&e)

	// SELECT * FROM `employees` WHERE emp_no > 10015
	// result := db.Where("emp_no > ?", 10015).Find(&e)

	// SELECT * FROM `employees` WHERE emp_no in (10015,10020,10005)
	// result := db.Where("emp_no in ?", []int{10015, 10020, 10005}).Find(&e)

	// SELECT * FROM `employees` WHERE last_name like '%p%'
	// result := db.Where("last_name like ?", "%p%").Find(&e)

	// SELECT * FROM `employees` WHERE last_name like '%p%'
	// result := db.Where("last_name like ?", "%p%").Find(&e)

	// SELECT * FROM `employees` WHERE emp_no = '10008' and last_name = 'Kalloufi'
	// result := db.Where("emp_no = ? and last_name = ?", "10008", "Kalloufi").Find(&e)

	// SELECT * FROM `employees` WHERE `employees`.`emp_no` = 10008 AND `employees`.`last_name` = 'Kalloufi'
	result := db.Where(&Employee{EmpNo: 10008, LastName: "Kalloufi"}).Find(&e)

	if result.Error != nil {
		log.Fatal(result.Error) // returns error or nil
	}

	fmt.Println(result.RowsAffected) // 返回找到的记录数
	fmt.Println(e)
}
```

### 2.5.4 选择特定字段

使用 `Select()` 选择需要投影的字段。

```go
func main() {
	var e []Employee

	// SELECT `emp_no`,`first_name`,`last_name` FROM `employees`
	// result := db.Select("emp_no", "first_name", "last_name").Find(&e)
	result := db.Select([]string{"emp_no", "first_name", "last_name"}).Find(&e)

	if result.Error != nil {
		log.Fatal(result.Error) // returns error or nil
	}

	fmt.Println(result.RowsAffected) // 返回找到的记录数
	fmt.Println(e)
}
```

### 2.5.5 排序

使用 `Order()` 对指定字段进行排序，默认升序。支持多字段排序。

```go
func main() {
	var e []Employee

	// SELECT * FROM `employees` ORDER BY emp_no DESC
	// result := db.Order("emp_no DESC").Find(&e)
    
	// SELECT * FROM `employees` ORDER BY first_name DESC,last_name
	result := db.Order("first_name DESC").Order("last_name").Find(&e)

	if result.Error != nil {
		log.Fatal(result.Error) // returns error or nil
	}

	fmt.Println(result.RowsAffected) // 返回找到的记录数
	fmt.Println(e)
}
```

### 2.5.6 分页查询

```go
func main() {
	var e []Employee
	// SELECT * FROM `employees` LIMIT 5
	// result := db.Limit(5).Find(&e)

	// SELECT * FROM `employees` LIMIT 5 OFFSET 5
	result := db.Limit(5).Offset(5).Find(&e)

	if result.Error != nil {
		log.Fatal(result.Error) // returns error or nil
	}

	fmt.Println(result.RowsAffected) // 返回找到的记录数
	fmt.Println(e)
}
```

### 2.5.7 分组查询

- 使用`Rows()`返回所有行，自行获取字段值，但是要用`Table()`指定表名

```go
type Salarie struct {
	EmpNo    int    // emp_no
	Salary   int    // salary
	FromDate string // from_date
	ToDate   string // to_date
}

// 需要定义一个结构体来承接查询后的结果集
type Result struct {
	Id    string
	Count int
}

func main() {
	// SELECT emp_no as id, Max(salary) as count FROM `salaries` GROUP BY `emp_no` HAVING count > 70000
	rows, err := db.Table("salaries").Select("emp_no as id, Max(salary) as count").Group("emp_no").Having("count > 70000").Rows()

	if err != nil {
		log.Fatal(err) // returns error or nil
	}

	var r = Result{}
	// 遍历每一行，填充2个属性的结构体实例
	for rows.Next() {
		rows.Scan(&r.Id, &r.Count)
		fmt.Println(r)
	}
}
```

- 或者使用 `Scan()`填充结构体容器

```go
func main() {
	var r = []*Result{}
	// SELECT emp_no as id, Max(salary) as count FROM `salaries` GROUP BY `emp_no` HAVING count > 70000
	result := db.Table("salaries").Select("emp_no as id, Max(salary) as count").Group("emp_no").Having("count > 70000").Scan(&r)

	if result.Error != nil {
		log.Fatal(result.Error) // returns error or nil
	}

	for _, v := range r {
		fmt.Println(v)
	}
}
```

### 2.5.8 连表查询

使用 `Joins()`方法，搭配一个嵌套的结构体承接结果集。

```go
type Employee struct {
	EmpNo     int    // emp_no
	BirthDate string // birth_date
	FirstName string // first_name
	LastName  string // last_name
	Gender    int    // gender
	HireDate  string // hire_date
}

type Salarie struct {
	EmpNo    int    // emp_no
	Salary   int    // salary
	FromDate string // from_date
	ToDate   string // to_date
}

// 需要定义一个嵌套的结构体来承接查询后的结果集
type Result struct {
	Employee // 结构体嵌套
	Salarie
}

func main() {
	var r = []*Result{}
	// SELECT s.*,e.* FROM salaries as s left join employees as e on s.emp_no = e.emp_no
	result := db.Table("salaries as s").Select("s.*,e.*").Joins("left join employees as e on s.emp_no = e.emp_no").Scan(&r)

	if result.Error != nil {
		log.Fatal(result.Error) // returns error or nil
	}

	for _, v := range r {
		fmt.Println(v)
	}
}
```



## 2.6 新增

`Create()`新增数据就是将结构体实例转换成数据库的结果集。

```go
package main

import (
	"fmt"
	"log"

	"gorm.io/driver/mysql"
	"gorm.io/gorm"
	"gorm.io/gorm/logger"
)

var db *gorm.DB

func init() {
	var err error
	dsn := "root:123456Aa.@tcp(127.0.0.1:3306)/test" // 数据库信息
	db, err = gorm.Open(mysql.Open(dsn), &gorm.Config{
		Logger: logger.Default.LogMode(logger.Info)}) // 连接数据库，设置日志等级
	if err != nil {
		log.Panicln(err)
	}
}

type Employee struct {
	EmpNo     int    // emp_no
	BirthDate string // birth_date
	FirstName string // first_name
	LastName  string // last_name
	Gender    int    // gender
	HireDate  string // hire_date
}

func InsertOne() {
	e := Employee{
		EmpNo:     100030,
		BirthDate: "2002-10-10",
		FirstName: "Tom",
		LastName:  "kelus",
		Gender:    1,
		HireDate:  "2012-10-10",
	}
	result := db.Create(&e)
	fmt.Printf("result: %v\n", result.RowsAffected)
}

func InsertMulti() {
	e1 := Employee{
		EmpNo:     100036,
		BirthDate: "2002-10-10",
		FirstName: "Tom",
		LastName:  "kelus",
		Gender:    1,
		HireDate:  "2012-10-10",
	}
	e2 := Employee{
		EmpNo:     100046,
		BirthDate: "2002-11-11",
		FirstName: "Jeom",
		LastName:  "KLett",
		Gender:    2,
		HireDate:  "2014-12-12",
	}
	result := db.Create([]*Employee{&e1, &e2})
	fmt.Printf("result: %v\n", result.RowsAffected)
}

func main() {
	InsertOne()
	InsertMulti()
}
```

## 2.7 更新

`Update()`方法，支持单行与批量修改。

```go
func main() {
	var e Employee

    // 单行更新 Update
	// UPDATE `employees` SET `last_name`='Jack' WHERE emp_no = 10003
	// result := db.Model(&e).Where("emp_no = ?", 10003).Update("last_name", "Jack")

	// 多行更新 Updates
	// UPDATE `employees` SET `last_name`='Marry',`gender`=1 WHERE emp_no > 10003
	result := db.Model(&e).Where("emp_no > ?", 10003).Updates(Employee{Gender: 1, LastName: "Marry"})

	if result.Error != nil {
		log.Fatal(result.Error) // returns error or nil
	}

	fmt.Println(result.RowsAffected) // 返回找到的记录数
	fmt.Println(e)
}
```



## 2.8 删除

- 单行删除

```go
func main() {
	var e Employee

    // DELETE FROM `employees` WHERE emp_no = '10010'
	// result := db.Where("emp_no = ?", "10010").Delete(&e)
    
    // 指定表的主键删除
	result := db.Delete(&e, 10009)
	if result.Error != nil {
		log.Fatal(result.Error) // returns error or nil
	}

	fmt.Println(result.RowsAffected) // 返回找到的记录数
	fmt.Println(e)
}
```

- 批量删除

```go
func main() {
	var e Employee

	// DELETE FROM `employees` WHERE emp_no >= '100030'
	// result := db.Where("emp_no >= ?", "100030").Delete(&e)

	// DELETE FROM `employees` WHERE `employees`.`emp_no` IN (10005,10006,1007)
	result := db.Delete(&e, []int{10005, 10006, 1007})
	if result.Error != nil {
		log.Fatal(result.Error) // returns error or nil
	}

	fmt.Println(result.RowsAffected) // 返回找到的记录数
	fmt.Println(e)
}
```

