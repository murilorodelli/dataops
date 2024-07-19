# Windows Terminal

## Instalação do Windows Terminal

### Passos para instalar o Windows Terminal usando a Microsoft Store

1. Abra a Microsoft Store:
   - Clique no menu Iniciar.
   - Digite "Microsoft Store" na barra de pesquisa.
   - Clique em "Microsoft Store" na lista de resultados.

2. Procure por "Windows Terminal" na Microsoft Store:
   - Digite "Windows Terminal" na barra de pesquisa da Microsoft Store.
   - Clique em "Windows Terminal" nos resultados da pesquisa.

3. Instale o Windows Terminal:
   - Clique no botão "Obter" ou "Instalar".

### Passos para instalar o Windows Terminal usando winget

1. Abra um prompt do PowerShell com permissão de Administrador:
   - Clique no menu Iniciar.
   - Digite "PowerShell" na barra de pesquisa.
   - Clique com o botão direito do mouse em "Windows PowerShell" na lista de resultados.
   - Selecione "Executar como administrador" no menu de contexto.
   - Se aparecer uma janela de Controle de Conta de Usuário (UAC), clique em "Sim" para permitir.

2. Execute o seguinte comando no PowerShell:

   ```powershell
   winget install --id Microsoft.WindowsTerminal -e --source winget
   ```

## Instalação das Fontes MesloLGS NF

Opcional mas recomendado pois muitas aplicações usam os caracteres Nerd Fonts para melhorar a experiência do terminal

### Passos para baixar e instalar as fontes MesloLGS NF

1. Acesse o repositório oficial das fontes MesloLGS NF no GitHub:
   - [Nerd Fonts - MesloLGS NF](https://github.com/ryanoasis/nerd-fonts/tree/master/patched-fonts/Meslo)

2. Baixe os arquivos de fontes:
   - Clique no link de cada variante da fonte (Regular, Bold, Italic, etc.).
   - Clique no botão "Download" para baixar os arquivos de fontes desejados.

3. Instale as fontes:
   - Localize os arquivos de fontes baixados no seu computador.
   - Selecione todos os arquivos de fontes, clique com o botão direito do mouse e escolha "Instalar".

## Configuração do Windows Terminal para usar MesloLGS NF

### Passos para configurar o Windows Terminal

1. Abra o Windows Terminal.

2. Acesse as configurações do Windows Terminal:
   - Clique na seta para baixo ao lado da guia ativa.
   - Selecione "Configurações" no menu suspenso.

3. Edite o arquivo de configurações:
   - No painel de configurações, clique em "Abrir arquivo JSON" no canto inferior esquerdo.
   - O arquivo `settings.json` será aberto em seu editor de texto padrão.

4. Configure a fonte para MesloLGS NF:
   - Encontre a seção do perfil que deseja configurar (exemplo: "profiles").
   - Adicione ou edite a seguinte linha dentro do perfil desejado: `"fontFace": "MesloLGS NF",`
   - Salve as alterações no arquivo `settings.json`.

        Exemplo de configuração no `settings.json`

        ```json
        {
            "profiles": {
                "list": [
                    {
                        "guid": "{GUID-do-perfil}",
                        "name": "Windows PowerShell",
                        "fontFace": "MesloLGS NF",
                        // outras configurações
                    }
                ]
            }
        }
        ```

5. Reinicie o Windows Terminal para aplicar as alterações.
