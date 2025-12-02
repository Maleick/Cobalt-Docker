# Cobalt Strike Docker

This project provides a simple way to build and run a Cobalt Strike team server in a Docker container. It includes a Dockerfile for building the image, a shell script for automation, and sample Malleable C2 profiles. The configuration and example profiles have been updated and tested with **Cobalt Strike 4.12**.

## Prerequisites

Before you begin, ensure you have the following installed:

- [Docker](https://www.docker.com/get-started)
- A valid Cobalt Strike license key

## Files

- **`Dockerfile`**: Defines the Docker image for the Cobalt Strike team server. It installs the necessary dependencies, downloads and installs Cobalt Strike (tested with 4.12), and sets up the container environment.
- **`cobalt-docker.sh`**: A shell script that automates the process of building the Docker image and running the container. It prompts for your Cobalt Strike license key and a password for the team server.
- **`malleable.profile`**: A default Malleable C2 profile to customize the appearance of your Cobalt Strike traffic.
- **`malleable.profile.4.12-drip` / `malleable.profile.4.12-drip-vaex`**: Additional example Malleable C2 profiles tailored and validated for Cobalt Strike 4.12.

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

## Cobalt Strike 4.12 notes

- This repository (Dockerfile, automation script, and example profiles) has been validated against Cobalt Strike 4.12.
- The helper profiles `malleable.profile.4.12-drip` and `malleable.profile.4.12-drip-vaex` were linted with `c2lint` and are intended as 4.12-friendly starting points.
- If you use a different Cobalt Strike version, you should:
  - Re-run `./cobalt-docker.sh lint <your_profile>` to validate any custom profiles with `c2lint` inside the container.
  - Review Fortra’s release notes for any profile syntax or behavioral changes between versions.
- Java is provided in the image; you normally do not need a host-side Java install to run the team server inside Docker.

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
