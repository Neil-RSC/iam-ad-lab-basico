# Laboratorio de IAM con Active Directory

> Laboratorio básico pero real de gestión de identidades y accesos (IAM): controlador de dominio, cliente unido al dominio, usuarios y grupos, permisos sobre recursos compartidos, política de grupo, automatización con PowerShell y auditoría básica de inicio de sesión.

![Estado](https://img.shields.io/badge/estado-completado-brightgreen)
![Nivel](https://img.shields.io/badge/nivel-principiante-blue)
![Entorno](https://img.shields.io/badge/entorno-VirtualBox-orange)

---

## Descripción

Montaje paso a paso de un entorno básico de **Active Directory** en un laboratorio virtual aislado, practicando los fundamentos de IAM que se usan en empresas reales:

- Un **servidor** como controlador de dominio (**DC01**)
- Un **equipo cliente** unido al dominio (**WS01**)
- Usuarios y grupos organizados en unidades organizativas (OUs)
- Una **carpeta compartida** con permisos basados en grupos
- Una **política de grupo (GPO)** sencilla
- Un **script en PowerShell** que automatiza la creación de usuarios
- Revisión de **auditoría básica** en el registro de Seguridad

## Tecnologías y herramientas

| Herramienta | Uso |
| --- | --- |
| Windows Server 2022 (Evaluation) | Controlador de dominio, AD DS, DNS |
| Windows 10 | Equipo cliente del dominio |
| VirtualBox | Hipervisor (red solo-anfitrión / Host-Only) |
| Active Directory Domain Services | Servicio de identidades centralizado |
| DNS | Resolución de nombres del dominio `lab.local` |
| GPO | Administración de directivas de grupo |
| PowerShell | Automatización de alta de usuarios |

## Entorno del laboratorio

| Máquina | SO | Rol | RAM | Disco | IP |
| --- | --- | --- | --- | --- | --- |
| **DC01** | Windows Server 2022 Standard Eval (Desktop Experience) | Controlador de dominio + DNS | 2048 MB | 40 GB | 192.168.56.10 |
| **WS01** | Windows 10 | Cliente unido al dominio | 2048 MB | 50 GB | 192.168.56.20 |

- **Hipervisor:** VirtualBox, red **solo-anfitrión (vboxnet0)** con DHCP deshabilitado — el laboratorio está aislado de la red doméstica.
- **Host:** Windows 10 Enterprise LTSC 21H2 · i5 6ª gen · 8 GB RAM · 500 GB disco.
- **Dominio:** `lab.local` (NetBIOS: `LAB`)

### Estructura lógica de AD

```javascript
lab.local
└── LAB-Corp
    ├── Usuarios   (ana.garcia, andres.lugo, luis.perez, marta.sanchez,
    │               sofia.mendez, veronica.ortiz...)
    └── Grupos     (GG-TI)
```

---

## Fases del proyecto

### Fase 1 — Preparación del equipo

Activación de VT-x en BIOS, deshabilitar Hyper-V para evitar conflictos con VirtualBox, organización del disco (`D:\LAB-IAM\ISOs | VMs | Docs`) y plan de recursos para trabajar con solo 8 GB de RAM.

### Fase 2 — Descarga de software

ISO de **Windows Server 2022 Evaluation** (gratis, 180 días) desde el Microsoft Evaluation Center e ISO de Windows 10 para el cliente.

### Fases 3-4 — Creación e instalación de DC01

VM en VirtualBox (2 vCPU, 2048 MB RAM, VDI dinámico de 40 GB) con la ISO de Windows Server montada. Se instaló la edición **Standard Evaluation con Desktop Experience**, se estableció contraseña del Administrador local, se renombró el equipo a **DC01** y se configuró IP fija (192.168.56.10, DNS 127.0.0.1).

### Fase 5 — Red del laboratorio

Red **solo-anfitrión (vboxnet0)** creada con DHCP deshabilitado y asignada a ambas VMs, de modo que DC01 y WS01 se comunican entre sí y con el host sin tocar la red doméstica.

### Fase 6 — Promoción a Controlador de Dominio

Instalación del rol **Servicios de dominio de Active Directory (AD DS)** y del rol **DNS**:

| Instalación del rol AD DS | Progreso de la instalación |
| --- | --- |
| ![fase6-1](docs/capturas/fase06-01-instalar-rol-adds.png) | ![fase6-2](docs/capturas/fase06-02-progreso-instalacion-adds.png) |

Tras la instalación, desde la bandera de notificación se promovió el servidor: **nuevo bosque** con dominio raíz `lab.local`, contraseña DSRM configurada, y reinicio automático:

| Notificación "Promover este servidor" | Inicio de sesión como LAB\Administrador |
| --- | --- |
| ![fase6-3](docs/capturas/fase06-03-notificacion-promover-dc.png) | ![fase6-4](docs/capturas/fase06-04-login-lab-administrador.png) |

**Verificación:** el dominio `lab.local` visible en *Usuarios y equipos de Active Directory*, y `nslookup lab.local` resolviendo a **192.168.56.10**:

| ADUC con el dominio lab.local | nslookup lab.local → 192.168.56.10 |
| --- | --- |
| ![fase6-5](docs/capturas/fase06-05-aduc-dominio-lab-local.png) | ![fase6-6](docs/capturas/fase06-06-nslookup-verificacion.png) |

### Fase 7 — Cliente WS01 y unión al dominio

Instalación de Windows 10 en la segunda VM y configuración de red con IP fija (192.168.56.20, máscara 255.255.255.0, **DNS 192.168.56.10** — esencial para "ver" el dominio):

| Instalación de Windows en WS01 | IP fija y DNS de WS01 |
| --- | --- |
| ![fase7-1](docs/capturas/fase07-01-instalacion-windows-cliente.png) | ![fase7-3](docs/capturas/fase07-03-ip-fija-ws01.png) |

#### Solución de problemas

Al intentar unir WS01 al dominio apareció el error **"An Active Directory Domain Controller (AD DC) for the domain lab.local could not be contacted"**, acompañado de `ping` con "Destination host unreachable" y `nslookup` con timeouts. Esto indicaba que WS01 no alcanzaba al DNS del dominio:

| ping fallido y DNS con timeouts | Error al unirse al dominio |
| --- | --- |
| ![fase7-4](docs/capturas/fase07-04-problema-ping-dns-timeout.png) | ![fase7-5](docs/capturas/fase07-05-error-dc-no-contactado.png) |

Tras revisar la conectividad y confirmar que **DC01 estaba encendido y accesible por la red Host-Only**, la unión al dominio se completó con éxito:

![Welcome to the lab.local domain](docs/capturas/fase07-07-unido-al-dominio.png)

Finalmente se verificó el inicio de sesión con una **cuenta de dominio** (ana.garcia) en WS01:

| Inicio de sesión en el dominio LAB |
| --- |
| ![fase7-8](docs/capturas/fase07-08-login-cuenta-dominio.png) |

### Fase 8 — Usuarios y grupos en Active Directory

Creación de la estructura de OUs (**LAB-Corp → Usuarios, Grupos**) y alta manual de usuarios con contraseña temporal y **cambio obligatorio en el próximo inicio de sesión**:

| Estructura LAB-Corp en ADUC | Asistente de nuevo usuario | Resumen: Ana García (ana.garcia@lab.local) |
| --- | --- | --- |
| ![fase8-1](docs/capturas/fase08-01-estructura-ou-lab-corp.png) | ![fase8-2](docs/capturas/fase08-02-asistente-nuevo-usuario.png) | ![fase8-3](docs/capturas/fase08-03-usuario-ana-garcia.png) |

Usuarios creados en `LAB-Corp\Usuarios` y grupo de seguridad global **GG-TI** en `LAB-Corp\Grupos`:

| Usuarios creados | Creación del grupo GG-TI (Global, Seguridad) |
| --- | --- |
| ![fase8-4](docs/capturas/fase08-04-usuarios-creados.png) | ![fase8-5](docs/capturas/fase08-05-grupo-gg-ti.png) |

> **Por qué grupos:** en vez de dar permisos a cada usuario uno por uno, se asignan al grupo. Si alguien cambia de rol o se va, basta quitarlo del grupo y pierde todos los accesos automáticamente — así funciona la gestión de identidades en una empresa real.

### Fase 9 — Carpeta compartida con permisos

Carpeta `C:\Compartidos\TI` compartida en DC01; permisos NTFS de **Lectura y ejecución** solo para el grupo **GG-TI**. Desde WS01, accediendo a `\\DC01\ti` con una cuenta miembro del grupo, el acceso se concedió correctamente:

![Acceso a \\DC01\ti desde WS01](docs/capturas/fase09-01-acceso-carpeta-ti.png)

Un usuario que **no** pertenece a GG-TI recibe acceso denegado — el control de acceso basado en grupos funciona.

### Fase 10 — Política de grupo (GPO)

Desde la **Administración de directivas de grupo (GPMC)**, se creó la directiva **GPO-TI-Restricciones** vinculada a la OU LAB-Corp, con la configuración de usuario *"Prohibir acceso al Panel de control y a la configuración de PC"*:

| Consola GPMC | GPO vinculada a LAB-Corp | Editor de la directiva |
| --- | --- | --- |
| ![fase10-1](docs/capturas/fase10-01-consola-gpmc.png) | ![fase10-2](docs/capturas/fase10-02-gpo-vinculada-lab-corp.png) | ![fase10-3](docs/capturas/fase10-03-editor-gpo.png) |

En WS01 se forzó la aplicación de directivas con `gpupdate /force` y, tras cerrar y reabrir sesión, el Panel de control apareció **bloqueado por la GPO**:

| gpupdate /force como ana.garcia | Restricción aplicada en WS01 |
| --- | --- |
| ![fase10-4](docs/capturas/fase10-04-gpupdate-force.png) | ![fase10-5](docs/capturas/fase10-05-panel-control-bloqueado.png) |

### Fase 11 — Automatización con PowerShell

En empresas reales los usuarios no se crean a mano uno por uno: se automatiza. Se creó el script [`scripts/New-LabUser.ps1`](scripts/New-LabUser.ps1), que recibe nombre y apellido y en un solo comando:

1. Genera el `SamAccountName` en formato `nombre.apellido`
2. Crea el usuario en `OU=Usuarios,OU=LAB-Corp,DC=lab,DC=local`
3. Le asigna contraseña temporal con **cambio obligatorio en el próximo inicio de sesión**
4. Lo agrega al grupo **GG-TI** (hereda todos los permisos automáticamente)

| Script en el Bloc de notas | Ejecución en PowerShell |
| --- | --- |
| ![fase11-1](docs/capturas/fase11-01-script-new-labuser.png) | ![fase11-2](docs/capturas/fase11-02-ejecutando-script.png) |

Resultado: mensaje de éxito y usuario **sofia.mendez** visible en ADUC dentro de la OU correcta:

| "Usuario sofia.mendez creado correctamente" | sofia.mendez en LAB-Corp\Usuarios |
| --- | --- |
| ![fase11-3](docs/capturas/fase11-03-usuario-creado-exito.png) | ![fase11-4](docs/capturas/fase11-04-sofia-mendez-en-aduc.png) |

```powershell
.\New-LabUser.ps1 -Nombre "Sofia" -Apellido "Mendez"
```

### Fase 12 — Auditoría básica de inicio de sesión

En DC01 se abrió el **Visor de eventos → Registros de Windows → Seguridad**, donde se revisaron los eventos clave:

| ID | Significado |
| --- | --- |
| 4624 | Inicio de sesión exitoso |
| 4625 | Inicio de sesión fallido |
| 4720 | Cuenta de usuario creada |
| 4738 | Cuenta de usuario modificada |

| Visor de eventos | Registro de Seguridad (4624, 4634, 5379) |
| --- | --- |
| ![fase12-1](docs/capturas/fase12-01-visor-de-eventos.png) | ![fase12-2](docs/capturas/fase12-02-registro-seguridad.png) |

**Prueba realizada:** un inicio de sesión en WS01 con contraseña incorrecta a propósito, y comprobación posterior del evento **4625** correspondiente en DC01. Esto demuestra la idea central de la auditoría en IAM: **todo inicio de sesión, correcto o incorrecto, queda registrado**, y eso es lo que permite detectar accesos sospechosos.

---

## Aprendizajes clave

- **Gestión de identidades centralizada:** una sola cuenta de dominio permite iniciar sesión en cualquier equipo unido al dominio.
- **Permisos por grupos, no por usuarios:** se asignan permisos al grupo; al mover o dar de baja a una persona, basta quitarla del grupo para revocar todos sus accesos (principio base de AGDLP).
- **Doble capa de permisos:** permisos de *uso compartido* (SMB) y permisos **NTFS** — el acceso efectivo es la intersección de ambos.
- **Diagnóstico de red:** el error "AD DC could not be contacted" casi siempre es DNS o conectividad; verificar IP, DNS preferido y que el DC esté accesible resuelve la mayoría de los casos.
- **GPOs para cumplimiento:** la configuración de seguridad se aplica de forma centralizada y escalable.
- **Automatización con PowerShell:** reducir la alta manual de usuarios a un comando elimina errores y ahorra tiempo.
- **Auditoría:** cada inicio de sesión (exitoso o fallido) queda registrado en el registro de Seguridad — base para detectar accesos sospechosos.

## Checklist del proyecto

- [x] DC01 instalado y promovido a Controlador de Dominio
- [x] WS01 unido al dominio (tras solucionar error de conectividad/DNS)
- [x] Usuarios y grupo GG-TI creados
- [x] Carpeta compartida con permisos probados
- [x] GPO aplicada y verificada en WS01
- [x] Script de creación de usuarios funcionando
- [x] Eventos de seguridad revisados en el Visor de eventos (4624/4625)

## Estructura del repositorio

```javascript
iam-ad-lab-basico/
├── README.md
├── docs/
│   └── capturas/      ← evidencia por fase (Fases 6 a 12)
└── scripts/
    └── New-LabUser.ps1
```

---

