# Instalando o Docker Engine no Ubuntu

## Pré-requisitos

### Considerações sobre Firewall

Ao usar `ufw` ou `firewalld` para gerenciar configurações de firewall, observe que as portas de contêiner expostas com Docker podem ignorar suas regras de firewall.

O Docker é compatível com `iptables-nft` e `iptables-legacy`. Certifique-se de que quaisquer regras de firewall sejam criadas usando `iptables` ou `iptables6` e adicione-as à cadeia `DOCKER-USER`.

Consulte [Filtragem de pacotes e firewalls](https://docs.docker.com/network/iptables/#docker-and-ip-filtering) para obter mais detalhes.

### Requisitos do Sistema Operacional

Para instalar o Docker Engine, você precisa de uma versão de 64 bits de uma das seguintes versões do Ubuntu:

- Ubuntu Noble 24.04 (LTS)
- Ubuntu Jammy 22.04 (LTS)
- Ubuntu Focal 20.04 (LTS)

O Docker Engine para Ubuntu suporta as seguintes arquiteturas: x86_64 (amd64), armhf, arm64, s390x e ppc64le (ppc64el).

### Desinstalar Versões Antigas

Antes de instalar o Docker Engine, desinstale quaisquer pacotes conflitantes. Os mantenedores da distribuição fornecem pacotes não oficiais do Docker no APT, que devem ser removidos antes de instalar a versão oficial do Docker Engine.

Desinstale os seguintes pacotes não oficiais:

- `docker.io`
- `docker-compose`
- `docker-compose-v2`
- `docker-doc`
- `podman-docker`

O Docker Engine depende de `containerd` e `runc`, agrupados como `containerd.io`. Desinstale quaisquer versões previamente instaladas de `containerd` ou `runc` para evitar conflitos.

Execute o seguinte comando para desinstalar todos os pacotes conflitantes:

```sh
for pkg in docker.io docker-doc docker-compose docker-compose-v2 podman-docker containerd runc; do sudo apt-get remove $pkg; done
```

**Notas**:

1. `apt-get` pode relatar que nenhum desses pacotes está instalado.

2. Imagens, contêineres, volumes e redes armazenados em `/var/lib/docker/` não são removidos automaticamente ao desinstalar o Docker. Para uma instalação limpa, leia a seção [Desinstalar Docker Engine](#desinstalar-docker-engine).

## Métodos de Instalação

Existem várias maneiras de instalar o Docker Engine:

- Usando o repositório apt do Docker (método preferido).
- Agrupado com o Docker Desktop para Linux.
- Instalação e gerenciamento manuais.
- Usando um script de conveniência (recomendado apenas para testes e desenvolvimento).

Este guia se concentra no método preferido: usar o repositório apt. Para outros métodos, consulte a [documentação oficial do Docker](https://docs.docker.com/engine/install).

### Instalar Usando o Repositório apt

Antes de instalar o Docker Engine em uma nova máquina host, configure o repositório do Docker. Depois disso, você pode instalar e atualizar o Docker a partir do repositório.

#### Configurar o Repositório apt do Docker

1. **Adicione a chave GPG oficial do Docker:**

    ```sh
    sudo apt-get update
    sudo apt-get install ca-certificates curl
    sudo install -m 0755 -d /etc/apt/keyrings
    sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
    sudo chmod a+r /etc/apt/keyrings/docker.asc
    ```

2. **Adicione o repositório Docker às fontes do APT:**

    ```sh
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    sudo apt-get update
    ```

    *Nota*: Para derivativos do Ubuntu, como o Linux Mint, você pode precisar usar `UBUNTU_CODENAME` em vez de `VERSION_CODENAME`.

#### Instalar Docker Engine

1. **Instale os pacotes Docker:**

    ```sh
    sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    ```

2. **Adicione seu usuário ao grupo `docker` para executar o Docker sem `sudo`:**

    ```sh
    sudo usermod -aG docker $USER
    ```

3. **Inicie o serviço Docker:**

    ```sh
    sudo service docker start
    ```

4. **Verifique a instalação executando a imagem `hello-world`:**

    ```sh
    sudo docker run hello-world
    ```

    Este comando baixa uma imagem de teste, executa-a em um contêiner e imprime uma mensagem de confirmação antes de sair.

Parabéns! Você instalou e iniciou o Docker Engine com sucesso.

## Desinstalar Docker Engine

Para desinstalar o Docker Engine, CLI, containerd e pacotes Docker Compose, execute:

```sh
sudo apt-get purge docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin docker-ce-rootless-extras
```

Imagens, contêineres, volumes ou arquivos de configuração personalizados no seu host não são removidos automaticamente. Para excluir todas as imagens, contêineres e volumes, execute:

```sh
sudo rm -rf /var/lib/docker
sudo rm -rf /var/lib/containerd
```

Você deve excluir manualmente qualquer arquivo de configuração editado.

Para mais informações, consulte a [documentação oficial do Docker](https://docs.docker.com/engine/install).
