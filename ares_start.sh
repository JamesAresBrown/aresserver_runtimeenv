#!/bin/sh

# Function to stop and remove a container
stop_and_remove_container() {
    local container_name=$1
    if [ "$(docker ps -q -f name=$container_name)" ]; then
        echo "Stopping existing container: $container_name"
        docker stop $container_name
        docker rm $container_name
    fi
}

# Parse command line options
MODE=$1
case "$MODE" in
    start)
        # Check if base path is provided
        if [ $# -ne 2 ]; then
            echo "Usage: $0 start <base_path>"
            exit 1
        fi
        BASE_PATH=$2

        # Define container names
        MYSQL_CONTAINER_NAME="mysql_container"
        REDIS_CONTAINER_NAME="redis_container"
        UBUNTU_CONTAINER_NAME="ubuntu_container"

        # Stop and remove existing containers
        stop_and_remove_container $MYSQL_CONTAINER_NAME
        stop_and_remove_container $REDIS_CONTAINER_NAME
        stop_and_remove_container $UBUNTU_CONTAINER_NAME

        # Start MySQL container
        docker run -d -p 3306:3306 --privileged=true \
            -v $BASE_PATH/mysql/log:/var/log/mysql \
            -v $BASE_PATH/mysql/data:/var/lib/mysql \
            -v $BASE_PATH/mysql/conf:/etc/mysql/conf.d \
            -e MYSQL_ROOT_PASSWORD=320510 \
            --name $MYSQL_CONTAINER_NAME \
            mysql:5.7

        if [ $? -ne 0 ]; then
            echo "Failed to start MySQL container."
            exit 1
        fi

        # Start Redis container
        docker run -d -p 6379:6379 --privileged=true \
            -v $BASE_PATH/redis/redis.conf:/etc/redis/redis.conf \
            -v $BASE_PATH/redis/data:/data \
            -v $BASE_PATH/redis/log:/var/log \
            --name $REDIS_CONTAINER_NAME \
            redis:6.0.8 /etc/redis/redis.conf

        if [ $? -ne 0 ]; then
            echo "Failed to start Redis container."
            exit 1
        fi

        # Start Ubuntu server container
	# ubuntu环境暴露22用于ssh。暴露80用于http。
	# 数据卷1：服务器相关文件 数据卷2：启动文件 数据卷3：CLion环境
        docker run -it -d -p 22201:22 -p 80:80 \
            -v $BASE_PATH/server:/tmp/data \
	    -v $BASE_PATH/server/AresServer/script/auto_restart_server.sh:/tmp/start.sh \
	    -v $BASE_PATH/server/codingenv:/codingenv \
            --name $UBUNTU_CONTAINER_NAME \
            aresubuntu:2.0

        if [ $? -ne 0 ]; then
            echo "Failed to start Ubuntu server container."
            exit 1
        fi

        echo "All containers started successfully."
        ;;
    stop)
        # Stop and remove all containers without needing base path
        stop_and_remove_container mysql_container
        stop_and_remove_container redis_container
        stop_and_remove_container ubuntu_container

        echo "All containers stopped and removed successfully."
        ;;
    *)
        echo "Usage: $0 {start <base_path>|stop}"
        exit 1
        ;;
esac

exit 0

