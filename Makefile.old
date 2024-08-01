# Define variables
VENV := .venv
PYTHON := $(VENV)/bin/python
PIP := $(VENV)/bin/pip
TEST := $(VENV)/bin/pytest

# Default target
.DEFAULT_GOAL := install

# Create virtual environment
$(VENV)/bin/activate: requirements.txt
	python3 -m venv $(VENV)
	$(PIP) install --upgrade pip
	$(PIP) install -r requirements.txt

# Install dependencies
install: $(VENV)/bin/activate
	@echo "Dependencies installed."

# Run tests
test: $(VENV)/bin/activate
	$(TEST)

# Clean up
clean:
	rm -rf $(VENV)
	@echo "Cleaned up."

# Lint the code
lint: $(VENV)/bin/activate
	$(PYTHON) -m flake8 .

# Format the code
format: $(VENV)/bin/activate
	$(PYTHON) -m black .

# Run the application
run: $(VENV)/bin/activate
	$(PYTHON) main.py
