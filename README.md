# instalador-automatizado

Script em PowerShell criado para automatizar a instalação de aplicativos no Windows e auxiliar rotinas de suporte de TI.

O projeto identifica o perfil do computador, copia os instaladores de uma pasta de rede, solicita privilégios de administrador e executa as instalações na ordem configurada. Também mantém logs e permite retomar uma execução interrompida.

> Este repositório contém uma versão genérica e demonstrativa. Os caminhos, aplicativos e parâmetros devem ser adaptados e testados antes do uso em qualquer ambiente.

## Funcionalidades

- Detecção automática dos perfis **Notebook** e **Desktop** pelo nome do computador;
- Seleção manual do perfil quando o nome não corresponde aos padrões configurados;
- Cópia dos instaladores da rede para uma pasta temporária local;
- Elevação automática para privilégios de administrador;
- Instalação silenciosa de arquivos `.exe` e `.msi`;
- Suporte a instalações que precisam de interação manual;
- Registro das instalações concluídas e retomada após interrupções;
- Nova tentativa para aplicativos que apresentarem falha;
- Geração de logs com o resultado da execução;
- Identificação de instalações que exigem reinicialização;
- Limpeza dos instaladores concluídos.

## Arquivos do projeto

```text
.
├── Instalador_Automatizado.ps1  # Lógica principal da automação
├── INSTALAR.bat                 # Atalho para iniciar o script
└── README.md                    # Documentação do projeto
```

## Pré-requisitos

- Windows 10 ou Windows 11;
- Windows PowerShell 5.1;
- Conta com permissão para elevar privilégios;
- Acesso à pasta de rede que contém os instaladores;
- Instaladores oficiais e previamente testados.

## Estrutura esperada na rede

Organize os instaladores em pastas separadas por perfil:

```text
\\servidor\compartilhamento\Instaladores\
├── Notebook\
│   ├── ChromeSetup.exe
│   ├── instalador_nb1.exe
│   └── ...
└── Desktop\
    ├── ChromeSetup.exe
    ├── instalador2.msi
    └── ...
```

Os nomes são apenas exemplos. Utilize os nomes correspondentes aos arquivos do seu ambiente.

## Configuração

Abra o arquivo `Instalador_Automatizado.ps1` e ajuste a seção **CONFIGURAÇÃO**:

```powershell
$PrefixoNotebook = '*NTB*'
$PrefixoDesktop = '*WKS*'
$CaminhoRede = '\\servidor\compartilhamento\Instaladores'
$PastaTrabalho = 'C:\TempInstalacao'
```

Depois, edite as listas `$Apps` e `$AppsManuais` com o nome, o arquivo e os argumentos de cada instalador:

```powershell
$Apps = @(
    @{ Nome = 'Google Chrome'; Arquivo = 'ChromeSetup.exe'; Argumentos = '/silent /install' }
    @{ Nome = 'Aplicativo MSI'; Arquivo = 'aplicativo.msi'; Argumentos = '/quiet' }
)
```

Os argumentos de instalação silenciosa variam entre fabricantes. Consulte a documentação oficial de cada aplicativo antes de configurá-los.

## Como executar

1. Baixe ou clone este repositório.
2. Configure o script para o seu ambiente.
3. Organize os instaladores nas pastas `Notebook` e `Desktop` da rede.
4. Execute o arquivo `INSTALAR.bat`.
5. Confirme a solicitação de administrador e acompanhe as mensagens apresentadas.

Os logs são armazenados por padrão em:

```text
C:\TempInstalacao\Logs
```

## Códigos de retorno

Para arquivos MSI, o script considera os códigos `0`, `3010` e `1641` como sucesso. Os dois últimos indicam que o Windows precisa ser reiniciado.

Para instaladores EXE, o código `0` é considerado sucesso por padrão. Caso um fabricante utilize outros códigos, informe-os no cadastro do aplicativo:

```powershell
@{
    Nome = 'Aplicativo de exemplo'
    Arquivo = 'aplicativo.exe'
    Argumentos = '/silent'
    CodigosSucesso = @(0, 3010)
}
```

## Cuidados antes do uso

- Teste o script e cada instalador em uma máquina de laboratório;
- Use somente arquivos obtidos de fontes confiáveis;
- Restrinja a alteração dos instaladores na pasta de rede;
- Revise os logs antes de compartilhá-los, pois mensagens de erro podem conter caminhos internos;
- Ajuste os comandos silenciosos conforme a documentação de cada fabricante;
- Não inclua instaladores comerciais, licenças, credenciais ou informações internas neste repositório.

O parâmetro `ExecutionPolicy Bypass` é aplicado somente ao processo usado para iniciar o script. Ele não altera permanentemente a política de execução do Windows. Execute apenas scripts que você tenha revisado e em que confie.

## Personalização

O projeto foi mantido propositalmente simples para facilitar sua adaptação. É possível adicionar novos perfis, validação de versões instaladas, verificação de assinatura digital ou outras regras conforme a necessidade do ambiente.

## Autor

Desenvolvido por **Pedro Ramos** como projeto de automação para rotinas de suporte de TI.

Contribuições, sugestões e melhorias são bem-vindas.
