# Instalação do WSL2

## Windows 10

1. **Habilitar a Plataforma de Máquina Virtual**:

    ```sh
    dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart
    dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart
    ```

2. **Instalar o Kernel do WSL**: [Baixar Kernel do WSL 2](https://docs.microsoft.com/pt-br/windows/wsl/wsl2-kernel) e instalar o pacote.

3. **Definir a Versão Padrão para WSL 2**:

    ```sh
    wsl --set-default-version 2
    ```

4. **Converter Distribuição Existente para WSL 2** (se aplicável):

    ```sh
    wsl --set-version <nome da distribuição> 2
    ```

## Windows 11

1. **Instalar o WSL**:

    ```sh
    wsl --install
    ```

2. **Opcional - Escolher Distribuição Linux**:

    ```sh
    wsl -l -o
    wsl --install -d <nome-da-distribuição>
    ```
