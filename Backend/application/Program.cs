
using application.Data;
using application.Services;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.AspNetCore.Http.Features;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using System.Threading.RateLimiting;
using static System.Net.WebRequestMethods;

//var corsUrl =
//    "https://navinbhandari2002.github.io/";



var corsUrl = new[]
{
    "https://navinbhandari2002.github.io",
    "http://localhost:64045",
     "http://localhost:64046"
};

var builder = WebApplication.CreateBuilder(args);



builder.Services.AddCors(options =>
{
    options.AddPolicy("AllowFlutterFrontend", policy =>
    {
        policy.WithOrigins(corsUrl)
            .AllowAnyHeader()
            .AllowAnyMethod()
            .AllowCredentials();
    });
});


builder.WebHost.ConfigureKestrel(options =>
{
    options.Limits.MaxRequestBodySize = 629_145_600; // 600 MB
});

builder.Services.Configure<FormOptions>(options =>
{
    options.MultipartBodyLengthLimit = 629_145_600; // 600 MB
    options.ValueLengthLimit = int.MaxValue;
    options.MultipartHeadersLengthLimit = int.MaxValue;
});

// Add services to the container.

builder.Services.AddControllers();
// Learn more about configuring Swagger/OpenAPI at https://aka.ms/aspnetcore/swashbuckle
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();


// Configure PostgreSQL database
builder.Services.AddDbContext<DatabaseController>(options =>
    options.UseNpgsql(builder.Configuration.GetConnectionString("monster")));

// Get JWT settings from configuration
var jwtSettings = builder.Configuration.GetSection("JwtSettings");
var base64Key = jwtSettings["Secret"];
var keyBytes = Convert.FromBase64String(base64Key ?? "JWT secret not configured.");

// JWT Authentication
builder.Services.AddAuthentication(options =>
{
    options.DefaultAuthenticateScheme = JwtBearerDefaults.AuthenticationScheme;
    options.DefaultChallengeScheme = JwtBearerDefaults.AuthenticationScheme;
})
.AddJwtBearer(options =>
{
    options.RequireHttpsMetadata = false;
    options.SaveToken = true;


options.TokenValidationParameters = new TokenValidationParameters
{
    ValidateIssuerSigningKey = true,
    IssuerSigningKey = new SymmetricSecurityKey(keyBytes),

    ValidateIssuer = true,
    ValidIssuer = jwtSettings["Issuer"],

    ValidateAudience = true,
    ValidAudience = jwtSettings["Audience"],

    ValidateLifetime = true
};

    // Allow SignalR WebSocket connections to authenticate using access_token.
    options.Events = new JwtBearerEvents
    {
        OnMessageReceived = context =>
        {
            var AccessToken = context.Request.Query["access_token"];
            var RequestPath = context.HttpContext.Request.Path;

            if (!string.IsNullOrEmpty(AccessToken) &&
                RequestPath.StartsWithSegments("/chatHub"))
            {
                context.Token = AccessToken;
            }

            return Task.CompletedTask;
        }
    };


});


// Authorization Policies
builder.Services.AddAuthorization(options =>
{
    options.AddPolicy("RequireAdminRole", policy => policy.RequireRole("admin"));
    options.AddPolicy("RequireProviderRole", policy => policy.RequireRole("provider"));
    options.AddPolicy("RequireUserRole", policy => policy.RequireRole("user"));
    options.AddPolicy("RequireProviderUserRole", policy => policy.RequireRole("user","provider"));
    options.AddPolicy("RequireforAllRole", policy => policy.RequireRole("admin", "user","provider"));
    options.AddPolicy("RequireAdminProRole", policy => policy.RequireRole("admin","provider"));

});

// Register custom services
builder.Services.AddScoped<TokenServices>();

builder.Services.AddRateLimiter(o =>
{
    o.RejectionStatusCode = 550;

    o.AddPolicy("auth", ctx => RateLimitPartition.GetFixedWindowLimiter(
        ctx.Connection.RemoteIpAddress?.ToString() ?? "unknown",
        _ => new FixedWindowRateLimiterOptions
        {
            PermitLimit = 5,
            Window = TimeSpan.FromMinutes(1),
            QueueLimit = 0,
            AutoReplenishment = true
        }));
});

builder.Services.AddSignalR();

var app = builder.Build();

// Configure the HTTP request pipeline.
//if (app.Environment.IsDevelopment())
//{
//    app.UseSwagger();
//    app.UseSwaggerUI();
//}


//app.UseSwagger();
//app.UseSwaggerUI();

app.UseSwagger();

app.UseSwaggerUI(c =>
{
    c.SwaggerEndpoint("/swagger/v1/swagger.json", "KaamMitra API V1");
    c.RoutePrefix = string.Empty;
});

using var serviceScope = app.Services.CreateScope();

var dbContext = serviceScope.ServiceProvider
    .GetRequiredService<DatabaseController>();

dbContext.Database.Migrate();


//app.UseHttpsRedirection();

app.UseStaticFiles();

app.UseRouting();

app.UseCors("AllowFlutterFrontend");

app.UseRateLimiter();

app.UseAuthentication();

app.UseAuthorization();

app.MapControllers();

app.MapHub<ChatHub>("/chatHub");

app.Run();
