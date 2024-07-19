# Git

## Windows

Abra um prompt do PowerShell com permissão de Administrador

### Passos para abrir o PowerShell como Administrador:

1. Clique no menu Iniciar.
2. Digite "PowerShell" na barra de pesquisa.
3. Clique com o botão direito do mouse em "Windows PowerShell" na lista de resultados.
4. Selecione "Executar como administrador" no menu de contexto.
5. Se aparecer uma janela de Controle de Conta de Usuário (UAC), clique em "Sim" para permitir.

### Execute o seguinte comando:

```powershell
winget install --id Git.Git -e --source winget
```

## Ubuntu

Abra uma janela de terminal e execute:

``` sh
sudo apt update
```

Isso garantirá que o índice de pacotes esteja atualizado antes da instalação do Git.

``` sh
sudo apt install git
```
