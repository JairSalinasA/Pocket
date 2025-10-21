# =============================================
# GUÍA RÁPIDA DE CONFIGURACIÓN POSTGRESQL
# SafeKeyLicensing - Con tus credenciales específicas
# =============================================

# Credenciales de tu PostgreSQL:
# Host: localhost
# Port: 5432
# Database: SafeKeyLicensing  
# Username: postgres
# Password: admin

# =============================================
# PASO 1: VERIFICAR CONEXIÓN
# =============================================

# IMPORTANTE: En Windows, psql no está en el PATH por defecto
# Usar la ruta completa encontrada: C:\Program Files\PostgreSQL\16\bin\psql.exe

# Comando para conectar a PostgreSQL (ejecutar en PowerShell):
& "C:\Program Files\PostgreSQL\16\bin\psql.exe" -h localhost -p 5432 -U postgres -d postgres

# O crear un alias para facilitar el uso:
Set-Alias -Name psql -Value "C:\Program Files\PostgreSQL\16\bin\psql.exe"

# Después del alias, usar simplemente:
psql -h localhost -p 5432 -U postgres -d postgres

# Si funciona, verás algo como:
# postgres=#

# =============================================
# PASO 2: CREAR BASE DE DATOS (si no existe)
# =============================================

# Dentro del prompt de PostgreSQL, ejecutar:
CREATE DATABASE "SafeKeyLicensing" 
WITH 
OWNER = postgres
ENCODING = 'UTF8'
LC_COLLATE = 'en_US.UTF-8'
LC_CTYPE = 'en_US.UTF-8';

# Verificar que se creó:
\l

# Conectar a la nueva base de datos:
\c SafeKeyLicensing

# =============================================
# PASO 3: HABILITAR EXTENSIONES NECESARIAS
# =============================================

# Ejecutar dentro de la base de datos SafeKeyLicensing:
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "hstore";  
CREATE EXTENSION IF NOT EXISTS "pg_trgm";
CREATE EXTENSION IF NOT EXISTS "btree_gin";

# Verificar extensiones instaladas:
\dx

# Salir de PostgreSQL:
\q

# =============================================
# PASO 4: PROBAR CONEXIÓN DESDE .NET
# =============================================

# Desde el directorio del proyecto, ejecutar:
cd SafeKeyLicensingSol
dotnet restore
dotnet build

# Si hay errores de conexión, verificar:
# 1. PostgreSQL esté ejecutándose
# 2. Puerto 5432 esté abierto
# 3. Usuario postgres tenga permisos

# =============================================
# PASO 5: CREAR Y APLICAR MIGRACIONES
# =============================================

# Instalar herramientas EF si no están instaladas:
dotnet tool install --global dotnet-ef

# Verificar instalación:
dotnet ef --version

# Crear migración inicial:
dotnet ef migrations add InitialCreate --project SafeKeyLicensing

# Aplicar migraciones a la base de datos:
dotnet ef database update --project SafeKeyLicensing

# =============================================
# COMANDOS DE TROUBLESHOOTING
# =============================================

# Si PostgreSQL no está ejecutándose:
# Windows: Iniciar servicio desde Services.msc
# O desde PowerShell como administrador:
# Start-Service postgresql-x64-15

# Verificar que PostgreSQL escucha en puerto 5432:
netstat -an | findstr 5432

# Probar conexión básica:
psql -h localhost -p 5432 -U postgres -c "SELECT version();"

# Ver bases de datos existentes:
psql -h localhost -p 5432 -U postgres -c "\l"

# =============================================
# COMANDOS ÚTILES DE POSTGRESQL
# =============================================

# Conectar a base de datos específica:
psql -h localhost -p 5432 -U postgres -d SafeKeyLicensing

# Ver tablas en la base de datos actual:
\dt

# Ver esquema de una tabla:
\d nombre_tabla

# Ejecutar script SQL desde archivo:
psql -h localhost -p 5432 -U postgres -d SafeKeyLicensing -f script.sql

# Ver conexiones activas:
psql -h localhost -p 5432 -U postgres -c "SELECT * FROM pg_stat_activity;"

# =============================================
# PRÓXIMOS PASOS DESPUÉS DE CONFIGURAR BD
# =============================================

# 1. Ejecutar la aplicación:
dotnet run --project SafeKeyLicensing

# 2. Verificar que la aplicación inicia sin errores

# 3. Probar endpoint de salud:
# http://localhost:5000/health

# 4. Revisar logs para verificar conexión a BD exitosa

# =============================================
# PROBLEMAS COMUNES Y SOLUCIONES
# =============================================

# Error: "password authentication failed"
# Solución: Verificar password "admin" es correcto

# Error: "could not connect to server"  
# Solución: Verificar que PostgreSQL está ejecutándose

# Error: "database does not exist"
# Solución: Ejecutar comando CREATE DATABASE arriba

# Error: "permission denied"
# Solución: Verificar que usuario postgres tiene permisos

# Error en migraciones EF:
# Solución: Verificar connection string en appsettings.json

# =============================================
# INFORMACIÓN ADICIONAL
# =============================================

# Connection String que se está usando:
# Host=localhost;Port=5432;Database=SafeKeyLicensing;Username=postgres;Password=admin;Include Error Detail=true;

# Esta configuración está en:
# - appsettings.json
# - appsettings.Development.json

# Para cambiar credenciales en el futuro, actualizar estos archivos.

echo "Configuración completada. Ejecutar comandos paso a paso."