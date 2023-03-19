# contracts

## Deploy

Deploy Store Blueprint

```bash
make deploy-blueprint
```

Deploy Store Manager

```bash
make deploy-manager
```

Update config for factory

- blueprint
- manager

Deploy Factory

```bash
make deploy-factory
```

Set lambda in store manager

```bash
make set-lambda
```

create/fund upkeep for store (Per Store Owner)

- https://automation.chain.link/mumbai

create/fund/add consumer (consumer is manager) functions sub

Create a new Store instance (Company)

```bash
make deploy-new-store
```

## Store Manager

- Add Company
- Updates Order tracking
- Each company will have their own automation upkeep
- Possibly use new CL functions

## Store

- each company will have their own store
