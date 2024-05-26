# Use an appropriate base image
FROM python:3.12-slim

# Install system dependencies for Playwright
RUN apt-get update && apt-get install -y \
    libwoff1 \
    libopus0 \
    libwebpdemux2 \
    libharfbuzz-icu0 \
    libenchant-2-2 \
    libhyphen0 \
    libflite1 \
    libegl1 \
    libgudev-1.0-0 \
    libevdev2 \
    libgles2 \
    gstreamer1.0-libav \
    && rm -rf /var/lib/apt/lists/*

# Install Playwright and its browsers
RUN pip install playwright \
    && playwright install --with-deps chromium

# Set the working directory
WORKDIR /app

# Copy the rest of your application code
COPY . .

# Install Poetry
RUN curl -sSL https://install.python-poetry.org | python3 -

# Install Python dependencies using Poetry
RUN poetry install

# Expose the necessary ports
EXPOSE 3000 3001

# Command to run your application
CMD ["./start.sh"]
