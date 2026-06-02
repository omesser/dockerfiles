# Multi-stage build: Nginx with custom dynamic modules + React frontend.
#
# Key patterns:
#   - Compiles nginx dynamic modules from the official pkg-oss build system
#   - Integrity-checks downloaded scripts (sha512 verification)
#   - Separate stage for React build (node_modules never reach final image)
#   - Final image is a clean nginx with only the compiled module + static assets
#   - Parameterized NGINX_VERSION and ENABLED_MODULES for easy updates
#
# Adapted from the official nginx module build recipe:
#   https://github.com/nginxinc/docker-nginx/blob/master/modules/Dockerfile
#
# Usage:
#   docker build -t my-nginx .
#   docker build --build-arg NGINX_VERSION=1.27.3 --build-arg ENABLED_MODULES="headers-more geoip2" -t my-nginx .

ARG NGINX_VERSION=1.27.3

#### Stage 1: Build nginx dynamic modules from source ####
FROM nginx:$NGINX_VERSION AS modules-builder

# Space-separated list of modules to build.
# Available modules: https://github.com/nginx/pkg-oss/tree/master/debian
ARG ENABLED_MODULES="headers-more"

SHELL ["/bin/bash", "-exo", "pipefail", "-c"]

RUN if [ "$ENABLED_MODULES" = "" ]; then \
        echo "No additional modules enabled, exiting"; \
        exit 1; \
    fi

RUN apt-get update \
    && apt-get install -y --no-install-suggests --no-install-recommends \
                patch make wget git devscripts debhelper dpkg-dev \
                quilt lsb-release build-essential libxml2-utils xsltproc \
                equivs git g++ libparse-recdescent-perl \
    # Verify integrity of the xslscript helper
    && XSLSCRIPT_SHA512="f7194c5198daeab9b3b0c3aebf006922c7df1d345d454bd8474489ff2eb6b4bf8e2ffe442489a45d1aab80da6ecebe0097759a1e12cc26b5f0613d05b7c09ffa *stdin" \
    && wget -O /tmp/xslscript.pl https://raw.githubusercontent.com/nginx/xslscript/9204424259c343ca08a18a78915f40f28025e093/xslscript.pl \
    && if [ "$(cat /tmp/xslscript.pl | openssl sha512 -r)" = "$XSLSCRIPT_SHA512" ]; then \
        echo "XSLScript checksum verification succeeded!"; \
        chmod +x /tmp/xslscript.pl; \
        mv /tmp/xslscript.pl /usr/local/bin/; \
    else \
        echo "XSLScript checksum verification failed!"; \
        exit 1; \
    fi \
    && git clone -b ${NGINX_VERSION}-${PKG_RELEASE%%~*} https://github.com/nginx/pkg-oss/ \
    && cd pkg-oss \
    && mkdir /tmp/packages \
    && for module in $ENABLED_MODULES; do \
        echo "Building $module for nginx-$NGINX_VERSION"; \
        if [ -d /modules/$module ]; then \
            echo "Building $module from user-supplied sources"; \
            if [ ! -s /modules/$module/source ]; then \
                echo "No source file for $module in modules/$module/source, exiting"; \
                exit 1; \
            fi; \
            if [ -f /modules/$module/build-deps ]; then \
                echo "Installing $module build dependencies"; \
                apt-get update && apt-get install -y --no-install-suggests --no-install-recommends $(cat /modules/$module/build-deps | xargs); \
            fi; \
            if [ -x /modules/$module/prebuild ]; then \
                echo "Running prebuild script for $module"; \
                /modules/$module/prebuild; \
            fi; \
            /pkg-oss/build_module.sh -v $NGINX_VERSION -f -y -o /tmp/packages -n $module $(cat /modules/$module/source); \
            BUILT_MODULES="$BUILT_MODULES $(echo $module | tr '[A-Z]' '[a-z]' | tr -d '[/_\-\.\t ]')"; \
        elif make -C /pkg-oss/debian list | grep -P "^$module\s+\d" > /dev/null; then \
            echo "Building $module from pkg-oss sources"; \
            cd /pkg-oss/debian; \
            make rules-module-$module BASE_VERSION=$NGINX_VERSION NGINX_VERSION=$NGINX_VERSION; \
            mk-build-deps --install --tool="apt-get -o Debug::pkgProblemResolver=yes --no-install-recommends --yes" debuild-module-$module/nginx-$NGINX_VERSION/debian/control; \
            make module-$module BASE_VERSION=$NGINX_VERSION NGINX_VERSION=$NGINX_VERSION; \
            find ../../ -maxdepth 1 -mindepth 1 -type f -name "*.deb" -exec mv -v {} /tmp/packages/ \;; \
            BUILT_MODULES="$BUILT_MODULES $module"; \
        else \
            echo "Don't know how to build $module module, exiting"; \
            exit 1; \
        fi; \
    done \
    && echo "BUILT_MODULES=\"$BUILT_MODULES\"" > /tmp/packages/modules.env

#### Stage 2: Install compiled modules into a clean nginx image ####
FROM nginx:$NGINX_VERSION AS nginx-with-modules
RUN --mount=type=bind,target=/tmp/packages/,source=/tmp/packages/,from=modules-builder \
    apt-get update \
    && . /tmp/packages/modules.env \
    && for module in $BUILT_MODULES; do \
           apt-get install --no-install-suggests --no-install-recommends -y /tmp/packages/nginx-module-${module}_${NGINX_VERSION}*.deb; \
       done \
    && rm -rf /var/lib/apt/lists/

#### Stage 3: Build the frontend (React/Next.js/Vite) ####
FROM node:20-slim AS app-builder

WORKDIR /app

# Copy package files first for layer caching
COPY frontend/package.json frontend/package-lock.json ./
RUN npm ci

# Then copy source and build
COPY frontend/ ./
RUN npm run build

#### Stage 4: Final image -- clean nginx + module + static assets ####
FROM nginx:$NGINX_VERSION

# Copy the compiled module .so from stage 2
COPY --from=nginx-with-modules /usr/lib/nginx/modules/ /usr/lib/nginx/modules/

# Copy the built frontend assets (adjust source path for your framework)
# Next.js: /app/out  |  Vite: /app/dist  |  CRA: /app/build
COPY --from=app-builder /app/out /usr/share/nginx/html

# Copy your nginx config (uncomment and adjust)
# COPY nginx.conf /etc/nginx/nginx.conf

CMD ["nginx", "-g", "daemon off;"]
