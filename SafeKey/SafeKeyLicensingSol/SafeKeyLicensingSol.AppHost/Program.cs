var builder = DistributedApplication.CreateBuilder(args);

builder.AddProject<Projects.SafeKeyLicensing>("safekeylicensing");

builder.Build().Run();
