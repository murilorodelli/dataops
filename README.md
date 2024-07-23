# Big Data XYZ

Bem-vindo ao Big Data XYZ! Este repositório contém tudo o que você precisa para configurar, desenvolver e implementar um ambiente de Big Data XYZ.

## Sumário

- [Big Data XYZ](#big-data-xyz)
  - [Sumário](#sumário)
  - [Requisitos](#requisitos)
  - [Instalação](#instalação)
    - [Pré-requisitos](#pré-requisitos)
    - [Passo a Passo de Instalação](#passo-a-passo-de-instalação)
  - [Configuração do Kubernetes](#configuração-do-kubernetes)
    - [k3d/k3s](#k3d/k3s)
    - [Kubectl](#kubectl)
  - [Desenvolvimento com VSCode](#desenvolvimento-com-vscode)
    - [Extensões Recomendadas](#extensões-recomendadas)
    - [Debugando Aplicações](#debugando-aplicações)
  - [Integração e Entrega Contínua (CI/CD)](#integração-e-entrega-contínua-cicd)
    - [Configuração do Git](#configuração-do-git)
    - [Pipeline de CI/CD](#pipeline-de-cicd)
  - [Estrutura do Projeto](#estrutura-do-projeto)
  - [Uso](#uso)
  - [Contribuição](#contribuição)
  - [Licença](#licença)

## Requisitos

Para utilizar este projeto, você precisará dos seguintes componentes:

- Sistema Operacional compatível com Docker
  - Windows
    - Windows 10/11
    - WSL2
    - Windows Terminal
  - Linux
    - Ubuntu ou similar
- Git
- Docker
- k3d/k3s
- Kubectl
- VSCode

## Instalação

### Pré-requisitos

Antes de iniciar a instalação, certifique-se de ter os seguintes pré-requisitos instalados:

- [Instalação do WSL2 (Somente Windows)](docs/install/wsl.md)
- [Instalação do Windows Terminal (Somente Windows)](docs/install/winterm.md)
- [Instalação do Git](docs/install/git.md)

### Passo a Passo de Instalação

1. Clone o repositório:

   ```bash
   git clone https://github.com/murilorodelli/dataops.git
   cd dataops
   ```

2. Configure o ambiente:

   ```bash
   ./scripts/bootstrap.sh
   ```

3. Faça novamente o login:

   Para realizar logout em WSL, feche a janela do terminal ou digite exit, enquanto em Linux, use o comando logout na linha de comando, ou utilize o menu de logout na interface gráfica.

## Configuração do Kubernetes

### k3d/k3s

k3d/k3s é uma ferramenta que facilita a execução de Kubernetes localmente.

1. Inicie o k3d/k3s:

   ```bash
   k3d/k3s start
   ```

2. Verifique a instalação:

   ```bash
   kubectl get nodes
   ```

### Kubectl

Kubectl é uma ferramenta de linha de comando para gerenciar clusters Kubernetes.

1. Verifique a instalação do kubectl:

   ```bash
   kubectl version --client
   ```

## Desenvolvimento com VSCode

### Extensões Recomendadas

Para uma melhor experiência de desenvolvimento com Kubernetes, instale as seguintes extensões no VSCode:

- [Kubernetes](https://marketplace.visualstudio.com/items?itemName=ms-kubernetes-tools.vscode-kubernetes-tools)
- [Docker](https://marketplace.visualstudio.com/items?itemName=ms-azuretools.vscode-docker)
- [Python](https://marketplace.visualstudio.com/items?itemName=ms-python.python)
- [GitLens](https://marketplace.visualstudio.com/items?itemName=eamodio.gitlens)

### Debugando Aplicações

Para debugar suas aplicações dentro do Kubernetes, siga os passos:

1. Configure o `launch.json` no VSCode para sua aplicação Python.
2. Utilize a extensão do Kubernetes para depurar diretamente no cluster.

## Integração e Entrega Contínua (CI/CD)

### Configuração do Git

1. Inicialize um repositório Git:

   ```bash
   git init
   ```

2. Adicione o repositório remoto:

   ```bash
   git remote add origin https://github.com/seu-usuario/projeto-big-data.git
   ```

3. Configure o arquivo `.gitignore` para ignorar arquivos desnecessários.

### Pipeline de CI/CD

1. Crie um arquivo `Jenkinsfile` ou configure o GitHub Actions para o pipeline CI/CD.
2. Defina os estágios de build, teste e deploy.

## Estrutura do Projeto

```plaintext
projeto-big-data/
├── data/
├── docs/
├── scripts/
│   ├── setup.sh
│   ├── start-hadoop.sh
│   ├── start-spark.sh
├── src/
│   ├── hadoop/
│   ├── spark/
│   ├── k8s/
├── tests/
├── .vscode/
│   ├── launch.json
│   ├── settings.json
├── .github/
│   ├── workflows/
│       ├── ci.yml
├── .env.example
├── README.md
├── requirements.txt
└── .gitignore
```

## Uso

- Iniciar Kubernetes:

  ```bash
  k3d/k3s start
  ```

- Verificar status do cluster:

  ```bash
  kubectl get nodes
  ```

- Executar testes:

  ```bash
  pytest
  ```

## Contribuição

Contribuições são bem-vindas! Por favor, veja o arquivo [CONTRIBUTING.md](CONTRIBUTING.md) para mais detalhes.

## Licença

Este projeto está licenciado sob a Licença MIT. Veja o arquivo [LICENSE](LICENSE) para mais detalhes.
