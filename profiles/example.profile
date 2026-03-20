#
# Example Malleable C2 Profile
#
# This is a minimal profile for testing. Replace it with your own
# operational profile before any real engagement.
#
# Lint with:  ./cobalt-docker.sh lint profiles/example.profile
# Deploy with: ./cobalt-docker.sh profiles/example.profile
#

set sample_name "Example Profile";
set sleeptime "30000";
set jitter "20";
set useragent "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/130.0.0.0 Safari/537.36";

http-get {
    set uri "/api/v1/updates";

    client {
        header "Accept" "application/json";
        header "Accept-Language" "en-US,en;q=0.9";

        metadata {
            base64url;
            header "Cookie";
        }
    }

    server {
        header "Content-Type" "application/json";
        header "Cache-Control" "no-cache";

        output {
            base64;
            print;
        }
    }
}

http-post {
    set uri "/api/v1/status";

    client {
        header "Content-Type" "application/json";

        id {
            base64url;
            header "Authorization";
        }

        output {
            base64;
            print;
        }
    }

    server {
        header "Content-Type" "application/json";

        output {
            base64;
            print;
        }
    }
}
