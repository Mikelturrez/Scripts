# Ruta base del registro
$claveBase32 = "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall"
$ClaveBase64 = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall"

# Ruta del log
$logPath = "c:\temp\chrome_update_log.txt"

function Escribir-Log {
    param([string]$mensaje)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "$timestamp - $mensaje" | Out-File -FilePath $logPath -Append -Encoding UTF8
}

function Buscar-Chrome-En-Registro {
    $subclaves = Get-ChildItem -Path $claveBase32
    $subclaves += Get-ChildItem -Path $ClaveBase64
    $ChromeVersion = $null
    foreach ($subclave in $subclaves) {
        try {
            $propiedades = Get-ItemProperty -Path $subclave.PSPath
            if ($propiedades.DisplayName -like "Google Chrome") {
                $global:ChromeVersion = $propiedades.Version #Ponemos la variable $global para que esté disponible fuera de la función
                break  # Salimos del bucle una vez encontrada
            }
        } catch {
            continue
        }
    }
}
Read-Host
function Obtener-Version-Remota {
    try {
        $url = "https://versionhistory.googleapis.com/v1/chrome/platforms/win64/channels/stable/versions"
        $response = Invoke-RestMethod -Uri $url -UseBasicParsing
        $version = $response.versions[0].version
        return $version
    } catch {
        Escribir-Log "Error al obtener la versión remota: $_"
        return $null
    }
}

<#function Instalar-Chrome {
    $URLConsulta = "https://dl.google.com/chrome/install/latest/chrome_installer.exe"
    $rutaDescarga = "c:\temp\chrome_installer.exe"

    try {
        Invoke-WebRequest -Uri $URLConsulta -OutFile $rutaDescarga
        Escribir-Log "Instalador descargado correctamente."

        Start-Process -FilePath $rutaDescarga -ArgumentList "/silent /install" -Wait
        Escribir-Log "Chrome instalado o actualizado correctamente."
    } catch {
        Escribir-Log "Error durante la descarga o instalación: $_"
    }
}#>
function Instalar-Chrome {
    $URLConsulta = "https://dl.google.com/chrome/install/latest/chrome_installer.exe"
    $rutaDescarga = "C:\Temp\chrome_installer.exe"

    # Crear carpeta si no existe
    if (-not (Test-Path "C:\Temp")) {
        New-Item -Path "C:\" -Name "Temp" -ItemType Directory | Out-Null
    }

    try {
        Invoke-WebRequest -Uri $URLConsulta -OutFile $rutaDescarga
        Escribir-Log "Instalador de Chrome descargado correctamente."

        # Ejecutar el instalador en modo silencioso (actualiza si ya está instalado)
        Start-Process -FilePath $rutaDescarga -ArgumentList "/silent", "/install" -Wait
        Escribir-Log "Chrome instalado o actualizado correctamente."

        Remove-Item $rutaDescarga -Force
    } catch {
        Escribir-Log "Error durante la descarga o instalación: $_"
    }
}
# Inicio
Escribir-Log "----- INICIO DEL PROCESO DE INSTALACIÓN O ACTUALIZACIÓN DE CHROME -----"

$ChromeEnRegistro = Buscar-Chrome-En-Registro
$versionRemota = Obtener-Version-Remota

if ($ChromeVersion) {
    Escribir-Log "Chrome detectado en registro: $($ChromeVersion)"
} else {
    Escribir-Log "Chrome no encontrado en registro."
}

if ($versionRemota) {
    Escribir-Log "Última versión disponible: $versionRemota"
}

if (-not $ChromeVersion) {
    Escribir-Log "Chrome no está instalado. Procediendo a instalar..."
    Instalar-Chrome
    
} elseif ($ChromeVersion -lt $versionRemota) {
    Escribir-Log "Chrome desactualizado. Procediendo a actualizar..."
    #Instalar-Chrome
    $URLConsulta = "https://dl.google.com/chrome/install/latest/chrome_installer.exe"
    $rutaDescarga = "C:\Temp\chrome_installer.exe"

    # Crear carpeta si no existe
    if (-not (Test-Path "C:\Temp")) {
        New-Item -Path "C:\" -Name "Temp" -ItemType Directory | Out-Null
    }

    try {
        Invoke-WebRequest -Uri $URLConsulta -OutFile $rutaDescarga
        Escribir-Log "Instalador de Chrome descargado correctamente."

        # Ejecutar el instalador en modo silencioso (actualiza si ya está instalado)
        Start-Process -FilePath $rutaDescarga -ArgumentList "/silent", "/install" -Wait
        Escribir-Log "Chrome instalado o actualizado correctamente."

        Remove-Item $rutaDescarga -Force
    } catch {
        Escribir-Log "Error durante la descarga o instalación: $_"
    }
} else {
    Escribir-Log "Chrome ya está actualizado."
}

Escribir-Log "----- FIN DEL PROCESO -----"