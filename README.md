# 🏫 Eureka
### Gestión escolar simplificada

Aplicación móvil desarrollada en Flutter + Firebase para facilitar la administración de alumnos, el control de conceptos de cobro y la consulta de estados de cuenta en un centro educativo.

👨‍💼 **Administrador** · 👨‍👩‍👦 **Cliente (Tutor)**

---

## 📝 Acerca del proyecto

Eureka es una aplicación móvil diseñada para optimizar el trabajo administrativo de escuelas y colegios. Permite al personal administrativo dar de alta alumnos, organizarlos por grado y grupo, crear un catálogo de conceptos (colegiaturas, inscripciones) y asignar cargos de manera sencilla.

Además, el sistema incorpora un módulo especial para los tutores (clientes), quienes pueden consultar de forma segura el estado de cuenta de sus hijos y revisar los cargos pendientes desde la comodidad de su celular.

---

## 🚀 Características principales

| Módulo Administrador | Módulo Cliente |
| :--- | :--- |
| Inicio de sesión seguro | Inicio de sesión con correo asignado |
| Gestión de Alumnos (CRUD) | Consulta de Estado de Cuenta |
| Búsqueda y filtros por Grado/Grupo | Visualización de Saldo Pendiente |
| Catálogo de Conceptos de cobro | Historial de Cargos |
| Asignación de Cargos (individual) | Diseño adaptado a móviles |
| Generación de accesos para tutores | |

---

## 🎭 Roles de usuario

### 👨‍💼 Administrador
El administrador tiene control total sobre la gestión escolar. Puede dar de alta alumnos (asignando matrícula única, grado de 1ro a 6to y grupo A/B), crear conceptos de cobro con formato de moneda y asignar cargos a los alumnos. También cuenta con un botón para generar las cuentas de acceso de los tutores automáticamente.

### 👨‍👩‍👦 Cliente (Tutor)
El cliente ingresa con el correo que la escuela le generó. Su vista es estrictamente de **solo lectura**, lo que garantiza la seguridad de los datos. Puede ver el estado de cuenta de su hijo(a), el total del saldo pendiente y los detalles de cada cargo.

---

## 🛠️ Tecnologías utilizadas

Flutter • Dart • Firebase Authentication • Cloud Firestore • Intl • Git • GitHub

---

## 🔐 Autenticación y seguridad

La aplicación utiliza Firebase Authentication para administrar el acceso. Después del inicio de sesión, el sistema identifica el rol registrado en Cloud Firestore y dirige automáticamente al usuario al módulo correspondiente.

```text
Inicio de sesión
       │
       ▼
Identificación del rol
       │
 ┌─────┴───────────┐
 ▼                 ▼
Administrador   Cliente
