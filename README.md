# docker-metabase

Docker build for metabase v 0.33.0
Builds in docker with pull requests applied and additional drivers included.

## Running

```bash
docker run -d -p 3000:3000 --name metabase huksley/metabase:0.33
```

## Current PRs included:

  * None, define METABASE_PULLS= build arg to include Metabase PRs to apply before build

## Additional drivers included:

  * https://github.com/tlrobinson/metabase-http-driver Allows to query JSON endpoints

## Links

  * Docker hub: https://hub.docker.com/r/huksley/metabase
  * Github: https://github.com/huksley/docker-metabase

