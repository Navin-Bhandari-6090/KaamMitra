using application.Data;
using application.Models;
using application.Models.DTOModels;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using System.Security.Claims;

namespace application.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class HomeController : ControllerBase
    {

        public DatabaseController Database { get; set; }
 


        public HomeController(DatabaseController Database, IWebHostEnvironment Environment)
        {
            this.Database = Database;
        

        }



        [HttpGet("getfooterinfo")]
        [Authorize]
        public async Task<IActionResult> GetFooterInfo()
        {
            try
            {
                var userNumberClaim =
User.FindFirst(ClaimTypes.NameIdentifier)?.Value;

                if (!int.TryParse(userNumberClaim, out int currentUserNumber))
                {
                    return Forbid();
                }


                var user = await Database.UserInfos
                    .FirstOrDefaultAsync(x => x.UserNumber == currentUserNumber);

                if (user == null)
                {

                    return StatusCode(502, "User not found");
                }


                if (user.LoginAccess == false)
                {
                    return StatusCode(506, "You have been blocked by System.Contact to KaamMitra community.");
                }

                var footerInfo = await Database.FooterInfos
                    .AsNoTracking()
                    .FirstOrDefaultAsync();

                if (footerInfo == null)
                {
                    return StatusCode(404, new
                    {
                        message = "Footer information not found."
                    });
                }

                return StatusCode(200, footerInfo);
            }
            catch (Exception ex)
            {
                return StatusCode(500, new
                {
                    message = "Something went wrong while getting footer information.",
                    error = ex.Message
                });
            }
        }


        [Authorize(Policy = "RequireProviderUserRole")]
        [HttpGet]
        [Route("getalladvertisementinfos")]
        public async Task<IActionResult> GetAllAdvertisementInfos()
        {
            try
            {


                // Check ModelState
                if (!ModelState.IsValid)
                {
                    return StatusCode(400, "Data are not in correct format.");
                }


                var userNumberClaim =
         User.FindFirst(ClaimTypes.NameIdentifier)?.Value;

                if (!int.TryParse(userNumberClaim, out int userNumber))
                    return Forbid();

                var user = await Database.UserInfos
                    .FirstOrDefaultAsync(x => x.UserNumber == userNumber);

                if (user == null)
                {

                    return StatusCode(404, "User not found");
                }


                if (user.LoginAccess == false)
                {
                    return StatusCode(506, "You have been blocked by System.Contact to KaamMitra community.");
                }

                // Get all AdvertisementInfos
                var advertisementList = await Database.AdvertisementInfos.OrderBy(x => x.UploadedAt)
                    .ToListAsync();

                // Check data
                if (advertisementList == null || advertisementList.Count == 0)
                {
                    return StatusCode(404, "No advertisement information is present.");
                }

                // Return all advertisement data
                return Ok(advertisementList);
            }
            catch (Exception ex)
            {
                return StatusCode(
                    500,
                    $"An error occurred while getting advertisement information: {ex.Message}"
                );
            }
        }




    }
}
