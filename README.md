# Cobalt Strike Docker

This project provides a simple way to build and run a Cobalt Strike team server in a Docker container. It includes a Dockerfile for building the image, a shell script for automation, and a sample Malleable C2 profile.

## Prerequisites

Before you begin, ensure you have the following installed:

- [Docker](https://www.docker.com/get-started)
- A valid Cobalt Strike license key

## Files

- **`Dockerfile`**: Defines the Docker image for the Cobalt Strike team server. It installs the necessary dependencies, downloads and installs Cobalt Strike, and sets up the container environment.
- **`cobalt-docker.sh`**: A shell script that automates the process of building the Docker image and running the container. It prompts for your Cobalt Strike license key and a password for the team server.
- **`malleable.profile`**: A sample Malleable C2 profile to customize the appearance of your Cobalt Strike traffic.

## Setup and Usage

1.  **Clone the repository:**

    ```bash
    git clone <repository-url>
    cd <repository-name>
    ```

2.  **Make the script executable:**

    ```bash
    chmod +x cobalt-docker.sh
    ```

3.  **Run the script:**

    ```bash
    ./cobalt-docker.sh
    ```

    The first time you run the script, it will prompt you for your Cobalt Strike license key and a password for the team server. These credentials will be saved in a `.env` file in the project directory.

    For subsequent runs, the script will automatically load the credentials from the `.env` file, so you won't be prompted again.

The script will then build the Docker image (if not already built or if changes are detected) and start the Cobalt Strike team server in a container. The server will be accessible on your host machine at the IP address displayed in the script's output.

## Disclaimer

This project is intended for authorized and ethical use only. Cobalt Strike is a powerful tool that can be used for malicious purposes. By using this project, you agree to use it in a responsible and legal manner. The author is not responsible for any misuse of this project.
