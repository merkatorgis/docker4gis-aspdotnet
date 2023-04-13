FROM mcr.microsoft.com/dotnet/sdk:7.0 AS build-env
ONBUILD WORKDIR /App

# Copy everything
ONBUILD COPY . ./
# Restore as distinct layers
ONBUILD RUN dotnet restore
# Build and publish a release
ONBUILD RUN dotnet publish -c Release -o out

ONBUILD ARG DOTNET_PROJECT
ONBUILD ENV DOTNET_PROJECT=$DOTNET_PROJECT

# Build runtime image
FROM mcr.microsoft.com/dotnet/aspnet:7.0
ONBUILD WORKDIR /App
ONBUILD COPY --from=build-env /App/out .

# Allow configuration before things start up.
COPY conf/entrypoint /
ENTRYPOINT ["/entrypoint"]
CMD ["dotnet"]

# Example plugin use.
COPY conf/.plugins/bats /tmp/bats
RUN /tmp/bats/install.sh

# This may come in handy.
ONBUILD ARG DOCKER_USER
ONBUILD ENV DOCKER_USER=$DOCKER_USER

# Extension template, as required by `dg component`.
COPY template /template/
# Make this an extensible base component; see
# https://github.com/merkatorgis/docker4gis/tree/npm-package/docs#extending-base-components.
COPY conf/.docker4gis /.docker4gis
COPY build.sh /.docker4gis/build.sh
COPY run.sh /.docker4gis/run.sh
ONBUILD COPY conf /tmp/conf
ONBUILD RUN touch /tmp/conf/args
ONBUILD RUN cp /tmp/conf/args /.docker4gis
