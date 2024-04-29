# 基本用法

```go
package main

import (
	"database/sql"
	"fmt"
	"log"
	"time"

	_ "github.com/go-sql-driver/mysql" // 驱动安装和导入
)

var db *sql.DB

func init() {
	var err error
	dsn := "root:123456Aa.@tcp(110.41.160.251:3310)/test" // 数据库信息
	db, err = sql.Open("mysql", dsn)                      // 连接数据库
	if err != nil {
		log.Panicln(err)
	}
	db.SetConnMaxLifetime(time.Second * 30) // 设置最大连接超时时间
	db.SetMaxOpenConns(0)                   // 设置最大连接数，0 表示不限制
	db.SetMaxIdleConns(10)                  // 设置最大空闲连接数
}

// 和字段对应的变量或结构体定义，最好和数据库中字段顺序对应
type Emp struct {
	emp_no                int
	birth_date            string
	first_name, last_name string
	gender                int
	hire_date             string
}

func main() {
	// 查询语句,? 代表参数的占位符，有参数几个就用几个？
	query := "select * from employees where emp_no = ? or emp_no = ?"
	arg := []any{10002, 10019}
	var e Emp
	// 1、单行查询
	row := db.QueryRow(query, arg...)
	err := row.Scan(&e.emp_no, &e.birth_date, &e.first_name, &e.last_name, &e.gender, &e.hire_date)
	if err != nil {
		log.Println(err)
	}
	fmt.Println(e)
	fmt.Println("~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~")

	// 2、多行查询
	rows, err := db.Query(query, arg...)
	if err != nil {
		log.Panicln(err)
	}
	for rows.Next() {
		err := rows.Scan(&e.emp_no, &e.birth_date, &e.first_name, &e.last_name, &e.gender, &e.hire_date)
		if err != nil {
			log.Panicln(err)
		}
		fmt.Println(e)
	}
}
```



# 预编译防止SQL注入

```go
package main

import (
	"database/sql"
	"fmt"
	"log"
	"time"

	_ "github.com/go-sql-driver/mysql" // 驱动安装和导入
)

var db *sql.DB

func init() {
	var err error
	dsn := "root:123456Aa.@tcp(110.41.160.251:3310)/test" // 数据库信息
	db, err = sql.Open("mysql", dsn)                      // 连接数据库
	if err != nil {
		log.Panicln(err)
	}
	db.SetConnMaxLifetime(time.Second * 30) // 设置最大连接超时时间
	db.SetMaxOpenConns(0)                   // 设置最大连接数，0 表示不限制
	db.SetMaxIdleConns(10)                  // 设置最大空闲连接数
}

// 和字段对应的变量或结构体定义，最好和数据库中字段顺序对应
type Emp struct {
	emp_no                int
	birth_date            string
	first_name, last_name string
	gender                int
	hire_date             string
}

func main() {
	// 查询语句,? 代表参数的占位符，有参数几个就用几个？
	query := "select * from employees where emp_no = ? or emp_no = ?;"
	// 使用db.Prepare预编译并使用参数化查询，防止SQL注入攻击
	stmt, err := db.Prepare(query)
	if err != nil {
		log.Panicln(err)
	}
	defer stmt.Close()

	arg := []any{10002, "10019 or 1 = 1"}
	var e Emp

	rows, err := stmt.Query(arg...)
	if err != nil {
		log.Panicln(err)
	}
	for rows.Next() {
		err := rows.Scan(&e.emp_no, &e.birth_date, &e.first_name, &e.last_name, &e.gender, &e.hire_date)
		if err != nil {
			log.Panicln(err)
		}
		fmt.Println(e)
	}
}

```

