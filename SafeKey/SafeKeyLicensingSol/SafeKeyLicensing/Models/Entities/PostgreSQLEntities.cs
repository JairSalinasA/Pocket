using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace SafeKeyLicensing.Models.Entities;

/// <summary>
/// Entidad de solicitud de licencia
/// </summary>
public class Solicitud
{
    public int Id { get; set; }
    
    [Required]
    [StringLength(100)]
    public string SolicitudId { get; set; } = null!;
    
    public int TenantId { get; set; }
    
    [Required]
    public string UsuarioId { get; set; } = null!;
    
    public int TipoLicenciaId { get; set; }
    
    [StringLength(50)]
    public string Status { get; set; } = "Pendiente";
    
    public DateTime FechaCreacion { get; set; } = DateTime.UtcNow;
    public DateTime FechaActualizacion { get; set; } = DateTime.UtcNow;
    
    // Relaciones
    public virtual Tenant Tenant { get; set; } = null!;
    public virtual TipoLicencia TipoLicencia { get; set; } = null!;
    public virtual ICollection<LicenciaActiva> LicenciasActivas { get; set; } = new List<LicenciaActiva>();
}

/// <summary>
/// Entidad de tipo de licencia
/// </summary>
public class TipoLicencia
{
    public int Id { get; set; }
    
    [Required]
    [StringLength(100)]
    public string Nombre { get; set; } = null!;
    
    public string? Descripcion { get; set; }
    
    [Column(TypeName = "decimal(10,2)")]
    public decimal Precio { get; set; }
    
    public int DuracionDias { get; set; }
    
    public bool Activo { get; set; } = true;
    
    public int TenantId { get; set; }
    
    public DateTime FechaCreacion { get; set; } = DateTime.UtcNow;
    
    // Relaciones
    public virtual Tenant Tenant { get; set; } = null!;
    public virtual ICollection<Solicitud> Solicitudes { get; set; } = new List<Solicitud>();
    public virtual ICollection<LicenciaActiva> LicenciasActivas { get; set; } = new List<LicenciaActiva>();
}

/// <summary>
/// Entidad de software
/// </summary>
public class Software
{
    public int Id { get; set; }
    
    [Required]
    [StringLength(100)]
    public string Nombre { get; set; } = null!;
    
    public string? Descripcion { get; set; }
    
    [StringLength(50)]
    public string Version { get; set; } = "1.0.0";
    
    public bool Activo { get; set; } = true;
    
    public int TenantId { get; set; }
    
    public DateTime FechaCreacion { get; set; } = DateTime.UtcNow;
    
    // Relaciones
    public virtual Tenant Tenant { get; set; } = null!;
}

/// <summary>
/// Entidad de heartbeat
/// </summary>
public class Heartbeat
{
    public int Id { get; set; }
    
    public int LicenciaActivaId { get; set; }
    
    public DateTime Fecha { get; set; } = DateTime.UtcNow;
    
    [StringLength(45)]
    public string? IPAddress { get; set; }
    
    [Column(TypeName = "jsonb")]
    public Dictionary<string, object>? SystemInfo { get; set; }
    
    // Relaciones
    public virtual LicenciaActiva LicenciaActiva { get; set; } = null!;
}

/// <summary>
/// Entidad de pago que demuestra el uso de JSONB en PostgreSQL
/// </summary>
public class Pago
{
    public int Id { get; set; }
    
    [Required]
    [StringLength(100)]
    public string PagoId { get; set; } = null!;
    
    public int TenantId { get; set; }
    
    [Required]
    public string UsuarioId { get; set; } = null!;
    
    [Column(TypeName = "decimal(10,2)")]
    public decimal Monto { get; set; }
    
    [StringLength(3)]
    public string Moneda { get; set; } = "USD";
    
    [Required]
    [StringLength(500)]
    public string Concepto { get; set; } = null!;
    
    [Required]
    [StringLength(50)]
    public string MetodoPago { get; set; } = null!;
    
    [StringLength(200)]
    public string? ReferenciaExterna { get; set; }
    
    [StringLength(50)]
    public string Status { get; set; } = "Pendiente";
    
    public DateTime? FechaPago { get; set; }
    public DateTime? FechaExpiracion { get; set; }
    
    // ===== Campos JSONB para datos flexibles =====
    
    /// <summary>
    /// Datos de la transacción almacenados como JSONB
    /// Permite almacenar información variable según el proveedor de pago
    /// </summary>
    [Column(TypeName = "jsonb")]
    public PaymentTransactionData? DatosTransaccion { get; set; }
    
    /// <summary>
    /// Metadatos adicionales almacenados como JSONB
    /// </summary>
    [Column(TypeName = "jsonb")]
    public Dictionary<string, object>? Metadata { get; set; }
    
    [Column(TypeName = "text")]
    public string? Error { get; set; }
    
    public DateTime FechaCreacion { get; set; } = DateTime.UtcNow;
    public DateTime FechaActualizacion { get; set; } = DateTime.UtcNow;
    
    // Relaciones
    public virtual Tenant Tenant { get; set; } = null!;
}

/// <summary>
/// Clase para datos de transacción que se serializa a JSONB
/// </summary>
public class PaymentTransactionData
{
    public string Method { get; set; } = null!;
    public string Provider { get; set; } = null!;
    public CustomerData? CustomerData { get; set; }
    public BillingAddress? BillingAddress { get; set; }
    public List<PaymentItem>? Items { get; set; }
    public Dictionary<string, object>? ProviderSpecificData { get; set; }
}

public class CustomerData
{
    public string Name { get; set; } = null!;
    public string Email { get; set; } = null!;
    public string? Phone { get; set; }
    public string? Company { get; set; }
    public Dictionary<string, string>? CustomFields { get; set; }
}

public class BillingAddress
{
    public string Street { get; set; } = null!;
    public string City { get; set; } = null!;
    public string State { get; set; } = null!;
    public string PostalCode { get; set; } = null!;
    public string Country { get; set; } = null!;
}

public class PaymentItem
{
    public string Name { get; set; } = null!;
    public decimal Price { get; set; }
    public int Quantity { get; set; }
    public string? Description { get; set; }
}

/// <summary>
/// Entidad de licencia con capacidades de array PostgreSQL
/// </summary>
public class LicenciaActiva
{
    public int Id { get; set; }
    
    [Required]
    [StringLength(50)]
    public string LicenciaId { get; set; } = null!;
    
    public int SolicitudId { get; set; }
    
    [Required]
    [StringLength(100)]
    public string ApiKey { get; set; } = null!;
    
    [Required]
    [StringLength(500)]
    public string HardwareInfo { get; set; } = null!;
    
    public int TipoLicenciaId { get; set; }
    public int TenantId { get; set; }
    
    public DateTime FechaInicio { get; set; } = DateTime.UtcNow;
    public DateTime FechaVencimiento { get; set; }
    
    [StringLength(50)]
    public string Status { get; set; } = "ACTIVA";
    
    public DateTime? UltimoHeartbeat { get; set; }
    public int IntentosHeartbeatFallidos { get; set; } = 0;
    
    // ===== Arrays PostgreSQL =====
    
    /// <summary>
    /// Lista de IPs permitidas almacenada como array PostgreSQL
    /// </summary>
    [Column(TypeName = "text[]")]
    public string[]? AllowedIPs { get; set; }
    
    /// <summary>
    /// Características habilitadas almacenadas como array
    /// </summary>
    [Column(TypeName = "text[]")]
    public string[]? Features { get; set; }
    
    // ===== Campos JSONB =====
    
    /// <summary>
    /// Configuración de la licencia en formato JSONB
    /// </summary>
    [Column(TypeName = "jsonb")]
    public LicenseConfiguration? Configuration { get; set; }
    
    /// <summary>
    /// Información detallada del hardware en JSONB
    /// </summary>
    [Column(TypeName = "jsonb")]
    public HardwareDetails? HardwareDetails { get; set; }
    
    public DateTime FechaCreacion { get; set; } = DateTime.UtcNow;
    
    // Relaciones
    public virtual Solicitud Solicitud { get; set; } = null!;
    public virtual TipoLicencia TipoLicencia { get; set; } = null!;
    public virtual Tenant Tenant { get; set; } = null!;
    public virtual ICollection<Heartbeat> Heartbeats { get; set; } = new List<Heartbeat>();
}

public class LicenseConfiguration
{
    public int MaxUsers { get; set; } = 1;
    public int MaxInstallations { get; set; } = 1;
    public bool AllowOfflineUse { get; set; } = false;
    public int OfflineDaysLimit { get; set; } = 7;
    public Dictionary<string, bool>? FeatureFlags { get; set; }
    public Dictionary<string, object>? CustomSettings { get; set; }
}

public class HardwareDetails
{
    public string? HDDId { get; set; }
    public string? MotherboardId { get; set; }
    public string? CPUId { get; set; }
    public string? MACAddress { get; set; }
    public string? OSVersion { get; set; }
    public string? Architecture { get; set; }
    public long? TotalRAM { get; set; }
    public Dictionary<string, object>? AdditionalInfo { get; set; }
}

/// <summary>
/// Entidad de tenant con configuración flexible en JSONB
/// </summary>
public class Tenant
{
    public int Id { get; set; }
    
    [Required]
    [StringLength(200)]
    public string Nombre { get; set; } = null!;
    
    [Required]
    [StringLength(100)]
    public string TenantId { get; set; } = null!;
    
    public string? Descripcion { get; set; }
    
    [StringLength(256)]
    public string? ContactEmail { get; set; }
    
    [StringLength(500)]
    public string? Website { get; set; }
    
    [StringLength(500)]
    public string? LogoUrl { get; set; }
    
    // Límites
    public int MaxLicencias { get; set; } = 100;
    public int MaxUsuarios { get; set; } = 10;
    public int MaxSoftwares { get; set; } = 5;
    
    [StringLength(50)]
    public string Plan { get; set; } = "Free";
    
    public bool Activo { get; set; } = true;
    
    // Información de pagos
    [StringLength(100)]
    public string? StripeCustomerId { get; set; }
    
    [StringLength(256)]
    public string? PaypalEmail { get; set; }
    
    // ===== Configuración flexible en JSONB =====
    
    /// <summary>
    /// Configuraciones personalizables del tenant
    /// </summary>
    [Column(TypeName = "jsonb")]
    public TenantSettings? Settings { get; set; }
    
    /// <summary>
    /// Configuración de branding
    /// </summary>
    [Column(TypeName = "jsonb")]
    public BrandingConfiguration? Branding { get; set; }
    
    /// <summary>
    /// Configuración de notificaciones
    /// </summary>
    [Column(TypeName = "jsonb")]
    public NotificationSettings? NotificationSettings { get; set; }
    
    public DateTime FechaCreacion { get; set; } = DateTime.UtcNow;
    public DateTime? FechaExpiracion { get; set; }
    public DateTime FechaActualizacion { get; set; } = DateTime.UtcNow;
    
    // Relaciones
    public virtual ICollection<Software> Software { get; set; } = new List<Software>();
    public virtual ICollection<TipoLicencia> TiposLicencia { get; set; } = new List<TipoLicencia>();
    public virtual ICollection<Solicitud> Solicitudes { get; set; } = new List<Solicitud>();
    public virtual ICollection<LicenciaActiva> LicenciasActivas { get; set; } = new List<LicenciaActiva>();
    public virtual ICollection<Pago> Pagos { get; set; } = new List<Pago>();
}

public class TenantSettings
{
    public string? TimeZone { get; set; }
    public string? Language { get; set; } = "es";
    public string? Currency { get; set; } = "USD";
    public bool EnableAutoRenewal { get; set; } = true;
    public int HeartbeatIntervalMinutes { get; set; } = 30;
    public int LicenseExpirationWarningDays { get; set; } = 7;
    public Dictionary<string, object>? CustomSettings { get; set; }
}

public class BrandingConfiguration
{
    public string? PrimaryColor { get; set; }
    public string? SecondaryColor { get; set; }
    public string? LogoUrl { get; set; }
    public string? FaviconUrl { get; set; }
    public string? CompanyName { get; set; }
    public Dictionary<string, string>? CustomCss { get; set; }
}

public class NotificationSettings
{
    public bool EmailNotifications { get; set; } = true;
    public bool SmsNotifications { get; set; } = false;
    public bool WebhookNotifications { get; set; } = false;
    public string? WebhookUrl { get; set; }
    public List<string>? NotificationEmails { get; set; }
    public Dictionary<string, bool>? EventSubscriptions { get; set; }
}

/// <summary>
/// Entidad de logs con búsqueda full-text
/// </summary>
public class Log
{
    public int Id { get; set; }
    public DateTime Fecha { get; set; } = DateTime.UtcNow;
    
    [Required]
    [StringLength(50)]
    public string Nivel { get; set; } = null!;
    
    [Required]
    [StringLength(1000)]
    public string Mensaje { get; set; } = null!;
    
    public string? Detalles { get; set; }
    
    [StringLength(45)]
    public string? IPAddress { get; set; }
    
    [StringLength(500)]
    public string? UserAgent { get; set; }
    
    public string? UsuarioId { get; set; }
    public int TenantId { get; set; }
    
    // ===== Campo calculado para búsqueda full-text =====
    
    /// <summary>
    /// Vector de búsqueda generado automáticamente
    /// </summary>
    [Column(TypeName = "tsvector")]
    public string? SearchVector { get; set; }
    
    // ===== Metadatos adicionales en JSONB =====
    
    [Column(TypeName = "jsonb")]
    public Dictionary<string, object>? Metadata { get; set; }
    
    // Relaciones
    public virtual Tenant Tenant { get; set; } = null!;
}