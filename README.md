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
    git clone https://github.com/Maleick/Cobalt-Docker.git
    cd Cobalt-Docker
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

    **Important:** The `.env` file is excluded from version control by the `.gitignore` file, so your credentials will not be uploaded to GitHub or shared with others. If you add other sensitive files, make sure to update `.gitignore` accordingly.

    For subsequent runs, the script will automatically load the credentials from the `.env` file, so you won't be prompted again.


The script will then build the Docker image (if not already built or if changes are detected) and start the Cobalt Strike team server in a container. The server will be accessible on your host machine at the IP address displayed in the script's output.

## Credits & Kudos

- **Cobalt Strike**: This project is based on the Cobalt Strike software by Fortra. You must have a valid license to use Cobalt Strike.
- **Docker**: Thanks to the Docker community for providing the tools and documentation that make containerization easy.
- **Inspiration**: This project was heavily inspired by the following repositories and resources:
  - [White Knight Labs docker-cobaltstrike](https://github.com/WKL-Sec/docker-cobaltstrike) (which itself is based on [warhorse/docker-cobaltstrike](https://github.com/warhorse/docker-cobaltstrike))
  - [ZSECURE/zDocker-cobaltstrike](https://github.com/ZSECURE/zDocker-cobaltstrike/tree/main)
  - Blog post by Ezra Buckingham

Special thanks to these authors and the broader community for sharing their work and knowledge.

If you found this project helpful, consider giving it a star on GitHub or sharing feedback!

## Disclaimer

This project is intended for authorized and ethical use only. Cobalt Strike is a powerful tool that can be used for malicious purposes. By using this project, you agree to use it in a responsible and legal manner. The author is not responsible for any misuse of this project.
