using application.Data;
using application.Models;
using application.Models.DTOModels;
using application.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
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

        public DatabaseController Database { get; set; }
        public TokenServices TokenServices { get; set; }

        private readonly IConfiguration configuration;

        public AuthenticationController(DatabaseController Database, TokenServices TokenServices, IConfiguration configuration)

        {
            this.Database = Database;
            this.TokenServices = TokenServices;
            this.configuration = configuration;
        }

        private string HashPassword(string password)
        {
            using (var sha256 = SHA256.Create())
            {
                // Compute hash for the password
                var hashedBytes = sha256.ComputeHash(Encoding.UTF8.GetBytes(password));
                // Convert the byte array to a hexadecimal string
                if (hashedBytes != null)
                {
                    return BitConverter.ToString(hashedBytes).Replace("-", "").ToLower();
                }
                else
                {
                    return "";
                }

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


        [HttpPost]
        [Route("signin")]
        [Authorize]
        public async Task<IActionResult> SignUpUser([FromForm] UserInfoDTO obj)
        {
            try
            {
                // 1. Validate model
                if (!ModelState.IsValid)
                {
                    return StatusCode(
                        501,
                        "The provided data is not in correct format."
                    );
                }

                // 2. Check whether email already exists
                var existingUser = await Database.UserInfos
                    .FirstOrDefaultAsync(x => x.Email == obj.Email);

                if (existingUser != null)
                {
                    return StatusCode(
                        502,
                        "The provided user email is already registered."
                    );
                }

                // 3. Create user
                // Photo is intentionally empty during signup.
                var user = new UserInfo
                {
                    FirstName = obj.FirstName,
                    LastName = obj.LastName,
                    Email = obj.Email,
                    PhoneNumber = obj.PhoneNumber,
                    WhatsappPhoneNumber = obj.WhatsappPhoneNumber,
                    Address = obj.Address,

                    Password = HashPassword(obj.Password),

                    Latitude = obj.Latitude,
                    Longitude = obj.Longitude,

                    Photo = string.Empty,

                    Role = obj.Role,
                    LoginAccess = true
                };

                // 4. Save user
                await Database.UserInfos.AddAsync(user);
                await Database.SaveChangesAsync();

                // 5. Return success
                return Ok();
            }
            catch (Exception ex)
            {
                return StatusCode(500, ex.Message);
            }
        }


        [HttpPost]
        [Authorize]
        [Route("login")]
        public async Task<IActionResult> LoginUser([FromBody] LoginModel obj)
        {
            try
            {
                if (ModelState.IsValid)
                {
                    // Check if the user exists
                    var user_data = await Database.UserInfos.FirstOrDefaultAsync(x => x.Email == obj.Email);

                    if (user_data != null)
                    {
                        if (!user_data.LoginAccess)
                        {
                            return StatusCode(504, "Your account is not authorized for login.");
                        }

                        // Validate password (assuming you store hashed passwords)
                        if (user_data.Password == HashPassword(obj.Password))
                        {
                            // Generate token
                            string token = TokenServices.GenerateTokenUser(user_data);
                            // Return response
                            return Ok(new
                            {
                                token = token,
                                email = user_data.Email,
                                usertype = user_data.Role
                            });
                        }
                        else
                        {
                            return StatusCode(503, "Invalid password.");
                        }
                    }
                    else
                    {
                        return StatusCode(501, "No user with the provided email found.");
                    }
                }
                else
                {
                    return StatusCode(502, "Provide correct format.");
                }
            }
            catch (Exception ex)
            {
                return StatusCode(500, $"Exception caught in login action method.\n{ex.Message}"); // 500 Internal Server Error
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
