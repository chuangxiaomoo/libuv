# if make

$ sh autogen.sh
$ ./configure
$ make
$ make check
$ make install

# if 1e9 // 1e9 是科学计数法 表示1乘10的9次幂

# if 定时器如何工作？6个phase

https://blog.csdn.net/weixin_33768153/article/details/80336526

int uv_run(uv_loop_t* loop, uv_run_mode mode)
{
    // 0. 更新时间戳
    uv__update_time(loop);
        loop->time = uv__hrtime(UV_CLOCK_FAST)/1000000;    src/unix/linux-core.c|425|

    // 1. 按时间排序的heap，如果最小cb时间未到，则其它的也肯定未到，退出for(;;)
    uv__run_timers(loop);
        for (;;) {
            heap_node = heap_min(timer_heap(loop));
            if (handle->timeout > loop->time) break;
            uv_timer_stop(handle);
            uv_timer_again(handle);
            handle->timer_cb(handle);
        }

    // 2. 根据libuv的文档，一些应该在上轮循环poll阶段执行的callback，因为某些原因不能执行，
    //    就会被延迟到这一轮的循环的I/O callbacks阶段执行。换句话说这个阶段执行的callbacks是上轮残留的。
    ran_pending = uv__run_pending(loop);

    // 3. idle,prepare 仅内部使用。uv__run_idle()、uv__run_prepare()、uv__run_check() 的逻辑非常相似
    //    它们定义在文件 src/unix/loop-watcher.c|48|
    uv__run_idle(loop);
    uv__run_prepare(loop);

    // 4. 最为重要的阶段，执行I/O callback，在适当的条件下会阻塞在这个阶段
    uv__io_poll(loop, timeout);

    // 5. 参见idle和prepare阶段，执行setImmediate的callback
    uv__run_check(loop);

    // 6. 循环关闭所有的closing handles。其中的callback调用在uv__finish_close()中
    uv__run_closing_handles(loop);
}
