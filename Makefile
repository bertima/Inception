RED=\033[0;31m
GREEN=\033[0;32m
BLUE=\033[0;34m
YELLOW=\033[1;33m
END=\033[0m

SRC = srcs
ENV_FILE = srcs/.env
VOLUME_LOCAL = /home/$(USER)/data/

-include $(ENV_FILE)
DOMAIN = $(DOMAIN_NAME)


#==================================== RUN ====================================#


all: check_config up 


up: check_config
	@cd $(SRC) && docker compose up --build -d
	@echo "$(GREEN)BUILD AND RUN IMAGE$(END)"


build: check_config
	@cd $(SRC) && docker compose build
	@echo "$(GREEN)IMAGE CREATED$(END)"


#==================================== CHECK ====================================#


version:
	@echo "$(BLUE)DOCKER VERSION:$(END)"
	@docker --version
	@echo "\n$(BLUE)DOCKER COMPOSE VERSION:$(END)"
	@docker compose version


status:
	@echo "$(BLUE)DOCKER PROCESS STATUS ALL:$(END)"
	@docker ps -a

	@echo "\n$(BLUE)DOCKER IMAGES ALL:$(END)"
	@docker images -a
	
	@echo "\n$(BLUE)DOCKER VOLUME:$(END)"
	@docker volume ls

	@echo "\n$(BLUE)DOCKER NETWORK ALL:$(END)"
	@docker network ls

	@echo "\n$(BLUE)DOCKER SYSTEM:$(END)"
	@docker system df
	@echo ""


check_env:
	@if [ -f $(ENV_FILE) ]; then \
		echo "$(GREEN).env exist$(END)"; \
	else \
		echo "$(RED).env IS MISSING, CREAT THEN BEFORE CONTINUE$(END)"; \
		exit 1; \
	fi



check_domain:
	@if ! grep -q "$(DOMAIN)" /etc/hosts; then \
		echo "127.0.0.1 $(DOMAIN)" | sudo tee -a /etc/hosts > /dev/null; \
		echo "$(YELLOW)$(DOMAIN) ADDED TO /etc/hosts.$(END)"; \
	else \
		echo "$(GREEN)$(DOMAIN) exist.$(END)"; \
	fi

check_certificate:
	@if [ ! -d "$(VOLUME_LOCAL)/nginx" ]; then \
		echo "$(RED)Creat folder : $(VOLUME_LOCAL)/nginx for creat certificate$(END)"; \
		exit 1; \
	fi

	@if [ ! -f /home/$(USER)/data/nginx/inception.crt ]; then \
		openssl req -x509 -nodes -days 365 \
			-newkey rsa:2048 \
			-keyout /home/$(USER)/data/nginx/inception.key \
			-out /home/$(USER)/data/nginx/inception.crt \
			-subj "/C=FR/ST=IDF/L=Paris/O=42/OU=42/CN=$(DOMAIN)" \
			> /dev/null 2>&1; \
		echo "$(YELLOW)Certificate CREATED.$(END)"; \
	else \
		echo "$(GREEN)Certificate exist.$(END)"; \
	fi


check_path_volume:
	@if [ -d "$(VOLUME_LOCAL)" ]; then \
		echo "$(GREEN)Volume local already exist: $(VOLUME_LOCAL)$(END)"; \
	else \
		echo "$(YELLOW)Creating volume local: $(VOLUME_LOCAL)$(END)"; \
		mkdir -p $(VOLUME_LOCAL); \
	fi

	@if [ -d "$(VOLUME_LOCAL)/nginx" ]; then \
		echo "$(GREEN)Volume local already exist: $(VOLUME_LOCAL)/nginx$(END)"; \
	else \
		echo "$(YELLOW)Creating volume local: $(VOLUME_LOCAL)/nginx$(END)"; \
		mkdir -p $(VOLUME_LOCAL)/nginx; \
	fi

	@if [ -d "$(VOLUME_LOCAL)/html" ]; then \
		echo "$(GREEN)Volume local already exist: $(VOLUME_LOCAL)/html$(END)"; \
	else \
		echo "$(YELLOW)Creating volume local: $(VOLUME_LOCAL)/html$(END)"; \
		mkdir -p $(VOLUME_LOCAL)/html; \
	fi

	@if [ -d "$(VOLUME_LOCAL)/mariadb" ]; then \
		echo "$(GREEN)Volume local already exist: $(VOLUME_LOCAL)/mariadb$(END)"; \
	else \
		echo "$(YELLOW)Creating volume local: $(VOLUME_LOCAL)/mariadb$(END)"; \
		mkdir -p $(VOLUME_LOCAL)/mariadb; \
		sudo chown -R bertrmar:bertrmar $(VOLUME_LOCAL)/mariadb; \
	fi


check_config: check_env check_domain check_path_volume check_certificate


#==================================== CLEAR ====================================#


down:
	@cd srcs && docker compose down -v --rmi all
	@echo "$(RED)CONTAINERS, NETWORK AND IMAGES BUILD BY DOCKER COMPOSE REMOVE$(END)"


suppress:
	@if [ -n "$$(docker ps -q)" ]; then \
		echo "$(RED)STOP CONTAINERS:$(END)"; \
		docker stop $$(docker ps -q); \
	else \
		echo "$(YELLOW)No containers to stop$(END)"; \
	fi

	@if [ -n "$$(docker ps -aq)" ]; then \
		echo "\n$(RED)SUPPRESS CONTAINERS:$(END)"; \
		docker rm -f $$(docker ps -aq); \
	else \
		echo "$(YELLOW)No containers to suppress$(END)"; \
	fi

	@if [ -n "$$(docker images -aq)" ]; then \
		echo "\n$(RED)SUPPRESS IMAGES:$(END)"; \
		docker rmi -f $$(docker images -aq); \
	else \
		echo "$(YELLOW)No images to suppress$(END)"; \
	fi


remove_env:
	@if [ -f $(ENV_FILE) ]; then \
		echo "$(RED).env DELETE:$(END)\n"; \
		rm -rf $(ENV_FILE); \
	else \
		echo "$(YELLOW).env DOESN'T EXIST:$(END)"; \
	fi

remove_certificate:
	@if [ -n "ls $(VOLUME_LOCAL)/nginx" ]; then \
		echo "$(RED)Certificate remove$(END)\n"; \
		rm -rf $(VOLUME_LOCAL)/nginx; \
	else \
		echo "$(YELLOW)Certificate DOESN'T EXIST$(END)"; \
	fi

remove_volume:
	@if [ -n "$$(docker volume ls -q)" ]; then \
		echo "\n$(RED)VOLUME REMOVE:$(END)"; \
		docker volume rm  $$(docker volume ls -q); \
	else \
		echo "$(YELLOW)No volume to remove$(END)"; \
	fi

remove_network:
	@if [ -n "$$(docker network ls -q --filter type=custom)" ]; then \
		echo "\n$(RED)NETWORKS REMOVE:$(END)"; \
		docker network rm  $$(docker network ls -q --filter type=custom); \
	else \
		echo "$(YELLOW)No networks to remove$(END)"; \
	fi


remove_volume_local:
	@if [ -d "$(VOLUME_LOCAL)" ]; then \
		echo "$(RED)VOLUME LOCAL REMOVE: $(VOLUME_LOCAL)$(END)"; \
		sudo rm -Rf  $(VOLUME_LOCAL); \
	else \
		echo "$(YELLOW)No volume local to remove$(END)"; \
	fi


remove_cache:
	@echo "\n$(RED)CACHE REMOVE:$(END)"
	@docker system prune -af --volumes
	@docker buildx prune -af 


clean: suppress remove_network remove_volume


fclean: clean remove_certificate remove_volume_local remove_cache 


re: clean all

fre: fclean all


#==================================== PHONY ====================================#


.PHONY: all up build \
		check_config check_domain check_env check_path_volume check_certificate\
		version status \
		down supress remove_cache remove_volume remove_volume_local remove_network \
		clean fclean re fre