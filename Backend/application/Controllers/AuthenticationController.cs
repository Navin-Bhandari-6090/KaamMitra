using application.Data;
using application.Models;
using application.Models.DTOModels;
using application.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.RateLimiting;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Security.Cryptography;
using System.Security.Cryptography.Xml;
using System.Text;

namespace application.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class AuthenticationController : ControllerBase
    {

        private readonly DatabaseController Database;
        private readonly TokenServices TokenServices;

        private readonly IConfiguration configuration;

        private static readonly string[] SelfSignupRoles = { "user", "provider" };

        private readonly ILogger<AuthenticationController> _logger;



        public AuthenticationController(DatabaseController Database, TokenServices TokenServices, IConfiguration configuration, ILogger<AuthenticationController> logger)

        {
            this.Database = Database;
            this.TokenServices = TokenServices;
            this.configuration = configuration;
             _logger = logger;
        }

        // Used so a missing user takes as long to reject as a wrong password
        private static readonly string DummyHash = BCrypt.Net.BCrypt.HashPassword("dummy-password", 12);

        // Hashes all new and changed passwords
        private static string HashPassword(string password) =>
            BCrypt.Net.BCrypt.HashPassword(password, 12);

        // Verifies a password against the stored BCrypt hash
        private bool VerifyPassword(UserInfo user, string plain)
        {
            var stored = user.Password;
            if (string.IsNullOrEmpty(stored))
                return false;

            try
            {
                return BCrypt.Net.BCrypt.Verify(plain, stored);
            }
            catch (BCrypt.Net.SaltParseException ex)
            {
                _logger.LogError(ex, "Malformed password hash for user {UserNumber}", user.UserNumber);
                return false;
            }
        }

        [HttpPost]
        [AllowAnonymous]
        [EnableRateLimiting("auth")]
        [Route("signin")]
        public async Task<IActionResult> SignUpUser([FromForm] UserInfoDTO obj)
        {
            try
            {
                if (!ModelState.IsValid)
                    return StatusCode(501, "The provided data is not in correct format.");

                if (string.IsNullOrWhiteSpace(obj.Password) || obj.Password.Length < 8 || obj.Password.Length > 72)
                    return StatusCode(501, "Password must be between 8 and 72 characters.");

                var email = (obj.Email ?? "").Trim().ToLower();

                if (string.IsNullOrEmpty(email))
                    return StatusCode(501, "The provided data is not in correct format.");

                // Emails listed in configuration become admin; everyone else picks from the whitelist
                var adminEmails = (configuration.GetSection("Seed:AdminEmails").Get<string[]>() ?? Array.Empty<string>())
                    .Select(e => e.Trim().ToLower());

                string role;

                if (adminEmails.Contains(email))
                {
                    role = "admin";
                }
                else
                {
                    var requestedRole = obj.Role?.Trim().ToLower();
                    if (requestedRole == null || !SelfSignupRoles.Contains(requestedRole))
                        return BadRequest("Invalid role.");
                    role = requestedRole;
                }

                var existingUser = await Database.UserInfos
                    .FirstOrDefaultAsync(x => x.Email.ToLower() == email);

                if (existingUser != null)
                    return StatusCode(502, "The provided user email is already registered.");

                var BlackListData=await Database.BlaclistUsers.Where(x=>x.Email==obj.Email || x.PhoneNumber==obj.PhoneNumber || x.WhatsappPhoneNumber==obj.WhatsappPhoneNumber).ToListAsync();

                if (BlackListData.Count>=1) 
                { 
                    return StatusCode(525, "You have been blocked by the system.");
                }
               
                var user = new UserInfo
                {
                    FirstName = obj.FirstName,
                    LastName = obj.LastName,
                    Email = email,
                    PhoneNumber = obj.PhoneNumber,
                    WhatsappPhoneNumber = obj.WhatsappPhoneNumber,
                    Address = obj.Address,
                    Password = HashPassword(obj.Password),
                    Latitude = obj.Latitude,
                    Longitude = obj.Longitude,
                    Photo = string.Empty,
                    Role = role,
                    LoginAccess = true,
                    Status=false
                };

                await Database.UserInfos.AddAsync(user);
                await Database.SaveChangesAsync();
                return Ok();
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Signup failed");
                return StatusCode(500, "Something went wrong. Please try again.");
            }
        }


        [HttpPost]
        [AllowAnonymous]
        [EnableRateLimiting("auth")]
        [Route("login")]
        public async Task<IActionResult> LoginUser([FromBody] LoginModel obj)
        {
            try
            {

                if (!ModelState.IsValid)
                    return StatusCode(502, "Provide correct format.");

                var email = (obj.Email ?? "").Trim().ToLower();

                var user = await Database.UserInfos.FirstOrDefaultAsync(x => x.Email.ToLower() == email);

                if (user == null)
                {
                    BCrypt.Net.BCrypt.Verify(obj.Password ?? "", DummyHash);   // keeps response time similar
                    return StatusCode(503, "Invalid email or password.");
                }

                if (!VerifyPassword(user, obj.Password ?? ""))
                    return StatusCode(503, "Invalid email or password.");

                if (!(bool)user.LoginAccess)
                    return StatusCode(504, "Your account is not authorized for login.");

                string token = TokenServices.GenerateTokenUser(user);
                return Ok(new
                {
                    token = token,
                    email = user.Email,
                    usertype = user.Role,
                    usernumber = user.UserNumber
                });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Login failed");
                return StatusCode(500, "Something went wrong. Please try again.");
            }
        }


        [HttpGet]
        [Route("jwtverify")]
        [Authorize]
        public async Task<ActionResult> VerifyToken()
        {
            try
            {
                return Ok();
            }
            catch (Exception ex)
            {
                return StatusCode(500);
            }

        }

        [HttpGet]
        [Route("jwtverifyprovider")]
        [Authorize(Policy = "RequireProviderRole")]
        public async Task<ActionResult> ProviderVerifyToken()
        {
            try
            {
                return Ok();
            }
            catch (Exception ex)
            {
                return StatusCode(500);
            }

        }

        [HttpGet]
        [Route("jwtverifyuser")]
        [Authorize(Policy = "RequireUserRole")]
        public async Task<ActionResult> UserVerifyToken()
        {
            try
            {
                return Ok();
            }
            catch (Exception ex)
            {
                return StatusCode(500);
            }

        }

        [HttpGet]
        [Route("jwtverifyadmin")]
        [Authorize(Policy = "RequireAdminRole")]
        public async Task<ActionResult> AdminVerifyToken()
        {
            try
            {
                return Ok();
            }
            catch (Exception ex)
            {
                return StatusCode(500);
            }

        }

        [HttpGet]
        [Route("userorproviderjwtverify")]
        [Authorize(Policy = "RequireProviderUserRole")]
        public async Task<ActionResult> UserOrProviderVerifyToken()
        {
            try
            {
                return Ok();
            }
            catch (Exception ex)
            {
                return StatusCode(500);
            }

        }

        [HttpGet]
        [Route("alluserjwtverify")]
        [Authorize(Policy = "RequireforAllRole")]
        public async Task<ActionResult> AllUserVerifyToken()
        {
            try
            {
                return Ok();
            }
            catch (Exception ex)
            {
                return StatusCode(500);
            }

        }

      
       

        [HttpGet]
        [Route("gettoken")]
        public async Task<IActionResult> Provide_Token()
        {
            try
            {

                // Generate token
                string token = TokenServices.GenerateRandomToken();
                // Return response
                return Ok(new
                {
                    token = token
                });
            }
            catch (Exception ex)
            {
                return StatusCode(500, $"Exception caught in login action method.\n{ex.Message}"); // 500 Internal Server Error
            }
        }







    }
}
