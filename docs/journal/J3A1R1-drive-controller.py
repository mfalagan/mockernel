#!/usr/bin/env python3
import queue
import signal
import socket
import subprocess
import sys
import threading


LISTEN_HOST = "0.0.0.0"
LISTEN_PORT = 873  # rsync port

QUEUE_MAX = 32
SESSION_TIMEOUT = 0.1

RSYNC_CMD = [
    "/usr/bin/rsync",
    "--daemon",
    "--no-detach",
    "--config=/petdrive/handler/rsyncd.conf",
]

IMAGE_LOCK_CMD = ["/petdrive/handler/image-lock"]
IMAGE_FREE_CMD = ["/petdrive/handler/image-free"]


pending = queue.Queue(maxsize=QUEUE_MAX)
stop_event = threading.Event()

listener = None
fatal_error = None
image_locked = False


def log(msg):
    print(msg, flush=True)


def request_shutdown(reason=None):
    global listener, fatal_error

    if fatal_error is None:
        fatal_error = reason

    stop_event.set()

    s = listener
    if s is not None:
        try:
            s.close()
        except OSError:
            pass


def handle_shutdown_signal(signum, frame):
    log(f"signal {signum}")
    request_shutdown()


def run_hook(argv, name):
    log(f"{name}: start")
    subprocess.run(argv, check=True)
    log(f"{name}: done")


def ensure_locked():
    global image_locked

    if image_locked:
        return

    run_hook(IMAGE_LOCK_CMD, "image-lock")
    image_locked = True


def ensure_free():
    global image_locked

    if not image_locked:
        return

    run_hook(IMAGE_FREE_CMD, "image-free")
    image_locked = False


def close_connection(conn):
    try:
        conn.shutdown(socket.SHUT_RDWR)
    except OSError:
        pass

    try:
        conn.close()
    except OSError:
        pass


def serve_connection(conn, addr):
    log(f"serving {addr[0]}:{addr[1]}")

    try:
        proc = subprocess.Popen(
            RSYNC_CMD,
            stdin=conn,
            stdout=conn,
            stderr=None,
            close_fds=True,
        )
        rc = proc.wait()
        log(f"rsync exit {addr[0]}:{addr[1]} rc={rc}")
    finally:
        close_connection(conn)


def worker_loop():
    timeout = 0.5

    while not stop_event.is_set():
        try:
            conn, addr = pending.get(timeout=timeout)
            timeout = SESSION_TIMEOUT
            ensure_locked()
            serve_connection(conn, addr)

        except queue.Empty:
            ensure_free()
            timeout = 0.5


def worker_main():
    try:
        worker_loop()

    except Exception as exc:
        log(f"fatal worker error: {exc!r}")
        request_shutdown(exc)

    finally:
        ensure_free()


def listener_loop():
    global listener

    while not stop_event.is_set():
        try:
            conn, addr = listener.accept()
            conn.setblocking(True)
            pending.put_nowait((conn, addr))
            log(f"queued {addr[0]}:{addr[1]} depth={pending.qsize()}")

        except queue.Full:
            log(f"dropping {addr[0]}:{addr[1]} queue full")
            close_connection(conn)


def listener_main():
    global listener

    try:
        if socket.has_dualstack_ipv6():
            s = socket.create_server(
                ("::", LISTEN_PORT),
                family=socket.AF_INET6,
                backlog=QUEUE_MAX,
                dualstack_ipv6=True,
            )
        else:
            s = socket.create_server(
                (LISTEN_HOST, LISTEN_PORT),
                family=socket.AF_INET,
                backlog=QUEUE_MAX,
            )

        with s:
            listener = s
            log(f"listening on {LISTEN_HOST}:{LISTEN_PORT} queue_max={QUEUE_MAX}")

            listener_loop()

    except Exception as exc:
        log(f"fatal listener error: {exc!r}")
        request_shutdown(exc)

    finally:
        listener = None


def main():
    signal.signal(signal.SIGINT, handle_shutdown_signal)
    signal.signal(signal.SIGTERM, handle_shutdown_signal)

    worker = threading.Thread(target=worker_main, name="worker")
    worker.start()

    listener_main()

    worker.join()

    if fatal_error is not None:
        return 1

    return 0


if __name__ == "__main__":
    sys.exit(main())