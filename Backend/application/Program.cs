
using application.Data;
using application.Services;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.AspNetCore.Http.Features;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using System.Threading.RateLimiting;

var builder = WebApplication.CreateBuilder(args);

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
    options.UseNpgsql(builder.Configuration.GetConnectionString("key")));

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
    o.RejectionStatusCode = 429;
    o.AddPolicy("auth", ctx => RateLimitPartition.GetFixedWindowLimiter(
        ctx.Connection.RemoteIpAddress?.ToString() ?? "unknown",
        _ => new FixedWindowRateLimiterOptions { PermitLimit = 5, Window = TimeSpan.FromMinutes(1) }));
});

builder.Services.AddSignalR();

var app = builder.Build();

// Configure the HTTP request pipeline.
if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

app.UseHttpsRedirection();
app.UseStaticFiles();
app.UseRateLimiter();
app.UseAuthentication();     
app.UseAuthorization();
app.MapControllers();

app.MapHub<ChatHub>("/chatHub");

app.Run();
