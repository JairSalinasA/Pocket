# 🛠️ Guía de Desarrollo - SafeKeyLicensing

## 🚀 Configuración del Entorno de Desarrollo

### Prerrequisitos del Sistema

#### Software Requerido
- **Visual Studio 2022** (17.14+) o **VS Code** con extensiones C#
- **.NET 8.0 SDK** (Latest)
- **PostgreSQL 15+** (con pgAdmin opcional)
- **Redis** (para caching distribuido)
- **Git** (para control de versiones)
- **Docker Desktop** (opcional, para contenedores)

#### Extensiones Recomendadas para VS Code
```json
{
  "recommendations": [
    "ms-dotnettools.csharp",
    "ms-dotnettools.csdevkit",
    "ms-vscode.vscode-json",
    "humao.rest-client",
    "formulahendry.auto-rename-tag",
    "bradlc.vscode-tailwindcss",
    "ms-dotnettools.blazorwasm-companion"
  ]
}
```

### Configuración Inicial del Proyecto

#### 1. Clonar el Repositorio
```bash
git clone https://github.com/tu-usuario/SafeKeyLicensing.git
cd SafeKeyLicensing
```

#### 2. Configurar Base de Datos PostgreSQL
```bash
# Ya tienes PostgreSQL instalado con estas credenciales:
# Host: localhost
# Port: 5432  
# Database: SafeKeyLicensing
# Username: postgres
# Password: admin

# Conectar a PostgreSQL y verificar conexión
psql -h localhost -p 5432 -U postgres -d postgres

# En el prompt de PostgreSQL, crear la base de datos si no existe:
CREATE DATABASE "SafeKeyLicensing" 
WITH 
OWNER = postgres
ENCODING = 'UTF8'
LC_COLLATE = 'en_US.UTF-8'
LC_CTYPE = 'en_US.UTF-8';

# Conectar a la nueva base de datos
\c SafeKeyLicensing

# Habilitar extensiones necesarias para funcionalidades NoSQL
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";    -- Generación de UUIDs
CREATE EXTENSION IF NOT EXISTS "hstore";       -- Almacenamiento clave-valor
CREATE EXTENSION IF NOT EXISTS "pg_trgm";      -- Búsqueda difusa
CREATE EXTENSION IF NOT EXISTS "btree_gin";    -- Índices GIN optimizados

\q

# Ejecutar script de extensiones avanzadas (opcional)
psql -h localhost -p 5432 -U postgres -d SafeKeyLicensing -f scripts/init-postgresql-extensions.sql

# Ejecutar script principal de base de datos
psql -h localhost -p 5432 -U postgres -d SafeKeyLicensing -f SafeKeyLicensing_BD.sql
```

#### 3. Configurar Variables de Entorno
```bash
# Copiar archivo de configuración
cp appsettings.example.json appsettings.Development.json

# Editar configuraciones de desarrollo
# Actualizar connection strings, API keys, etc.
```

#### 4. Restaurar Paquetes y Compilar
```bash
dotnet restore
dotnet build
```

#### 5. Ejecutar Migraciones de Entity Framework
```bash
dotnet ef database update --project SafeKeyLicensing
```

#### 6. Ejecutar la Aplicación
```bash
dotnet run --project SafeKeyLicensing
```

## 📁 Estructura del Proyecto Detallada

```
SafeKeyLicensingSol/
├── 📁 SafeKeyLicensing/                    # 🌐 Aplicación Principal
│   ├── 📁 Areas/
│   │   └── 📁 Identity/                    # Área de autenticación
│   ├── 📁 Controllers/                     # Controladores MVC/API
│   │   ├── HomeController.cs
│   │   ├── LicenseController.cs
│   │   ├── PaymentController.cs
│   │   └── TenantController.cs
│   ├── 📁 Data/                           # Contexto y configuraciones EF
│   │   ├── ApplicationDbContext.cs
│   │   ├── Configurations/
│   │   └── Migrations/
│   ├── 📁 Models/                         # Modelos de dominio
│   │   ├── Entities/
│   │   ├── DTOs/
│   │   └── ViewModels/
│   ├── 📁 Services/                       # Servicios de negocio
│   │   ├── Interfaces/
│   │   ├── LicenseService.cs
│   │   ├── PaymentService.cs
│   │   └── TenantService.cs
│   ├── 📁 Repositories/                   # Repositorios de datos
│   │   ├── Interfaces/
│   │   └── Implementations/
│   ├── 📁 Middleware/                     # Middleware personalizado
│   │   ├── TenantMiddleware.cs
│   │   └── ErrorHandlingMiddleware.cs
│   ├── 📁 Extensions/                     # Métodos de extensión
│   ├── 📁 Utilities/                      # Utilidades y helpers
│   ├── 📁 Views/                          # Vistas Razor
│   ├── 📁 wwwroot/                        # Archivos estáticos
│   └── Program.cs                         # Punto de entrada
├── 📁 SafeKeyLicensing.Tests/             # 🧪 Pruebas
│   ├── 📁 UnitTests/
│   ├── 📁 IntegrationTests/
│   └── 📁 TestUtilities/
├── 📁 SafeKeyLicensingSol.AppHost/        # 🚀 .NET Aspire Host
└── 📁 SafeKeyLicensingSol.ServiceDefaults/ # ⚙️ Configuraciones compartidas
```

## 🎯 Estándares de Desarrollo

### Convenciones de Nomenclatura

#### Clases y Métodos
```csharp
// ✅ Correcto - PascalCase para clases y métodos públicos
public class LicenseService : ILicenseService
{
    public async Task<License> CreateLicenseAsync(CreateLicenseRequest request)
    {
        // Implementación
    }
    
    // ✅ camelCase para métodos privados
    private async Task<bool> validateHardwareAsync(string hardwareId)
    {
        // Implementación
    }
}
```

#### Variables y Parámetros
```csharp
// ✅ Correcto - camelCase
public class PaymentService
{
    private readonly IPaymentRepository _paymentRepository;
    private readonly ILogger<PaymentService> _logger;
    
    public async Task ProcessPaymentAsync(PaymentRequest paymentRequest)
    {
        var tenantId = paymentRequest.TenantId;
        var paymentAmount = paymentRequest.Amount;
        // ...
    }
}
```

#### Constantes y Enums
```csharp
// ✅ Constantes - PascalCase
public static class PaymentStatus
{
    public const string Pending = "Pending";
    public const string Completed = "Completed";
    public const string Failed = "Failed";
}

// ✅ Enums - PascalCase
public enum LicenseType
{
    Basic,
    Professional,
    Premium,
    Enterprise
}
```

### Estructura de Archivos

#### Controladores
```csharp
[ApiController]
[Route("api/[controller]")]
[Authorize]
public class LicenseController : ControllerBase
{
    private readonly ILicenseService _licenseService;
    private readonly ILogger<LicenseController> _logger;
    
    public LicenseController(
        ILicenseService licenseService,
        ILogger<LicenseController> logger)
    {
        _licenseService = licenseService;
        _logger = logger;
    }
    
    /// <summary>
    /// Valida una licencia por API Key
    /// </summary>
    /// <param name="apiKey">Clave API de la licencia</param>
    /// <returns>Resultado de validación</returns>
    [HttpGet("validate/{apiKey}")]
    [AllowAnonymous]
    public async Task<ActionResult<LicenseValidationResult>> ValidateLicense(string apiKey)
    {
        try
        {
            var result = await _licenseService.ValidateApiKeyAsync(apiKey);
            return Ok(result);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error validating license with API key: {ApiKey}", apiKey);
            return StatusCode(500, "Internal server error");
        }
    }
}
```

#### Servicios
```csharp
public interface ILicenseService
{
    Task<LicenseValidationResult> ValidateApiKeyAsync(string apiKey);
    Task<License> CreateLicenseAsync(CreateLicenseRequest request);
    Task<bool> RevokeLicenseAsync(int licenseId, int tenantId);
    Task<List<License>> GetLicensesByTenantAsync(int tenantId);
}

public class LicenseService : ILicenseService
{
    private readonly IUnitOfWork _unitOfWork;
    private readonly ITenantProvider _tenantProvider;
    private readonly ILogger<LicenseService> _logger;
    
    public LicenseService(
        IUnitOfWork unitOfWork,
        ITenantProvider tenantProvider,
        ILogger<LicenseService> logger)
    {
        _unitOfWork = unitOfWork;
        _tenantProvider = tenantProvider;
        _logger = logger;
    }
    
    public async Task<LicenseValidationResult> ValidateApiKeyAsync(string apiKey)
    {
        if (string.IsNullOrWhiteSpace(apiKey))
            throw new ArgumentException("API key cannot be null or empty", nameof(apiKey));
        
        var license = await _unitOfWork.Licenses.GetByApiKeyAsync(apiKey);
        
        if (license == null)
        {
            _logger.LogWarning("License validation failed: API key not found {ApiKey}", apiKey);
            return new LicenseValidationResult { IsValid = false, Message = "Invalid API key" };
        }
        
        if (license.FechaVencimiento < DateTime.UtcNow)
        {
            _logger.LogWarning("License validation failed: License expired {LicenseId}", license.Id);
            return new LicenseValidationResult { IsValid = false, Message = "License expired" };
        }
        
        // Actualizar último heartbeat
        await _unitOfWork.Licenses.UpdateLastHeartbeatAsync(license.Id);
        await _unitOfWork.SaveChangesAsync();
        
        return new LicenseValidationResult
        {
            IsValid = true,
            License = license,
            Message = "License is valid"
        };
    }
}
```

## 🧪 Estrategia de Testing

### Configuración de Pruebas

#### xUnit Configuration
```csharp
// TestStartup.cs
public class TestStartup
{
    public void ConfigureServices(IServiceCollection services)
    {
        // Configurar base de datos en memoria
        services.AddDbContext<ApplicationDbContext>(options =>
            options.UseInMemoryDatabase(databaseName: Guid.NewGuid().ToString()));
        
        // Configurar servicios mock
        services.AddScoped<ITenantProvider, MockTenantProvider>();
        
        // Otros servicios de prueba
        services.AddLogging();
    }
}
```

#### Base para Integration Tests
```csharp
public class IntegrationTestBase : IDisposable
{
    protected readonly HttpClient _client;
    protected readonly WebApplicationFactory<Program> _factory;
    protected readonly ApplicationDbContext _context;
    
    public IntegrationTestBase()
    {
        _factory = new WebApplicationFactory<Program>()
            .WithWebHostBuilder(builder =>
            {
                builder.ConfigureServices(services =>
                {
                    // Remover base de datos real
                    var descriptor = services.SingleOrDefault(
                        d => d.ServiceType == typeof(DbContextOptions<ApplicationDbContext>));
                    
                    if (descriptor != null)
                        services.Remove(descriptor);
                    
                    // Agregar base de datos en memoria
                    services.AddDbContext<ApplicationDbContext>(options =>
                        options.UseInMemoryDatabase(Guid.NewGuid().ToString()));
                });
            });
        
        _client = _factory.CreateClient();
        _context = _factory.Services.GetRequiredService<ApplicationDbContext>();
    }
    
    protected async Task<string> CreateTestLicenseAsync()
    {
        var tenant = new Tenant { TenantId = "test-tenant", Nombre = "Test Tenant" };
        _context.Tenants.Add(tenant);
        
        var software = new Software { Nombre = "Test Software", TenantId = tenant.Id };
        _context.Software.Add(software);
        
        var license = new LicenseActive
        {
            ApiKey = Guid.NewGuid().ToString(),
            TenantId = tenant.Id,
            Status = "ACTIVA",
            FechaVencimiento = DateTime.UtcNow.AddDays(30)
        };
        _context.LicenciasActivas.Add(license);
        
        await _context.SaveChangesAsync();
        return license.ApiKey;
    }
    
    public void Dispose()
    {
        _client?.Dispose();
        _factory?.Dispose();
        _context?.Dispose();
    }
}
```

### Ejemplos de Pruebas

#### Unit Tests
```csharp
[TestClass]
public class LicenseServiceTests
{
    private Mock<IUnitOfWork> _mockUnitOfWork;
    private Mock<ITenantProvider> _mockTenantProvider;
    private Mock<ILogger<LicenseService>> _mockLogger;
    private LicenseService _licenseService;
    
    [TestInitialize]
    public void Setup()
    {
        _mockUnitOfWork = new Mock<IUnitOfWork>();
        _mockTenantProvider = new Mock<ITenantProvider>();
        _mockLogger = new Mock<ILogger<LicenseService>>();
        
        _licenseService = new LicenseService(
            _mockUnitOfWork.Object,
            _mockTenantProvider.Object,
            _mockLogger.Object);
    }
    
    [TestMethod]
    public async Task ValidateApiKey_ValidKey_ReturnsValidResult()
    {
        // Arrange
        var apiKey = "test-api-key";
        var license = new LicenseActive
        {
            Id = 1,
            ApiKey = apiKey,
            Status = "ACTIVA",
            FechaVencimiento = DateTime.UtcNow.AddDays(30)
        };
        
        _mockUnitOfWork.Setup(x => x.Licenses.GetByApiKeyAsync(apiKey))
                      .ReturnsAsync(license);
        
        // Act
        var result = await _licenseService.ValidateApiKeyAsync(apiKey);
        
        // Assert
        Assert.IsTrue(result.IsValid);
        Assert.AreEqual("License is valid", result.Message);
        Assert.IsNotNull(result.License);
        
        // Verify que se actualizó el heartbeat
        _mockUnitOfWork.Verify(x => x.Licenses.UpdateLastHeartbeatAsync(license.Id), Times.Once);
        _mockUnitOfWork.Verify(x => x.SaveChangesAsync(), Times.Once);
    }
    
    [TestMethod]
    public async Task ValidateApiKey_ExpiredLicense_ReturnsInvalidResult()
    {
        // Arrange
        var apiKey = "expired-api-key";
        var expiredLicense = new LicenseActive
        {
            Id = 1,
            ApiKey = apiKey,
            Status = "ACTIVA",
            FechaVencimiento = DateTime.UtcNow.AddDays(-1) // Expirada
        };
        
        _mockUnitOfWork.Setup(x => x.Licenses.GetByApiKeyAsync(apiKey))
                      .ReturnsAsync(expiredLicense);
        
        // Act
        var result = await _licenseService.ValidateApiKeyAsync(apiKey);
        
        // Assert
        Assert.IsFalse(result.IsValid);
        Assert.AreEqual("License expired", result.Message);
    }
    
    [TestMethod]
    public async Task ValidateApiKey_NullApiKey_ThrowsArgumentException()
    {
        // Act & Assert
        await Assert.ThrowsExceptionAsync<ArgumentException>(
            () => _licenseService.ValidateApiKeyAsync(null));
    }
}
```

#### Integration Tests
```csharp
[TestClass]
public class LicenseControllerIntegrationTests : IntegrationTestBase
{
    [TestMethod]
    public async Task ValidateLicense_ValidApiKey_ReturnsOkWithValidResult()
    {
        // Arrange
        var apiKey = await CreateTestLicenseAsync();
        
        // Act
        var response = await _client.GetAsync($"/api/license/validate/{apiKey}");
        
        // Assert
        response.EnsureSuccessStatusCode();
        
        var content = await response.Content.ReadAsStringAsync();
        var result = JsonSerializer.Deserialize<LicenseValidationResult>(content, new JsonSerializerOptions
        {
            PropertyNamingPolicy = JsonNamingPolicy.CamelCase
        });
        
        Assert.IsNotNull(result);
        Assert.IsTrue(result.IsValid);
        Assert.AreEqual("License is valid", result.Message);
    }
    
    [TestMethod]
    public async Task ValidateLicense_InvalidApiKey_ReturnsOkWithInvalidResult()
    {
        // Arrange
        var invalidApiKey = "invalid-api-key";
        
        // Act
        var response = await _client.GetAsync($"/api/license/validate/{invalidApiKey}");
        
        // Assert
        response.EnsureSuccessStatusCode();
        
        var content = await response.Content.ReadAsStringAsync();
        var result = JsonSerializer.Deserialize<LicenseValidationResult>(content, new JsonSerializerOptions
        {
            PropertyNamingPolicy = JsonNamingPolicy.CamelCase
        });
        
        Assert.IsNotNull(result);
        Assert.IsFalse(result.IsValid);
        Assert.AreEqual("Invalid API key", result.Message);
    }
}
```

## 🔄 Flujo de Trabajo con Git

### Branch Strategy
```
main/master     # 🚀 Producción - código estable
├── develop     # 🔄 Desarrollo - integración continua
├── feature/*   # ✨ Nuevas características
├── bugfix/*    # 🐛 Corrección de bugs
├── hotfix/*    # 🚨 Correcciones urgentes
└── release/*   # 📦 Preparación de releases
```

### Convención de Commits
```bash
# Formato: <tipo>(<alcance>): <descripción>
# 
# Tipos:
# feat:     Nueva funcionalidad
# fix:      Corrección de bug
# docs:     Cambios en documentación
# style:    Cambios de formato (espacios, punto y coma, etc.)
# refactor: Refactoring de código
# test:     Agregar o modificar pruebas
# chore:    Tareas de mantenimiento

# Ejemplos:
feat(license): agregar validación de hardware
fix(payment): corregir cálculo de impuestos
docs(api): actualizar documentación de endpoints
test(license): agregar pruebas unitarias para validación
refactor(tenant): simplificar lógica de multi-tenancy
```

### Pull Request Template
```markdown
## 📋 Descripción
Breve descripción de los cambios realizados.

## 🎯 Tipo de Cambio
- [ ] 🐛 Bug fix (cambio que corrige un issue)
- [ ] ✨ New feature (cambio que agrega funcionalidad)
- [ ] 💥 Breaking change (cambio que puede romper funcionalidad existente)
- [ ] 📚 Documentation update

## 🧪 Testing
- [ ] He agregado pruebas que prueban mi fix o feature
- [ ] Las pruebas nuevas y existentes pasan localmente
- [ ] He actualizado la documentación según sea necesario

## 📝 Checklist
- [ ] Mi código sigue los estándares de estilo del proyecto
- [ ] He realizado una auto-revisión de mi código
- [ ] He comentado mi código, particularmente en áreas difíciles de entender
- [ ] Mis cambios no generan nuevas advertencias
- [ ] He agregado pruebas que prueban que mi fix es efectivo o que mi feature funciona

## 📸 Screenshots (si aplica)
Agregar screenshots o GIFs para cambios en UI.
```

## 🛡️ Estándares de Seguridad

### Validación de Entrada
```csharp
// ✅ Validar siempre los parámetros de entrada
public async Task<License> CreateLicenseAsync(CreateLicenseRequest request)
{
    // Validación de parámetros
    if (request == null)
        throw new ArgumentNullException(nameof(request));
    
    if (string.IsNullOrWhiteSpace(request.ClientEmail))
        throw new ArgumentException("Client email is required", nameof(request.ClientEmail));
    
    if (!EmailValidator.IsValid(request.ClientEmail))
        throw new ArgumentException("Invalid email format", nameof(request.ClientEmail));
    
    // Validación de negocio
    var tenant = await _unitOfWork.Tenants.GetByIdAsync(request.TenantId);
    if (tenant == null)
        throw new InvalidOperationException("Tenant not found");
    
    // Continuar con la lógica...
}
```

### Logging Seguro
```csharp
// ✅ No loggear información sensible
_logger.LogInformation("License created for tenant {TenantId}, license ID: {LicenseId}", 
    license.TenantId, license.Id);

// ❌ Evitar loggear información sensible
// _logger.LogInformation("License created with API key: {ApiKey}", license.ApiKey);

// ✅ Usar structured logging
_logger.LogError("Payment processing failed for tenant {TenantId} with error: {ErrorMessage}", 
    payment.TenantId, ex.Message);
```

### Manejo de Errores
```csharp
// Global exception handler middleware
public class GlobalExceptionMiddleware
{
    private readonly RequestDelegate _next;
    private readonly ILogger<GlobalExceptionMiddleware> _logger;
    
    public async Task InvokeAsync(HttpContext context)
    {
        try
        {
            await _next(context);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "An unhandled exception occurred");
            await HandleExceptionAsync(context, ex);
        }
    }
    
    private static async Task HandleExceptionAsync(HttpContext context, Exception exception)
    {
        context.Response.StatusCode = exception switch
        {
            ArgumentException => 400,
            UnauthorizedAccessException => 401,
            ForbiddenException => 403,
            NotFoundException => 404,
            _ => 500
        };
        
        var response = new
        {
            Message = context.Response.StatusCode == 500 
                ? "An internal server error occurred" 
                : exception.Message,
            StatusCode = context.Response.StatusCode
        };
        
        await context.Response.WriteAsync(JsonSerializer.Serialize(response));
    }
}
```

## 📊 Monitoreo y Observabilidad

### Custom Metrics
```csharp
// Crear métricas personalizadas
public class ApplicationMetrics
{
    private readonly Counter<int> _licenseValidations;
    private readonly Histogram<double> _paymentProcessingTime;
    private readonly Gauge<int> _activeLicenses;
    
    public ApplicationMetrics(IMeterFactory meterFactory)
    {
        var meter = meterFactory.Create("SafeKeyLicensing");
        
        _licenseValidations = meter.CreateCounter<int>(
            "license_validations_total",
            "Total number of license validations");
            
        _paymentProcessingTime = meter.CreateHistogram<double>(
            "payment_processing_duration_seconds",
            "Time taken to process payments");
            
        _activeLicenses = meter.CreateGauge<int>(
            "active_licenses_count",
            "Current number of active licenses");
    }
    
    public void RecordLicenseValidation(string tenantId, bool isValid)
    {
        _licenseValidations.Add(1, new TagList
        {
            ["tenant_id"] = tenantId,
            ["is_valid"] = isValid.ToString()
        });
    }
    
    public void RecordPaymentProcessingTime(double duration, string paymentMethod)
    {
        _paymentProcessingTime.Record(duration, new TagList
        {
            ["payment_method"] = paymentMethod
        });
    }
    
    public void UpdateActiveLicensesCount(int count)
    {
        _activeLicenses.Record(count);
    }
}
```

### Structured Logging
```csharp
// Configuración de logging estructurado
builder.Logging.ClearProviders();
builder.Logging.AddConsole();
builder.Logging.AddOpenTelemetry(logging =>
{
    logging.IncludeFormattedMessage = true;
    logging.IncludeScopes = true;
});

// Uso en servicios
public class LicenseService
{
    private readonly ILogger<LicenseService> _logger;
    
    public async Task<License> CreateLicenseAsync(CreateLicenseRequest request)
    {
        using var scope = _logger.BeginScope("Creating license for tenant {TenantId}", request.TenantId);
        
        try
        {
            _logger.LogInformation("Starting license creation process");
            
            // Lógica de creación...
            
            _logger.LogInformation("License created successfully with ID {LicenseId}", license.Id);
            return license;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to create license for tenant {TenantId}", request.TenantId);
            throw;
        }
    }
}
```

## 🚀 Deployment y CI/CD

### GitHub Actions Workflow
```yaml
# .github/workflows/ci-cd.yml
name: CI/CD Pipeline

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main ]

jobs:
  test:
    runs-on: ubuntu-latest
    
    services:
      postgres:
        image: postgres:15
        env:
          POSTGRES_PASSWORD: postgres
          POSTGRES_DB: SafeKeyLicensing_Test
        options: >-
          --health-cmd pg_isready
          --health-interval 10s
          --health-timeout 5s
          --health-retries 5
    
    steps:
    - uses: actions/checkout@v3
    
    - name: Setup .NET
      uses: actions/setup-dotnet@v3
      with:
        dotnet-version: 8.0.x
    
    - name: Restore dependencies
      run: dotnet restore
    
    - name: Build
      run: dotnet build --no-restore
    
    - name: Test
      run: dotnet test --no-build --verbosity normal --collect:"XPlat Code Coverage"
    
    - name: Upload coverage to Codecov
      uses: codecov/codecov-action@v3

  deploy:
    needs: test
    runs-on: ubuntu-latest
    if: github.ref == 'refs/heads/main'
    
    steps:
    - uses: actions/checkout@v3
    
    - name: Build Docker image
      run: docker build -t safekeylicensing:${{ github.sha }} .
    
    - name: Deploy to staging
      run: |
        # Script de deployment
        echo "Deploying to staging environment"
```

---

**Última actualización**: Octubre 2025  
**Versión**: 1.0  
**Mantenido por**: Equipo de Desarrollo SafeKeyLicensing