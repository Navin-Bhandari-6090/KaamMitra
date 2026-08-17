using application.Data;
using application.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using System.Security.Cryptography;
using System.Text;

namespace application.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class AuthenticationController : ControllerBase
    {

        public DatabaseController Database { get; set; }
        public TokenServices TokenServices { get; set; }

        public AuthenticationController(DatabaseController Database, TokenServices TokenServices)

        {
            this.Database = Database;
            this.TokenServices = TokenServices;

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
        [Authorize(Policy = "RequireforAdminorMemberRole")]
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


}
}
