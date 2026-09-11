using application.Data;
using application.Models.DTOModels;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace application.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class ServiceController : ControllerBase
    {

        public DatabaseController Database { get; set; }

        public ServiceController(DatabaseController database)
        {
            this.Database = database;
        }

        [Authorize(Policy = "RequireProviderUserRole")]
        [HttpPost]
        [Route("getratinginfo")]
        public async Task<IActionResult> GetRatingInfo([FromBody] UserEmailInfoModel obj)
        {

            try
            {
                var user_data = await Database.UserInfos.FirstOrDefaultAsync(x => x.Email == obj.Email);
                if (user_data != null)
                {
                    var rating_data = await Database.RatingInfos
                        .GroupBy(x => x.RatingReceiver)
                        .Select(g => new
                        {
                            UserEmail = g.Key,
                            AverageRating = Math.Round(g.Average(x => x.RatingValue), 2)
                        })
                        .ToListAsync();

                    return Ok(rating_data);
                }
                else
                {
                    return StatusCode(500, "No user found.");
                }
            }
            catch (Exception ex)
            {
                return StatusCode(501, ex.Message);
            }
        }

        [Authorize(Policy = "RequireProviderUserRole")]
        [HttpPost]
        [Route("getuserinfo")]
        public async Task<IActionResult> GetUserInfo([FromBody] UserEmailInfoModel obj)
        {

            try
            {
                // 1. Validate whether the email exists
                var emailUser = await Database.UserInfos
                    .FirstOrDefaultAsync(x => x.Email == obj.Email);

                if (emailUser == null)
                {
                    return StatusCode(404, "Invalid email.");
                }


                // 2. Email is valid, so get ALL users
                var allUsers = await Database.UserInfos
                    .Select(x => new SendUserInfoServiceDTO
                    {
                        UserNumber = x.UserNumber,
                        FirstName = x.FirstName,
                        LastName = x.LastName,
                        Email = x.Email,
                        PhoneNumber = x.PhoneNumber,
                        WhatsappPhoneNumber = x.WhatsappPhoneNumber,
                        Latitude = x.Latitude,
                        Longitude = x.Longitude,
                        Photo = x.Photo
                    })
                    .ToListAsync();


                // 3. Return all users
                return Ok(allUsers);

            }
            catch (Exception ex)
            {
                return StatusCode(501, ex.Message);
            }
        }

        [Authorize(Policy = "RequireProviderUserRole")]
        [HttpPost]
        [Route("getserviceinfo")]
        public async Task<IActionResult> GetServiceInfo([FromBody] UserEmailInfoModel obj)
        {

            try
            {
                // 1. Validate whether the email exists
                var emailUser = await Database.UserInfos
                    .FirstOrDefaultAsync(x => x.Email == obj.Email);

                if (emailUser == null)
                {
                    return StatusCode(404, "Invalid email.");
                }

               var ServiceInfo = await Database.ProviderServiceInfo.ToListAsync();
                // 3. Return all users
                return Ok(ServiceInfo);

            }
            catch (Exception ex)
            {
                return StatusCode(501, ex.Message);
            }
        }


    }
}
