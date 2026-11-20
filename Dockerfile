FROM squidfunk/mkdocs-material:9.8.2
COPY requirements.txt .
RUN pip install -r requirements.txt
