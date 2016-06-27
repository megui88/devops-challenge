#!/bin/bash
cd /var/docker/
NEW_INSTANCE="app"$(date '+%d%m%Y%H%M%S');
NEW_COMPOSE_FILE="./app-"$NEW_INSTANCE".yml"
IMAGE=$1
TAG=$2
init_app(){
        OLD=$(ls | grep app |cut -c5- |rev |cut -c5- |rev)
        FIRST=$(docker ps | grep docker_app_1)

        rm -f app-*.yml
        cp ./docker-compose.yml $NEW_COMPOSE_FILE

        if [[ ! -z "$IMAGE" && ! -z "$TAG" ]]
        then
            sed -i "/image: tactivos/c\    image: $IMAGE:$TAG" $NEW_COMPOSE_FILE
        fi

        sed -i "s/9001://g" $NEW_COMPOSE_FILE
        sed -i "s/app/$NEW_INSTANCE/g" $NEW_COMPOSE_FILE
        echo "Updating images"
        docker-compose -f $NEW_COMPOSE_FILE pull
        docker-compose -f $NEW_COMPOSE_FILE up -d
        echo "upstream app_servers {server $(docker port "docker_"$NEW_INSTANCE"_1" 3000);}" > /etc/nginx/sites-available/app_upstream.conf
        kill -HUP $(cat /var/run/nginx.pid)
        echo "reload nginx"
        service nginx reload

        if [[ ! -z "$FIRST" ]]
        then
            echo "stopping container docker_app_1"
            docker stop docker_app_1
        fi

        if [[ ! -z "$OLD" ]]
        then
	        echo "stopping container docker_${OLD}_1"
            docker stop "docker_${OLD}_1"
        fi

        return 1
}
init_app
