---
sidebar_position: 3
---

# Wally Authentication

## Wally Registry

As we've developed a set of internal tools, we'll need to reconfigure the base `wally.toml` file that is generated.. this is so our new project has the ability to access our new registry that contains our internal tools.

Under the `wally.toml` file, please change the registry entry to the following;

```lua
registry = "https://github.com/Roblox-Devs-Dubit/wally-index"
```

## Wally Login

In order to download and use packages under RIT, you'll need to authenticate yourself with our Wally Registry, you can do this by the entering the following into a Terminal;

```bash
C:\..\project-name> wally login
```

Wally should then prompt you for a authentication of sorts. Type in the wally authentiaction key you have been given.

## Wally CI-CD Login

In order to download and use packages under pipelines, you'll need to authenticate yourself with wally during the pipelines, this can be done by adding a step that contains the following code; (replace the numbers with the wally key you have been given)

```bash
echo "12345678-1234-1234-1234-123456789abc" | wally login
```

A good example of this can be seen here;

```yml
    - step: &wally-install
        name: Wally Packages
        script:
          - echo "$WALLY_AUTH" | wally login
          - wally install
        artifacts:
          - Packages/**
```

where *"$WALLY_AUTH"* represents an environment variable with the value seen above.