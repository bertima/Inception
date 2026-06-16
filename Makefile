NAME   		=	webserv
SRC_DIR		=	src
INCL_DIR	=	includes
OBJ_DIR		= 	obj

OBJ			=	$(patsubst %.cpp,$(OBJ_DIR)/%.o,$(SRC))

all: $(NAME)

$(OBJ_DIR):
	mkdir -p $(OBJ_DIR)
	mkdir -p $(OBJ_DIR)/src

$(OBJ_DIR)/%.o: %.cpp | $(OBJ_DIR)
	$(CC) $(FLAGS) -c $< -o $@

$(NAME): $(OBJ)
	$(CC) $(FLAGS) $(OBJ) -o $(NAME)

m ?= update

push:
	@$(MAKE) fclean
	git add .
	git commit -m "$(m)"
	git push
	@echo -e "\033[32mPROGRAM Push on git with message:\033[0m" "$(m)"

clean:
	rm -rf $(OBJ_DIR) 
	@echo -e "\033[34mALL .O FILES SUCCESSFULLY DELETED\033[0m"

test: $(OBJ)
	clear
	$(CC) $(FLAGS) $(OBJ) -o $(NAME)
	valgrind --leak-check=full --track-fds=yes ./$(NAME) 


fclean: clean
	rm -f $(NAME)
	@echo -e "\033[35mPROGRAM SUCCESSFULLY DELETED\033[0m"

re: fclean all

.PHONY: all clean fclean re test push