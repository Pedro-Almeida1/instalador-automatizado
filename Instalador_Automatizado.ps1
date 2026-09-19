# ============================================================
# Script de Instalacao Automatizada de Aplicativos - Suporte TI
# Versao 2.0
# Autor: Pedro Ramos
# GitHub: https://github.com/seu-usuario/seu-repositorio
#
# DESCRICAO:
#   Automatiza a instalacao de aplicativos padrao em ambientes
#   corporativos Windows. Detecta o perfil da maquina pelo
#   hostname, copia os instaladores da rede para o disco local,
#   eleva privilegios automaticamente e instala cada app na
#   ordem definida. Inclui log, recuperacao de falha e limpeza
#   automatica apos a conclusao.
#
# PRE-REQUISITOS:
#   - Windows 10/11
#   - Acesso a uma pasta de rede com os instaladores
#   - Credenciais de administrador local
#
# COMO USAR:
#   1. Edite a secao "CONFIGURACAO" abaixo com os caminhos e
#      nomes de arquivo corretos para o seu ambiente.
#   2. Coloque este script e o INSTALAR.bat na pasta de rede.
#   3. O tecnico executa o INSTALAR.bat com duplo clique.
#
# ESTRUTURA DE PASTAS ESPERADA NA REDE:
#   \\servidor\compartilhamento\
#       Notebook\
#           Instalador_Automatizado.ps1
#           INSTALAR.bat
#           ChromeSetup.exe
#           ... (demais instaladores)
#       Desktop\
#           Instalador_Automatizado.ps1
#           INSTALAR.bat
#           ChromeSetup.exe
#           ... (demais instaladores)
# ============================================================

param(
    [string]$ScriptPath = $MyInvocation.MyCommand.Path,
    [switch]$Retomar
)

# ============================================================
# CONFIGURACAO - EDITE ESTA SECAO PARA O SEU AMBIENTE
# ============================================================

# Prefixos do hostname para deteccao de perfil automatica.
# Exemplo: se seus notebooks tem hostname "NTB-001", use "*NTB*"
$PrefixoNotebook = "*NTB*"
$PrefixoDesktop  = "*WKS*"

# Caminho base da pasta de rede onde estao os instaladores.
# Exemplo: "\\servidor\ti\Instaladores"
$CaminhoRede = "\\servidor\compartilhamento\Instaladores"

# Pasta temporaria local onde os instaladores serao copiados.
# Nao e necessario alterar.
$Destino = "C:\TempInstalacao\Instaladores"

# ============================================================
# BLOCO 1 - Deteccao de perfil pelo hostname
# ============================================================
$Hostname = $env:COMPUTERNAME

if ($Hostname -like $PrefixoNotebook) {
    $Perfil = "Notebook"
    $Origem = "$CaminhoRede\Notebook"
} elseif ($Hostname -like $PrefixoDesktop) {
    $Perfil = "Desktop"
    $Origem = "$CaminhoRede\Desktop"
} else {
    Write-Host ""
    Write-Host "Hostname '$Hostname' nao reconhecido." -ForegroundColor Yellow
    Write-Host "Selecione o perfil manualmente:" -ForegroundColor Yellow
    Write-Host "  1 - Notebook"
    Write-Host "  2 - Desktop"
    Write-Host ""
    $opcao = Read-Host "Digite 1 ou 2"

    switch ($opcao) {
        "1" {
            $Perfil = "Notebook"
            $Origem = "$CaminhoRede\Notebook"
        }
        "2" {
            $Perfil = "Desktop"
            $Origem = "$CaminhoRede\Desktop"
        }
        default {
            Write-Host "Opcao invalida. Encerrando." -ForegroundColor Red
            Start-Sleep -Seconds 3
            Exit
        }
    }
}

Write-Host ""
Write-Host "Perfil detectado: $Perfil ($Hostname)" -ForegroundColor Cyan

# ============================================================
# BLOCO 2 - Verifica elevacao
# ============================================================
$isAdmin = ([Security.Principal.WindowsIdentity]::GetCurrent().Groups -match "S-1-5-32-544")

# ============================================================
# BLOCO 3 - Copia da rede e elevacao
# Roda somente na PRIMEIRA execucao (contexto de usuario normal).
# O usuario normal tem acesso a pasta de rede; o contexto de
# Administrador (elevado) nao enxerga drives mapeados, por isso
# a copia acontece ANTES da elevacao.
# ============================================================
if (-NOT $isAdmin) {

    if (Test-Path $Destino) {
        Write-Host ""
        Write-Host "================================================" -ForegroundColor Yellow
        Write-Host "  ATENCAO: Pasta de instalacao ja existe!" -ForegroundColor Yellow
        Write-Host "  Isso indica que o script pode ter sido" -ForegroundColor Yellow
        Write-Host "  encerrado anteriormente de forma inesperada." -ForegroundColor Yellow
        Write-Host "================================================" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "O que deseja fazer?" -ForegroundColor White
        Write-Host "  1 - Continuar de onde parou (instalar apenas o que falta)"
        Write-Host "  2 - Recomecar do zero (recopiar tudo e reinstalar tudo)"
        Write-Host ""
        $opcaoRetomar = Read-Host "Digite 1 ou 2"

        switch ($opcaoRetomar) {
            "1" {
                $Retomar = $true
                Write-Host "Continuando instalacao..." -ForegroundColor Green
            }
            "2" {
                $Retomar = $false
                Write-Host "Recomecando do zero (arquivos serao sobrescritos)..." -ForegroundColor Yellow
                # Nao apagamos a pasta — o proprio script roda de dentro dela,
                # entao apagar causaria erro de arquivo em uso. A copia com
                # -Force abaixo sobrescreve tudo, restaurando inclusive os
                # instaladores que ja tinham sido deletados apos sucesso.
            }
            default {
                Write-Host "Opcao invalida. Encerrando." -ForegroundColor Red
                Start-Sleep -Seconds 3
                Exit
            }
        }
    } else {
        $Retomar = $false
    }

    if (-NOT $Retomar) {
        Write-Host ""
        Write-Host "================================================" -ForegroundColor Cyan
        Write-Host "   Instalacao Automatizada de Aplicativos" -ForegroundColor Cyan
        Write-Host "   Perfil: $Perfil" -ForegroundColor Cyan
        Write-Host "================================================" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "Copiando instaladores da rede para o disco local..." -ForegroundColor Yellow
        Write-Host "Aguarde, isso pode levar alguns minutos..." -ForegroundColor Yellow

        if (-NOT (Test-Path $Destino)) {
            New-Item -ItemType Directory -Path $Destino -Force | Out-Null
        }

        Copy-Item -Path "$Origem\*" -Destination $Destino -Recurse -Force -ErrorAction SilentlyContinue

        Write-Host "Copia concluida!" -ForegroundColor Green
    }

    # Copia o proprio script para o disco local e relanca elevado.
    # Necessario porque o contexto de Administrador nao acessa
    # caminhos de rede do usuario normal.
    Copy-Item -Path $ScriptPath -Destination "$Destino\Instalador.ps1" -Force

    Write-Host "Solicitando privilegios de administrador..." -ForegroundColor Yellow

    $retomarArg = ""
    if ($Retomar) { $retomarArg = "-Retomar" }

    Start-Process powershell -Verb RunAs -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$Destino\Instalador.ps1`" -ScriptPath `"$Destino\Instalador.ps1`" $retomarArg"
    Exit
}

# ============================================================
# BLOCO 4 - Configuracoes (roda ja como Administrador)
# ============================================================
$Base    = "C:\TempInstalacao\Instaladores"
$LogPath = "C:\TempInstalacao\Logs"

if (-NOT (Test-Path $LogPath)) {
    New-Item -ItemType Directory -Path $LogPath -Force | Out-Null
}

$DataHora = Get-Date -Format "yyyyMMdd_HHmmss"
$LogFile  = "$LogPath\instalacao_$DataHora.log"

Add-Content -Path $LogFile -Value "$(Get-Date) | INICIO | Perfil: $Perfil | Hostname: $Hostname"

# ============================================================
# BLOCO 5 - Lista de apps que falharam
# ============================================================
$AppsFalharam = @()

# ============================================================
# BLOCO 6 - Funcao de instalacao silenciosa
#
# Retorna:
#   "sucesso"  - instalado com ExitCode 0, instalador deletado
#   "erro"     - ExitCode diferente de 0, instalador mantido
#   "pulado"   - instalador nao encontrado (ja instalado antes)
# ============================================================
function Install-App {
    param(
        [string]$Nome,
        [string]$Arquivo,
        [string]$Argumentos
    )

    $Caminho = "$Base\$Arquivo"

    if (-NOT (Test-Path $Caminho)) {
        Write-Host "`n$Nome ja instalado anteriormente, pulando..." -ForegroundColor Gray
        Add-Content -Path $LogFile -Value "$(Get-Date) | $Nome | PULADO | Instalador nao encontrado (ja instalado)"
        return "pulado"
    }

    Write-Host "`nInstalando: $Nome..." -ForegroundColor Cyan

    try {
        if ($Argumentos -eq "") {
            $processo = Start-Process -FilePath $Caminho -Wait -PassThru
        } else {
            $processo = Start-Process -FilePath $Caminho -ArgumentList $Argumentos -Wait -PassThru
        }

        $exitCode = $processo.ExitCode

        if ($exitCode -eq 0) {
            Write-Host "$Nome instalado com sucesso." -ForegroundColor Green
            Add-Content -Path $LogFile -Value "$(Get-Date) | $Nome | SUCESSO | ExitCode: $exitCode"
            Remove-Item -Path $Caminho -Force -ErrorAction SilentlyContinue
            return "sucesso"
        } else {
            Write-Host "$Nome retornou codigo $exitCode." -ForegroundColor Red
            Add-Content -Path $LogFile -Value "$(Get-Date) | $Nome | ERRO | ExitCode: $exitCode"
            return "erro"
        }
    } catch {
        Write-Host "ERRO ao instalar $Nome - $_" -ForegroundColor Red
        Add-Content -Path $LogFile -Value "$(Get-Date) | $Nome | ERRO | $_"
        return "erro"
    }
}

# ============================================================
# BLOCO 7 - Funcao de instalacao manual
#
# Abre o instalador e aguarda o tecnico pressionar ENTER apos
# concluir. Usado para instaladores que nao suportam modo
# silencioso ou que exigem configuracao durante a instalacao.
# ============================================================
function Install-Manual {
    param(
        [string]$Nome,
        [string]$Arquivo
    )

    $Caminho = "$Base\$Arquivo"

    if (-NOT (Test-Path $Caminho)) {
        Write-Host "`n$Nome ja instalado anteriormente, pulando..." -ForegroundColor Gray
        return
    }

    Write-Host ""
    Write-Host "================================================" -ForegroundColor Yellow
    Write-Host "  INSTALACAO MANUAL: $Nome" -ForegroundColor Yellow
    Write-Host "  Siga as instrucoes na tela." -ForegroundColor Yellow
    Write-Host "  O script aguardara voce terminar." -ForegroundColor Yellow
    Write-Host "================================================" -ForegroundColor Yellow

    Start-Process -FilePath $Caminho

    Write-Host ""
    Read-Host "Quando a instalacao de '$Nome' estiver concluida, pressione ENTER para continuar"

    Write-Host "$Nome - instalacao manual concluida." -ForegroundColor Green
    Add-Content -Path $LogFile -Value "$(Get-Date) | $Nome | MANUAL | Concluido"
    Remove-Item -Path $Caminho -Force -ErrorAction SilentlyContinue
}

# ============================================================
# BLOCO 8 - Funcao de reinstalacao (tentativa de correcao)
# ============================================================
function Reinstalar-App {
    param(
        [string]$Nome,
        [string]$Arquivo,
        [string]$Argumentos
    )

    $Caminho = "$Base\$Arquivo"

    if (-NOT (Test-Path $Caminho)) {
        Write-Host "`n${Nome}: instalador nao encontrado para reinstalar." -ForegroundColor Red
        Add-Content -Path $LogFile -Value "$(Get-Date) | $Nome | REINSTALACAO | Instalador nao encontrado"
        return
    }

    Write-Host "`nTentando reinstalar: $Nome..." -ForegroundColor Yellow

    try {
        if ($Argumentos -eq "") {
            $processo = Start-Process -FilePath $Caminho -Wait -PassThru
        } else {
            $processo = Start-Process -FilePath $Caminho -ArgumentList $Argumentos -Wait -PassThru
        }

        $exitCode = $processo.ExitCode

        if ($exitCode -eq 0) {
            Write-Host "$Nome reinstalado com sucesso." -ForegroundColor Green
            Add-Content -Path $LogFile -Value "$(Get-Date) | $Nome | REINSTALACAO | SUCESSO | ExitCode: $exitCode"
            Remove-Item -Path $Caminho -Force -ErrorAction SilentlyContinue
        } else {
            Write-Host "$Nome nao foi possivel instalar. Realize a instalacao manual." -ForegroundColor Red
            Add-Content -Path $LogFile -Value "$(Get-Date) | $Nome | REINSTALACAO | ERRO | ExitCode: $exitCode"
        }
    } catch {
        Write-Host "ERRO ao reinstalar $Nome - $_" -ForegroundColor Red
        Add-Content -Path $LogFile -Value "$(Get-Date) | $Nome | REINSTALACAO | ERRO | $_"
    }
}

# ============================================================
# BLOCO 9 - Cabecalho
# ============================================================
Clear-Host
Write-Host "================================================" -ForegroundColor Cyan
Write-Host "   Instalacao Automatizada de Aplicativos" -ForegroundColor Cyan
Write-Host "   Perfil  : $Perfil" -ForegroundColor Cyan
Write-Host "   Maquina : $Hostname" -ForegroundColor Cyan
Write-Host "   Inicio  : $(Get-Date -Format 'dd/MM/yyyy HH:mm')" -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan
Write-Host ""

if ($Retomar) {
    Write-Host "Modo: RETOMADA DE INSTALACAO" -ForegroundColor Yellow
    Write-Host "Apps ja instalados serao pulados automaticamente." -ForegroundColor Yellow
} else {
    Write-Host "Modo: INSTALACAO COMPLETA" -ForegroundColor Green
}

Write-Host ""
Read-Host "Pressione ENTER para iniciar"

# ============================================================
# BLOCO 10 - Instalacoes por perfil
#
# COMO ADICIONAR UM NOVO APP SILENCIOSO:
#   $resultado = Install-App -Nome "Nome do App" -Arquivo "arquivo.exe" -Argumentos "/silent"
#   if ($resultado -eq "erro") { $AppsFalharam += @{ Nome = "Nome do App"; Arquivo = "arquivo.exe"; Argumentos = "/silent" } }
#
# COMO ADICIONAR UM APP EXCLUSIVO DE UM PERFIL:
#   if ($Perfil -eq "Notebook") {
#       $resultado = Install-App -Nome "Nome do App" -Arquivo "arquivo.exe" -Argumentos "/silent"
#       if ($resultado -eq "erro") { $AppsFalharam += @{ Nome = "Nome do App"; Arquivo = "arquivo.exe"; Argumentos = "/silent" } }
#   }
#
# ARGUMENTOS SILENCIOSOS MAIS COMUNS:
#   EXE: /silent   /S   /quiet   --silent
#   MSI: /quiet    /qn  /passive
#   Para descobrir: .\\instalador.exe /?  ou  .\\instalador.exe --help
# ============================================================

# --- Apps em comum para Desktop e Notebook ---
# Adapte os nomes de arquivo para os seus instaladores

$resultado = Install-App -Nome "Google Chrome"    -Arquivo "ChromeSetup.exe"       -Argumentos "/silent /install"
if ($resultado -eq "erro") { $AppsFalharam += @{ Nome = "Google Chrome";    Arquivo = "ChromeSetup.exe";       Argumentos = "/silent /install" } }

$resultado = Install-App -Nome "App Silencioso 2" -Arquivo "instalador2.msi"       -Argumentos "/quiet"
if ($resultado -eq "erro") { $AppsFalharam += @{ Nome = "App Silencioso 2"; Arquivo = "instalador2.msi";       Argumentos = "/quiet" } }

$resultado = Install-App -Nome "App Silencioso 3" -Arquivo "instalador3.exe"       -Argumentos "/S"
if ($resultado -eq "erro") { $AppsFalharam += @{ Nome = "App Silencioso 3"; Arquivo = "instalador3.exe";       Argumentos = "/S" } }

# --- Apps exclusivos do Notebook ---
if ($Perfil -eq "Notebook") {
    $resultado = Install-App -Nome "App Notebook 1" -Arquivo "instalador_nb1.exe"  -Argumentos "/silent"
    if ($resultado -eq "erro") { $AppsFalharam += @{ Nome = "App Notebook 1"; Arquivo = "instalador_nb1.exe"; Argumentos = "/silent" } }

    $resultado = Install-App -Nome "App Notebook 2" -Arquivo "instalador_nb2.exe"  -Argumentos "/SILENT"
    if ($resultado -eq "erro") { $AppsFalharam += @{ Nome = "App Notebook 2"; Arquivo = "instalador_nb2.exe"; Argumentos = "/SILENT" } }
}

# ============================================================
# BLOCO 11 - Tentativa de correcao dos que falharam
# ============================================================
if ($AppsFalharam.Count -gt 0) {
    Write-Host ""
    Write-Host "================================================" -ForegroundColor Red
    Write-Host "  ATENCAO: Os seguintes apps falharam:" -ForegroundColor Red
    foreach ($app in $AppsFalharam) {
        Write-Host "  - $($app.Nome)" -ForegroundColor Red
    }
    Write-Host "================================================" -ForegroundColor Red
    Write-Host ""
    Read-Host "Pressione ENTER para tentar reinstalar automaticamente"

    $AindaComErro = @()

    foreach ($app in $AppsFalharam) {
        Reinstalar-App -Nome $app.Nome -Arquivo $app.Arquivo -Argumentos $app.Argumentos

        if (Test-Path "$Base\$($app.Arquivo)") {
            $AindaComErro += $app.Nome
        }
    }

    if ($AindaComErro.Count -gt 0) {
        Write-Host ""
        Write-Host "================================================" -ForegroundColor Red
        Write-Host "  Os seguintes apps precisam de instalacao manual:" -ForegroundColor Red
        foreach ($nome in $AindaComErro) {
            Write-Host "  - $nome" -ForegroundColor Red
        }
        Write-Host "================================================" -ForegroundColor Red
        Add-Content -Path $LogFile -Value "$(Get-Date) | FINALIZACAO | Apps para instalacao manual: $($AindaComErro -join ', ')"
    }
}

# ============================================================
# BLOCO 12 - Instalacoes manuais
#
# COMO ADICIONAR UM APP MANUAL:
#   Install-Manual -Nome "Nome do App" -Arquivo "instalador.exe"
# ============================================================
Write-Host ""
Write-Host "================================================" -ForegroundColor Yellow
Write-Host "  PROXIMA ETAPA: Instalacoes manuais" -ForegroundColor Yellow
Write-Host "================================================" -ForegroundColor Yellow

# Adicione aqui os apps que exigem instalacao manual
Install-Manual -Nome "App Manual 1" -Arquivo "instalador_manual1.exe"

if ($Perfil -eq "Notebook") {
    Install-Manual -Nome "App Manual Notebook" -Arquivo "instalador_manual_nb.exe"
} else {
    Install-Manual -Nome "App Manual Desktop"  -Arquivo "instalador_manual_dt.exe"
}

# ============================================================
# BLOCO 13 - Limpeza e finalizacao
# ============================================================
$InstaladoreSobrando = Get-ChildItem -Path $Base -File -ErrorAction SilentlyContinue |
                       Where-Object { $_.Extension -ne ".ps1" }

if ($InstaladoreSobrando.Count -eq 0) {
    Write-Host ""
    Write-Host "Limpando pasta temporaria..." -ForegroundColor Gray
    Remove-Item -Path $Base -Recurse -Force -ErrorAction SilentlyContinue
    Write-Host "Pasta temporaria removida." -ForegroundColor Gray
} else {
    Write-Host ""
    Write-Host "Pasta temporaria mantida pois ainda ha instaladores pendentes." -ForegroundColor Yellow
}

Write-Host ""
Write-Host "================================================" -ForegroundColor Green
Write-Host "   INSTALACAO CONCLUIDA!" -ForegroundColor Green
Write-Host "   Log salvo em: $LogFile" -ForegroundColor Green
Write-Host "   Maquina : $Hostname" -ForegroundColor Green
Write-Host "   Perfil  : $Perfil" -ForegroundColor Green
Write-Host "   Fim     : $(Get-Date -Format 'dd/MM/yyyy HH:mm')" -ForegroundColor Green
Write-Host "================================================" -ForegroundColor Green

Add-Content -Path $LogFile -Value "$(Get-Date) | FIM | Instalacao finalizada"

Read-Host "Pressione ENTER para sair"
