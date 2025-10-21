# 📚 API Reference - SafeKeyLicensing

## 🌐 Información General de la API

### Base URL
```
Desarrollo: https://localhost:7000/api
Producción: https://api.safekeylicensing.com/api
```

### Autenticación
La API utiliza múltiples métodos de autenticación dependiendo del endpoint:

#### 1. JWT Bearer Token (Para usuarios del sistema)
```http
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

#### 2. API Key (Para validación de licencias)
```http
X-API-Key: your-license-api-key
```

#### 3. Admin Key (Para operaciones administrativas)
```http
X-Admin-Key: admin-master-key
```

### Formato de Respuesta
Todas las respuestas siguen el formato JSON estándar:

```json
{
  "success": true,
  "data": { /* contenido específico */ },
  "message": "Operation completed successfully",
  "timestamp": "2025-10-20T10:30:00Z"
}
```

### Códigos de Estado HTTP
- `200` - OK: Operación exitosa
- `201` - Created: Recurso creado exitosamente
- `400` - Bad Request: Error en los parámetros de entrada
- `401` - Unauthorized: Autenticación requerida
- `403` - Forbidden: Sin permisos para la operación
- `404` - Not Found: Recurso no encontrado
- `429` - Too Many Requests: Límite de requests excedido
- `500` - Internal Server Error: Error interno del servidor

## 🔐 Endpoints de Autenticación

### POST /auth/login
Autentica un usuario y obtiene un JWT token.

**Request:**
```json
{
  "email": "usuario@ejemplo.com",
  "password": "mi-password",
  "tenantId": "mi-tenant-id"
}
```

**Response:**
```json
{
  "success": true,
  "data": {
    "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "refreshToken": "refresh-token-here",
    "expiresIn": 3600,
    "user": {
      "id": "user-id",
      "email": "usuario@ejemplo.com",
      "name": "Usuario Ejemplo",
      "tenantId": "mi-tenant-id"
    }
  },
  "message": "Login successful"
}
```

### POST /auth/register
Registra un nuevo usuario en el sistema.

**Request:**
```json
{
  "email": "nuevo@ejemplo.com",
  "password": "password-seguro",
  "confirmPassword": "password-seguro",
  "firstName": "Nombre",
  "lastName": "Apellido",
  "tenantId": "tenant-id"
}
```

**Response:**
```json
{
  "success": true,
  "data": {
    "userId": "new-user-id",
    "email": "nuevo@ejemplo.com",
    "emailConfirmationRequired": true
  },
  "message": "User registered successfully. Please check your email to confirm your account."
}
```

### POST /auth/refresh-token
Renueva un JWT token usando el refresh token.

**Request:**
```json
{
  "refreshToken": "current-refresh-token"
}
```

**Response:**
```json
{
  "success": true,
  "data": {
    "token": "new-jwt-token",
    "refreshToken": "new-refresh-token",
    "expiresIn": 3600
  },
  "message": "Token refreshed successfully"
}
```

## 🏢 Endpoints de Tenants

### GET /tenants/{tenantId}
Obtiene información detallada de un tenant.

**Headers:**
```http
Authorization: Bearer {jwt-token}
```

**Response:**
```json
{
  "success": true,
  "data": {
    "id": 1,
    "tenantId": "mi-tenant",
    "nombre": "Mi Empresa",
    "descripcion": "Descripción de la empresa",
    "plan": "Professional",
    "activo": true,
    "maxLicencias": 500,
    "maxUsuarios": 50,
    "maxSoftwares": 20,
    "fechaCreacion": "2025-01-01T00:00:00Z",
    "estadisticas": {
      "licenciasActivas": 45,
      "totalSolicitudes": 120,
      "ingresosMesActual": 2500.00
    }
  }
}
```

### PUT /tenants/{tenantId}
Actualiza la información de un tenant.

**Headers:**
```http
Authorization: Bearer {jwt-token}
```

**Request:**
```json
{
  "nombre": "Nuevo Nombre",
  "descripcion": "Nueva descripción",
  "contactEmail": "contacto@empresa.com",
  "website": "https://empresa.com",
  "logoUrl": "https://empresa.com/logo.png"
}
```

### GET /tenants/{tenantId}/statistics
Obtiene estadísticas detalladas del tenant.

**Response:**
```json
{
  "success": true,
  "data": {
    "licenciasActivas": 45,
    "licenciasVencidas": 5,
    "totalSoftwares": 8,
    "totalUsuarios": 12,
    "ingresosTotales": 15000.00,
    "ingresosMesActual": 2500.00,
    "crecimientoMensual": 12.5,
    "distribucionLicencias": {
      "basicas": 20,
      "profesionales": 15,
      "premium": 8,
      "enterprise": 2
    }
  }
}
```

## 💿 Endpoints de Software

### GET /software
Lista todo el software del tenant actual.

**Headers:**
```http
Authorization: Bearer {jwt-token}
```

**Query Parameters:**
- `page` (int): Número de página (default: 1)
- `pageSize` (int): Elementos por página (default: 10)
- `search` (string): Búsqueda por nombre o código
- `activo` (bool): Filtrar por estado activo

**Response:**
```json
{
  "success": true,
  "data": {
    "items": [
      {
        "id": 1,
        "nombre": "Mi Software Pro",
        "codigo": "MSP-001",
        "version": "2.1.0",
        "descripcion": "Software profesional para...",
        "activo": true,
        "fechaCreacion": "2025-01-15T10:00:00Z",
        "totalLicencias": 25,
        "licenciasActivas": 20
      }
    ],
    "totalItems": 8,
    "totalPages": 1,
    "currentPage": 1,
    "pageSize": 10
  }
}
```

### POST /software
Crea un nuevo software.

**Request:**
```json
{
  "nombre": "Nuevo Software",
  "codigo": "NS-001",
  "version": "1.0.0",
  "descripcion": "Descripción del software"
}
```

### PUT /software/{id}
Actualiza un software existente.

**Request:**
```json
{
  "nombre": "Nombre Actualizado",
  "version": "1.0.1",
  "descripcion": "Nueva descripción",
  "activo": true
}
```

### DELETE /software/{id}
Elimina un software (soft delete).

## 📜 Endpoints de Tipos de Licencia

### GET /license-types
Lista los tipos de licencia del tenant.

**Response:**
```json
{
  "success": true,
  "data": [
    {
      "id": 1,
      "nombre": "Básica",
      "codigo": "LIC-0001",
      "precioMin": 10.00,
      "precioMax": 10.00,
      "descripcion": "Licencia básica con funciones core",
      "duracionDias": 30,
      "activo": true
    },
    {
      "id": 2,
      "nombre": "Profesional",
      "codigo": "LIC-0002",
      "precioMin": 10.00,
      "precioMax": 30.00,
      "descripcion": "Licencia profesional avanzada",
      "duracionDias": 30,
      "activo": true
    }
  ]
}
```

### POST /license-types
Crea un nuevo tipo de licencia.

**Request:**
```json
{
  "nombre": "Enterprise Custom",
  "codigo": "LIC-ENT-001",
  "precioMin": 100.00,
  "precioMax": 500.00,
  "descripcion": "Licencia enterprise personalizada",
  "duracionDias": 365
}
```

## 🎫 Endpoints de Licencias

### GET /licenses/validate/{apiKey}
Valida una licencia por su API Key (endpoint público).

**Headers:**
```http
X-API-Key: {api-key-de-la-licencia}
```

**Response (Licencia Válida):**
```json
{
  "success": true,
  "data": {
    "isValid": true,
    "license": {
      "id": 123,
      "licenciaId": "LIC-2025-001",
      "apiKey": "api-key-here",
      "status": "ACTIVA",
      "fechaVencimiento": "2025-11-20T00:00:00Z",
      "software": {
        "nombre": "Mi Software Pro",
        "version": "2.1.0"
      },
      "tipoLicencia": {
        "nombre": "Profesional",
        "codigo": "LIC-0002"
      }
    },
    "hardwareInfo": {
      "hddId": "WD-1234567890",
      "motherboardId": "MB-ABCD-1234"
    },
    "remainingDays": 31
  },
  "message": "License is valid"
}
```

**Response (Licencia Inválida):**
```json
{
  "success": false,
  "data": {
    "isValid": false,
    "reason": "expired"
  },
  "message": "License has expired"
}
```

### POST /licenses/heartbeat
Envía un heartbeat para mantener la licencia activa.

**Headers:**
```http
X-API-Key: {api-key-de-la-licencia}
```

**Request:**
```json
{
  "hardwareInfo": {
    "hddId": "WD-1234567890",
    "motherboardId": "MB-ABCD-1234",
    "cpuId": "CPU-9876543210"
  },
  "softwareVersion": "2.1.0",
  "additionalData": {
    "osVersion": "Windows 11",
    "lastUsed": "2025-10-20T10:30:00Z"
  }
}
```

**Response:**
```json
{
  "success": true,
  "data": {
    "heartbeatAccepted": true,
    "nextHeartbeatDue": "2025-10-20T11:30:00Z",
    "licenseStatus": "ACTIVA",
    "warningsCount": 0
  },
  "message": "Heartbeat recorded successfully"
}
```

### GET /licenses
Lista las licencias del tenant actual.

**Headers:**
```http
Authorization: Bearer {jwt-token}
```

**Query Parameters:**
- `status` (string): Filtrar por estado (ACTIVA, EXPIRADA, SUSPENDIDA)
- `softwareId` (int): Filtrar por software
- `desde` (date): Fecha desde
- `hasta` (date): Fecha hasta

**Response:**
```json
{
  "success": true,
  "data": {
    "items": [
      {
        "id": 123,
        "licenciaId": "LIC-2025-001",
        "apiKey": "****-****-****-1234",
        "status": "ACTIVA",
        "fechaInicio": "2025-10-01T00:00:00Z",
        "fechaVencimiento": "2025-11-01T00:00:00Z",
        "ultimoHeartbeat": "2025-10-20T10:25:00Z",
        "cliente": {
          "nombre": "Juan Pérez",
          "email": "juan@ejemplo.com"
        },
        "software": {
          "nombre": "Mi Software Pro",
          "version": "2.1.0"
        },
        "tipoLicencia": {
          "nombre": "Profesional"
        }
      }
    ],
    "totalItems": 45,
    "totalPages": 5,
    "currentPage": 1
  }
}
```

### POST /licenses/request
Crea una nueva solicitud de licencia.

**Request:**
```json
{
  "softwareId": 1,
  "tipoLicenciaId": 2,
  "clienteInfo": {
    "nombre": "Juan Pérez",
    "email": "juan@ejemplo.com",
    "empresa": "Empresa SA",
    "telefono": "+52-555-1234567"
  },
  "hardwareInfo": {
    "hddId": "WD-1234567890",
    "motherboardId": "MB-ABCD-1234"
  },
  "precio": 25.00,
  "notas": "Solicitud para uso comercial"
}
```

**Response:**
```json
{
  "success": true,
  "data": {
    "solicitudId": "SOL-2025-001234",
    "status": "Pendiente",
    "fechaSolicitud": "2025-10-20T10:30:00Z",
    "precio": 25.00,
    "pagoRequerido": true,
    "linkPago": "https://checkout.stripe.com/pay/..."
  },
  "message": "License request created successfully"
}
```

### PUT /licenses/{id}/status
Actualiza el estado de una licencia (solo administradores).

**Request:**
```json
{
  "status": "SUSPENDIDA",
  "motivo": "Violación de términos de uso",
  "notificarCliente": true
}
```

## 💳 Endpoints de Pagos

### POST /payments/create
Crea un nuevo pago para una solicitud de licencia.

**Request:**
```json
{
  "solicitudId": "SOL-2025-001234",
  "metodoPago": "stripe",
  "monto": 25.00,
  "moneda": "USD",
  "datosCliente": {
    "nombre": "Juan Pérez",
    "email": "juan@ejemplo.com"
  }
}
```

**Response:**
```json
{
  "success": true,
  "data": {
    "pagoId": "PAG-0001",
    "status": "Pendiente",
    "monto": 25.00,
    "moneda": "USD",
    "clientSecret": "pi_1234567890_secret_...",
    "linkPago": "https://checkout.stripe.com/pay/...",
    "fechaExpiracion": "2025-10-21T10:30:00Z"
  }
}
```

### GET /payments/{pagoId}/status
Consulta el estado de un pago.

**Response:**
```json
{
  "success": true,
  "data": {
    "pagoId": "PAG-0001",
    "status": "Completado",
    "monto": 25.00,
    "moneda": "USD",
    "metodoPago": "stripe",
    "fechaPago": "2025-10-20T10:35:00Z",
    "referenciaExterna": "pi_1234567890",
    "solicitud": {
      "solicitudId": "SOL-2025-001234",
      "status": "Pagada"
    }
  }
}
```

### POST /payments/webhook/stripe
Webhook para procesar notificaciones de Stripe.

**Headers:**
```http
Stripe-Signature: t=1234567890,v1=signature...
```

### POST /payments/webhook/paypal
Webhook para procesar notificaciones de PayPal.

## 📊 Endpoints de Reportes y Analytics

### GET /reports/dashboard
Obtiene datos del dashboard principal.

**Response:**
```json
{
  "success": true,
  "data": {
    "resumen": {
      "licenciasActivas": 45,
      "ingresosMes": 2500.00,
      "nuevasLicenciasHoy": 3,
      "solicitudesPendientes": 8
    },
    "graficas": {
      "ingresosPorMes": [
        { "mes": "2025-01", "ingresos": 1800.00 },
        { "mes": "2025-02", "ingresos": 2200.00 },
        { "mes": "2025-03", "ingresos": 2500.00 }
      ],
      "licenciasPorTipo": [
        { "tipo": "Básica", "cantidad": 20 },
        { "tipo": "Profesional", "cantidad": 15 },
        { "tipo": "Premium", "cantidad": 8 },
        { "tipo": "Enterprise", "cantidad": 2 }
      ]
    }
  }
}
```

### GET /reports/licenses
Reporte detallado de licencias.

**Query Parameters:**
- `desde` (date): Fecha inicio del reporte
- `hasta` (date): Fecha fin del reporte
- `formato` (string): json, csv, pdf

### GET /reports/revenue
Reporte de ingresos.

**Query Parameters:**
- `periodo` (string): mes, trimestre, año
- `año` (int): Año del reporte
- `mes` (int): Mes específico (opcional)

## 🔧 Endpoints Administrativos

### GET /admin/tenants
Lista todos los tenants (solo super admin).

**Headers:**
```http
X-Admin-Key: {admin-master-key}
```

### GET /admin/system/health
Verifica el estado del sistema.

**Response:**
```json
{
  "success": true,
  "data": {
    "status": "Healthy",
    "timestamp": "2025-10-20T10:30:00Z",
    "services": {
      "database": "Healthy",
      "redis": "Healthy",
      "stripe": "Healthy",
      "paypal": "Healthy"
    },
    "metrics": {
      "uptime": "15 days, 8 hours",
      "totalRequests": 125000,
      "averageResponseTime": "145ms",
      "errorRate": "0.02%"
    }
  }
}
```

### GET /admin/system/metrics
Obtiene métricas del sistema.

**Response:**
```json
{
  "success": true,
  "data": {
    "performance": {
      "requestsPerSecond": 25.5,
      "averageResponseTime": 145,
      "p95ResponseTime": 320,
      "errorRate": 0.02
    },
    "business": {
      "totalTenants": 15,
      "totalActiveLicenses": 450,
      "totalRevenue": 25000.00,
      "monthlyGrowth": 12.5
    },
    "infrastructure": {
      "cpuUsage": 35.2,
      "memoryUsage": 68.5,
      "diskUsage": 42.1,
      "databaseConnections": 12
    }
  }
}
```

## 🚨 Códigos de Error Específicos

### Errores de Autenticación (401)
```json
{
  "success": false,
  "error": {
    "code": "INVALID_CREDENTIALS",
    "message": "Invalid email or password",
    "details": "The provided credentials do not match any user in the system"
  }
}
```

### Errores de Licencia (400)
```json
{
  "success": false,
  "error": {
    "code": "LICENSE_EXPIRED",
    "message": "License has expired",
    "details": "License expired on 2025-10-15T00:00:00Z"
  }
}
```

### Errores de Tenant (403)
```json
{
  "success": false,
  "error": {
    "code": "TENANT_LIMIT_EXCEEDED",
    "message": "Tenant license limit exceeded",
    "details": "Current: 100, Limit: 100. Upgrade your plan to create more licenses"
  }
}
```

## 📝 Rate Limiting

La API implementa rate limiting por endpoint:

- **Autenticación**: 5 requests por minuto por IP
- **Validación de licencias**: 100 requests por minuto por API Key
- **Endpoints generales**: 60 requests por minuto por usuario autenticado
- **Webhooks**: 1000 requests por minuto

Cabeceras de respuesta:
```http
X-RateLimit-Limit: 60
X-RateLimit-Remaining: 59
X-RateLimit-Reset: 1635724800
```

## 🔄 Versionado de API

La API utiliza versionado en la URL:
- **v1**: `/api/v1/licenses/validate` (versión actual)
- **v2**: `/api/v2/licenses/validate` (próxima versión)

Cabecera de versión:
```http
API-Version: 1.0
```

---

**Última actualización**: Octubre 2025  
**Versión de API**: 1.0  
**Documentación mantenida por**: Equipo de Desarrollo SafeKeyLicensing