# Use the Alpine Linux-based Python 3 image for ARM
FROM python

# Set the working directory in the container
WORKDIR /app

# Copy the current directory contents into the container at /app
COPY . /app

# Install any needed packages specified in requirements.txt
RUN pip3 install --no-cache-dir -r requirements.txt

# Expose the port on which your Flask app runs
expose 6005

# Run the Flask application
CMD ["python3", "app.py"]
