RED=\033[0;31m
GREEN=\033[0;32m
BLUE=\033[0;34m
YELLOW=\033[1;33m
END=\033[0m

up:
	@cd srcs && docker compose up --build -d
	@echo "$(GREEN)BUILD AND RUN IMAGE$(END)"


build: 
	@cd srcs && docker compose build
	@echo "$(GREEN)IMAGE CREATED$(END)"


down:
	@cd srcs && docker compose down --rmi all
	@echo "$(RED)CONTAINERS, NETWORK AND IMAGES BUILD BY DOCKER COMPOSE REMOVE$(END)"

clear_containers_and_images:
	@if [ -n "$$(docker ps -aq)" ]; then \
		echo "$(RED)SUPPRESS CONTAINERS:$(END)"; \
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


remove_volume:
	@echo "\n$(RED)VOLUME REMOVE:$(END)"
	@docker volume prune -f


remove_cache:
	@echo "\n$(RED)CACHE REMOVE:$(END)"
	@docker builder prune -af


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
	
	@echo "\n$(BLUE)DOCKER SYSTEM:$(END)"
	@docker system df
	@echo ""

fclean: clear_containers_and_images remove_volume remove_cache


re: fclean all


.PHONY: up build down\
		clear_containers_and_images remove_cache remove_volume\
		version status \
		fclean re