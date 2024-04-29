# 基本使用

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
	dsn := "root:123456Aa.@tcp(110.41.160.251:3310)/test" // 数据库信息
	db, err = gorm.Open(mysql.Open(dsn), &gorm.Config{
		Logger: logger.Default.LogMode(logger.Info)}) // 连接数据库，设置日志等级
	if err != nil {
		log.Panicln(err)
	}
	fmt.Println("数据库连接成功!")
}

// 约束：不遵守约束就要手动设置对应关系
// 表名：结构体名称为表名去掉s；结构体命名为employee，那么数据库表名就是employees
// 字段名：结构体采用首字母大写的大驼峰字段命名；属性名为FirstName，默认对应数据库表的字段名为first_name
type Emp struct {
	EmpNo               int    `gorm:"primaryKey"`        // 设置为主键
	Birth_date          string `gorm:"column:birth_date"` // 手动设置属性与表字段的对应关系
	FirstName, LastName string
	Gender              int
	HireDate            string
}

type Student struct {
	ID   int    `gorm:"primaryKey;type:tinyint"`
	Name string `gorm:"type:varchar(15);not null"`
	Age  int    `gorm:"type:tinyint;not null"`
}

// 手动设置表名与结构体名称的对应关系
func (Emp) TableName() string {
	return "employees"
}

func main() {
	var s Student
	// 通过结构体迁移创建表students
	db.Migrator().CreateTable(&s)

	var e Emp
	// 查询一行,将查询到的数据塞入实例e中
	result := db.Take(&e)
	fmt.Println("影响的行数：", result.RowsAffected)
	fmt.Printf("查询结果: %v\n", e)

}

```

# 插入数据

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
	dsn := "root:123456Aa.@tcp(110.41.160.251:3310)/test" // 数据库信息
	db, err = gorm.Open(mysql.Open(dsn), &gorm.Config{
		Logger: logger.Default.LogMode(logger.Info)}) // 连接数据库，设置日志等级
	if err != nil {
		log.Panicln(err)
	}
	fmt.Println("数据库连接成功!")
}

// 约束：不遵守约束就要手动设置对应关系
// 表名：结构体名称为表名去掉s；结构体命名为employee，那么数据库表名就是employees
// 字段名：结构体采用首字母大写的大驼峰字段命名；属性名为FirstName，默认对应数据库表的字段名为first_name
type Emp struct {
	EmpNo               int    `gorm:"primaryKey"`        // 设置为主键
	Birth_date          string `gorm:"column:birth_date"` // 手动设置属性与表字段的对应关系
	FirstName, LastName string
	Gender              int
	HireDate            string
}

// 手动设置表名与结构体名称的对应关系
func (Emp) TableName() string {
	return "employees"
}
func InsertOne() {
	e := Emp{
		EmpNo:      100030,
		Birth_date: "2002-10-10",
		FirstName:  "Tom",
		LastName:   "kelus",
		Gender:     1,
		HireDate:   "2012-10-10",
	}
	result := db.Create(&e)
	fmt.Printf("result: %v\n", result.RowsAffected)
}
func InsertMulti() {
	e1 := Emp{
		EmpNo:      100036,
		Birth_date: "2002-10-10",
		FirstName:  "Tom",
		LastName:   "kelus",
		Gender:     1,
		HireDate:   "2012-10-10",
	}
	e2 := Emp{
		EmpNo:      100046,
		Birth_date: "2002-11-11",
		FirstName:  "Jeom",
		LastName:   "KLett",
		Gender:     2,
		HireDate:   "2014-12-12",
	}
	result := db.Create([]*Emp{&e1, &e2})
	fmt.Printf("result: %v\n", result.RowsAffected)
}

func main() {
	InsertOne()
	InsertMulti()
}

```

