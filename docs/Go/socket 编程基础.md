# 原理图

![image-20240205161507938](./socket%20%E7%BC%96%E7%A8%8B%E5%9F%BA%E7%A1%80/image-20240205161507938.png)

# 单线程 socket 通信

## Python 实现

```python
import socket

# 定义一个 Socket 监听实例
server = socket.socket()
laddr = ("0.0.0.0", 19999)
server.bind(laddr)
server.listen()

# 客户端握手连接成功后，返回一个新socket实例用于接收消息
conn, raddr = server.accept()
print(1, f"连接建立：{conn}")
# 阻塞主线程，等待客户端发送消息过来
data = conn.recv(1024)
print(2, f"接收到客户端的信息：{data}")
# 返回给客户端的消息
conn.send(data)
print(3, "连接关闭")

# 关闭socket连接
conn.close()
server.close()
```

## Go 实现

```go
package main

import (
	"log"
	"net"
)

func main() {
	// 1、定义监听的地址、端口和网络协议
	laddr, err := net.ResolveTCPAddr("tcp4", "0.0.0.0:9999")
	if err != nil {
		log.Panicln(err)
	}
	// 2、启动监听server
	server, err := net.ListenTCP("tcp4", laddr)
	if err != nil {
		log.Panicln(err)
	}
	defer server.Close()
	// 3、注册与客户端通信的socket连接
	conn, err := server.Accept()
	if err != nil {
		log.Panicln(err)
	}
	defer conn.Close()
	// 4、接收读取客户端发送的请求，并放入buffer缓冲区。底层为非阻塞模式，但使用起来像同步阻塞。
	buffer := make([]byte, 4096)
	n, err := conn.Read(buffer) // n为接收到的消息的字节长度
	if err != nil {
		log.Panicln(err)
	}
	data := buffer[:n] // 读取buffer中的n个字节长度的数据，即客户端发送的真正的数据
	// 5、实现 echo server，将客户端发送的数据返回给客户端
	conn.Write(data)
}
```



# 多线程、多次通信

## Python 实现

```python
import socket
import threading
import time


def recv(conn, raddr):
    try:
        for i in range(3):
            # 阻塞主线程，等待客户端发送消息过来
            data = conn.recv(1024)
            # 如果客户端断开连接，发送的空消息，则直接退出函数
            if not data:
                print("bye~", raddr)
                return
            print(2, f"接收到客户端的信息：{data}")
            # 返回给客户端的消息
            conn.send(data)
    except Exception as e:
        print(e)
    finally:
        # 关闭socket连接
        conn.close()
        print(3, "连接关闭")


def accept(server):
    i = 1
    while True:
        # 客户端握手连接成功后，返回一个新socket实例用于接收消息
        conn, raddr = server.accept()
        print(1, f"连接建立：{conn}")
        threading.Thread(target=recv, name=f"r-{i}", args=(conn, raddr)).start()
        i += 1


if __name__ == '__main__':
    # 定义一个 Socket 监听实例
    server = socket.socket()
    # 配置监听的IP和端口
    laddr = ("0.0.0.0", 29999)
    # 绑定
    server.bind(laddr)
    # 开启监听队列，1024个容量
    server.listen(1024)
    # 开启一个线程，运行接收客户端消息的实例
    threading.Thread(target=accept, name="ac", args=(server,)).start()
    while True:
        # 每三秒打印存活的线程
        time.sleep(3)
        print(threading.enumerate())

```

## Gorouting 实现

```go
package main

import (
	"fmt"
	"log"
	"net"
	"runtime"
	"time"
)

func main() {
	// 1、定义监听的地址、端口和网络协议，启动监听server
	server, err := net.Listen("tcp4", "0.0.0.0:9999")
	if err != nil {
		log.Panicln(err)
	}
	defer server.Close()

	// 启动一个协程循环注册socket
	go func() {
		for {
			// 2、注册与客户端通信的socket连接
			conn, err := server.Accept()
			if err != nil {
				log.Panicln(err)
			}
			// 启动一个协程，处理客户端请求
			go func(conn net.Conn) {
				defer conn.Close()
				// 3、接收读取客户端发送的请求，并放入buffer缓冲区。
				buffer := make([]byte, 4096)
				n, err := conn.Read(buffer)
				if n == 0 {
					fmt.Printf("客户端%s断开连接。", conn.RemoteAddr().String())
					return
				}
				if err != nil {
					log.Panicln(err)
					return
				}

				data := buffer[:n]
				fmt.Println(string(data))
				// 4、实现 echo server，将客户端发送的数据返回给客户端
				conn.Write(data)
			}(conn)
		}
	}()

	for {
		time.Sleep(5 * time.Second)
		fmt.Println(runtime.NumGoroutine())
	}
}
```

