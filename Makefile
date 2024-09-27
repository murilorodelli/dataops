# Docker Compose command
DOCKER_COMPOSE = docker compose

# Docker command
DOCKER = docker

# Colors and glyphs
RED=\033[0;31m
GREEN=\033[0;32m
YELLOW=\033[1;33m
NC=\033[0m # No Color
HR := $(shell printf '%*s\n' "$$(tput cols)" '' | tr ' ' '-')

CHECK_MARK = \xE2\x9C\x94
CROSS_MARK = \xE2\x9C\x98


# ----------------------------------
# Linting and testing
# ----------------------------------

venv:
	@test -d .venv || scripts/env_init


bandit: venv
	@echo "$(YELLOW)$(HR)🔒 Running Bandit security checks...\n$(HR)$(NC)"
	@. .venv/bin/activate && bandit --exit-zero -c pyproject.toml -r src

black: venv
	@echo "$(YELLOW)$(HR)♠️ Running Black code formatter..\n$(HR)$(NC)"
	@. .venv/bin/activate && black --color src

flake8: venv
	@echo "$(HR)"
	@echo "📏 Running Flake8 style checks..."
	@echo "$(HR)"
	@. .venv/bin/activate && flake8 src

isort: venv
	@echo "$(HR)"
	@echo "📚 Sorting imports with isort..."
	@echo "$(HR)"
	@. .venv/bin/activate && isort --settings-path=pyproject.toml src

mypy: venv
	@echo "$(HR)"
	@echo "🔍 Running Mypy type checks..."
	@echo "$(HR)"
	@. .venv/bin/activate && mypy --config-file=pyproject.toml --install-types --non-interactive --pretty src

pylint: venv
	@echo "$(HR)"
	@echo "$(YELLOW)🚦 Running Pylint style and error detection checks...$(NC)"
	@echo "$(HR)"
	@. .venv/bin/activate && pylint src

pydocstyle: venv
	@echo "$(HR)"
	@echo "$(YELLOW)📖 Checking docstring conventions with Pydocstyle...$(NC)"
	@echo "$(HR)"
	@. .venv/bin/activate && pydocstyle --config=pyproject.toml --verbose src

radon: venv
	@echo "$(HR)"
	@echo "$(YELLOW)🧮 Running Radon complexity and maintainability checks...$(NC)"
	@echo "$(HR)"
	@. .venv/bin/activate && radon cc -na -sa src
	@. .venv/bin/activate && radon mi -s src

test: venv
	@echo "$(HR)"
	@echo "$(GREEN)🧪 Running tests...$(NC)"
	@echo "$(HR)"
	@. .venv/bin/activate && pytest tests

