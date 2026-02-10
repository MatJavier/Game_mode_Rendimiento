# Gaming Mode Manager (Batch Edition) 

Una herramienta ligera, segura y eficiente escrita en **Batch** para optimizar Windows para el gaming. Este script ajusta parámetros críticos del sistema, la red y el registro para reducir la latencia (input lag) y maximizar los recursos de la CPU.

---

##  Características principales

El script automatiza las optimizaciones más efectivas sin necesidad de instalar software de terceros:

* ** Prioridad de CPU:** Ajusta el `SystemResponsiveness` para eliminar la reserva de recursos de servicios en segundo plano.
* ** Optimización de Red:** Desactiva el *Network Throttling Index* para estabilizar el ping y reducir el lag en juegos online.
* ** Plan de Energía:** Cambia el sistema al modo de **Alto Rendimiento** (`SCHEME_MIN`).
* ** Adiós al Stuttering:** Desactiva el Game DVR y la grabación de clips en segundo plano que consumen recursos de GPU/Disco.
* ** Sistema de Reversión:** Incluye un sistema de backup automático que guarda tus valores originales antes de modificar nada.

---

##  Instrucciones de Uso

### Requisitos
* **Windows 10 o 11**.
* **Permisos de Administrador** (necesarios para modificar el registro y planes de energía).

### Pasos
1.  Descarga el archivo `GamingMode.bat`.
2.  Haz clic derecho sobre el archivo y selecciona **"Ejecutar como administrador"**.
3.  Selecciona una opción del menú interactivo:
    * **1** - Activar el Modo Gaming.
    * **2** - Restaurar la configuración original (vuelve a la normalidad).
    * **3** - Ver estado actual de los registros.

---

## 🛠️ ¿Qué es lo que hace exactamente?

Para los curiosos o usuarios avanzados, aquí están los cambios técnicos:

| Parámetro | Acción | Beneficio |
| :--- | :--- | :--- |
| **NetworkThrottlingIndex** | Establecido en `0xFFFFFFFF` | Elimina la limitación de red de Windows. |
| **SystemResponsiveness** | Establecido en `0` | Da el 100% de prioridad a las aplicaciones en primer plano. |
| **Power Plan** | Activa `High Performance` | Evita que la CPU baje su frecuencia para ahorrar energía. |
| **Game DVR** | Desactivado | Libera ciclos de CPU y reduce tirones (stuttering). |
| **TCP Autotuning** | Ajustado a `Normal` | Optimiza el flujo de paquetes de datos. |

---

##  Seguridad y Logs

El script es transparente y preventivo:
* **Backups:** Crea una clave en `HKCU\Software\GamingModeManager` con tus valores antiguos.
* **Logs:** Cada vez que lo ejecutas, se genera un archivo `.log` en la misma carpeta detallando cada cambio realizado por si necesitas revisarlo.

---

##  Descargo de Responsabilidad

*Este script se proporciona "tal cual". Aunque incluye una función de restauración probada, siempre se recomienda crear un **Punto de Restauración del Sistema** antes de realizar modificaciones en el registro de Windows.*

---

**¿Dudas o sugerencias?** ¡Siéntete libre de abrir un issue o hacer un fork!
