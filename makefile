
ALL: start run
	
start:
	docker run --name bdbcomp-server -e MYSQL_ROOT_PASSWORD=root -e TERM=xterm-256color -v $(shell pwd)/:/host/ -d mariadb


stop:
	docker stop bdbcomp-server
	docker rm bdbcomp-server

restart: stop start
	

run:
	#docker exec -it bdbcomp-server /usr/bin/mysql -u root -proot
	docker exec -it bdbcomp-server /bin/bash
