## Terraform Use Cases

[![Tests](https://img.shields.io/github/actions/workflow/status/habedi/terraform-usecases/tests.yml?label=tests&style=flat&labelColor=282c34&logo=github)](https://github.com/habedi/terraform-usecases/actions/workflows/tests.yml)
[![License](https://img.shields.io/badge/license-MIT-007ec6?style=flat&labelColor=282c34&logo=open-source-initiative)](LICENSE)

---

This repository contains a collection of use cases where [Terraform](https://www.terraform.io/) is used to provision resources
in AWS to set up environments for various tasks.

#### List of currently implemented use cases

| Index | Title                                                                       | Complexity |
|-------|-----------------------------------------------------------------------------|------------|
| 1     | [Provision a Server](use-cases/use-case-1)                                  | Simple     |
| 2     | [Provision a Server and a Database](use-cases/use-case-2)                   | Simple     |
| 3     | [Set up a GraphQL API with AppSync and Amazon Aurora](use-cases/use-case-3) | Complex    |

---

### Quickstart

To follow the steps below, you need to have Git and [Nix](https://nixos.org/download/) (with flakes enabled) installed on your machine.

#### 1. Clone the repository

```shell
git clone https://github.com/habedi/terraform-usecases.git
cd terraform-usecases
```

#### 2. Set up the development environment

```shell
nix develop
```

#### 3. Run the tests (optional)

```shell
make test
```

---

### Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for details on how to make a contribution.

### License

The content of this repository is licensed under the MIT License (see [LICENSE](LICENSE)).
