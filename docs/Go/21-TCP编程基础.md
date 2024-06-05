# 一、服务端编程原理

## 1.1 CS 编程

Socket 编程，是完成一端和另一端通信的，注意一般来说这两端分别处在不同的进程中，也就是说网络通信是一个进程发消息到另外一个进程。

从业务角度来说，这两端从角色上分为：

1. 主动发送请求的一端，称为客户端 Client
2. 被动接受请求并回应的一端，称为服务端 Server

## 1.2 服务端编程

服务端主要作用是接收客户端的请求，处理，返回三大步。

其中接收客户端请求就需要建立Socket实例，主要的步骤有：

1. 创建 Socket Server 实例
2. bind 绑定 IP 地址 Address 和端口 Port
3. listen 开始监听，将在指定的 IP 的端口上监听
4. accept 返回一个新的 Socket 对象接收数据
5. recv 接收客户端的消息并处理
6. send 返回给客户端处理后的消息
7. close 关闭 accept 实例
8. close 关闭 Sokcet Server 实例

TCP Server 端通信原理图：

![image-20240205161507938](./socket%20%E7%BC%96%E7%A8%8B%E5%9F%BA%E7%A1%80/image-20240205161507938.png)

# 二、单线程、单次通信

单线程通信，一次只能建立一个连接，并且通信一次。

## Python 实现

```python
import socket

if __name__ == '__main__':
    # 创建一个 socket 实例
    server = socket.socket()
    # 给 server 绑定 ip 与 端口
    server.bind(("0.0.0.0", 9999))
    # 启动服务监听
    server.listen()
    # 客户端握手连接成功后，返回一个新socket实例用于接收消息
    conn, raddr = server.accept()
    print(1, f"连接建立：{conn}")
    # 阻塞主线程，等待客户端发送消息过来
    data = conn.recv(1024)
    print(2, f"接收到客户端的信息：{data}")
    # 返回给客户端的消息
    conn.send(data)
    # 关闭 conn 实例连接
    conn.close()
    print(3, "连接关闭")
    # 关闭 socket 主实例连接
    server.close()
    print(4, "进程结束")
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

# 三、多线程、多次通信

将阻塞的accept封装成函数，放入线程中，实现多线程，可接收多条连接请求。

只需将recv放入循环，即可指定与客户端通信的次数。

这样就实现了”多线程+阻塞IO“的 TCP 服务器。

缺点：

- 线程中，有IO操作，当前线程则会阻塞
- 如果接收到的请求太多，则会分配很多线程，线程的创建消耗很废时间和内存资源。

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

# 四、线程池版TCP服务器

系统启动一个新线程的成本是比较高的，因为它涉及与操作系统的交互。

在这种情形下，使用线程池可以很好地提升性能，尤其是当程序中需要创建大量生存期很短暂的线程时，更应该考虑使用线程池。

当请求建立连接后，线程池新建线程进行服务，通信结束，连接断开后，线程不销毁，直接用来接收下一个请求，这样可以节省频繁创建、销毁线程的资源。

```python
import socket
import threading
import time
from concurrent.futures import ThreadPoolExecutor

# 设置当前线程池的最大线程数
count = 3
executor = ThreadPoolExecutor(count)


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
    while True:
        # 客户端握手连接成功后，返回一个新socket实例用于接收消息
        conn, raddr = server.accept()
        print(1, f"连接建立：{conn}")
        executor.submit(recv, conn, raddr)


if __name__ == '__main__':
    # 定义一个 Socket 监听实例
    server = socket.socket()
    # 配置监听的IP和端口
    laddr = ("0.0.0.0", 29999)
    # 绑定
    server.bind(laddr)
    # 开启监听队列，1024个容量
    server.listen(1024)
    # 开启一个线程池，运行接收客户端消息的实例
    executor.submit(accept, server)
    while True:
        # 每三秒打印存活的线程
        time.sleep(3)
        print(threading.enumerate())
```

使用线程池方案，可以拥有海量线程来处理并发客户端请求，但是线程调度时上下文切换将给系统造成巨大的性能消耗，该问题程序层面目前解决不了。

使用操作系统层面解决：非阻塞IO、IO多路复用。

# 五、IO多路复用版

IO过程分两阶段： 

1. 数据准备阶段。从设备读取数据到内核空间的缓冲区
2. 内核空间复制回用户空间进程缓冲区阶段

系统调用—— read函数、recv函数等。

## 同步阻塞IO

<img src="./21-TCP%E7%BC%96%E7%A8%8B%E5%9F%BA%E7%A1%80/image-20240603172348939.png" alt="image-20240603172348939" style="zoom: 67%;" />

## 同步非阻塞IO

进程调用 recvfrom 操作，如果IO设备没有准备好，立即返回ERROR，进程不阻塞。

用户可以再次发起系 统调用（可以轮询），如果内核已经准备好，就阻塞，然后复制数据到用户空间。

虽然不阻塞，但是不断轮询，CPU处于忙等。

<img src="./21-TCP%E7%BC%96%E7%A8%8B%E5%9F%BA%E7%A1%80/image-20240603172451793.png" alt="image-20240603172451793" style="zoom:67%;" />

## IO多路复用

也称Event-driven IO。

所谓IO多路复用，就是利用操作系统提供的多路选择器（select/poll/epoll等）同时监控多个IO，称为多路IO，哪怕只有一路准备好了，就不需要等了就可以开始处理这一路的数据。

这种方式提高了同时处理 IO的能力。

<img src="./21-TCP%E7%BC%96%E7%A8%8B%E5%9F%BA%E7%A1%80/image-20240603172548334.png" alt="image-20240603172548334" style="zoom: 67%;" />

select几乎所有操作系统平台都支持，poll是对的select的升级。

epoll，Linux系统内核2.5+开始支持， 对select和poll的增强，在监视的基础上，减少数据在用户态和内核态之间的反复复制，增加回调机制。 

epoll与select相比，解决了select监听fd的限制和O(n)遍历位图效率问题，提供回调机制等，效率更高。 

以select为例，将关注的IO操作告诉select函数并调用，进程阻塞，内核“监视”select关注的文件描述符 fd，被关注的任何一个fd对应的IO准备好了数据，select返回。再使用read将数据复制到用户进程。

