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

                    return StatusCode(500, "User not found");
                }


                if (user.LoginAccess == false)
                {
                    return StatusCode(506, "You have been blocked by System.Contact to KaamMitra community.");
                }

                if (!ModelState.IsValid)
                {
                    return StatusCode(502, "Invalid input data.");
                }

                    var rating_data = await Database.RatingInfos
                        .GroupBy(x => new
                        {
                            x.RatingReceiverNumber,
                            x.ServiceName
                        })
                        .Select(g => new
                        {
                            RatingReceiverNumber = g.Key.RatingReceiverNumber,
                            ServiceName = g.Key.ServiceName,

                            AverageRating = Math.Round(g.Average(x => x.RatingValue), 2)
                        })
                        .ToListAsync();

                    return Ok(rating_data);
            
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
                if (!ModelState.IsValid)
                {
                    return StatusCode(502, "Invalid input data.");
                }
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
                if (!ModelState.IsValid) { 
                    return StatusCode(502,"Invalid input data.");
                }
                // 1. Validate whether the email exists
                var emailUser = await Database.UserInfos
                    .FirstOrDefaultAsync(x => x.Email == obj.Email);

                if (emailUser == null)
                {
                    return StatusCode(404, "Invalid email.");
                }

                var ServiceInfo = await Database.ProviderServiceInfo
      .Select(x => new ProviderServicesResponseDTO
      {
          ProviderServiceId = x.ProviderServiceId,
          ServiceName = x.ServiceName,
          ServiceDocument = x.ServiceDocument,
          Email = x.Email,
          UserNumber = x.UserNumber
      })
      .ToListAsync();

                return StatusCode(200, ServiceInfo);

            }
            catch (Exception ex)
            {
                return StatusCode(501, ex.Message);
            }
        }




        [Authorize(Policy = "RequireUserRole")]
        [Route("addbookinginfo")]
        [HttpPost]
        public async Task<IActionResult> AddBookingInfo([FromBody] BookinInfoModel obj)
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


                // 1. Validate model
                if (!ModelState.IsValid)
                {
                    return StatusCode(
                        501,
                        "The provided data is not in correct format."
                    );
                }


                var Provider = await Database.UserInfos
              .FirstOrDefaultAsync(x => x.UserNumber == obj.ProviderNumber);
                if (Provider == null)
                {
                    return StatusCode(503, "Provider not found.");
                }

                var Data = new BookinInfoModel
                {
                    ServiceId = obj.ServiceId,
                    Distance = obj.Distance,
                    ServiceName = obj.ServiceName,
                    ProviderNumber = Provider.UserNumber,
                    ProviderApprovalStatus = obj.ProviderApprovalStatus,
                    ProviderTaskCompleteStatus = obj.ProviderTaskCompleteStatus,
                    UserTaskCompleteStatus = obj.UserTaskCompleteStatus,
                    UserNumber = currentUserNumber,
                    CreatedAt = DateTime.UtcNow,
                    UserApprovalStatus = obj.UserApprovalStatus,
                    UserBookingDescription = obj.UserBookingDescription,
                    RequiredAdvancePayment=false,
               
                };
                await Database.BookingInfos.AddAsync(Data);
                await Database.SaveChangesAsync();
                return Ok("Insert data success in booking info table");
            }
            catch (Exception ex)
            {
                return StatusCode(500, ex.Message);
            }
        }



        [Authorize(Policy = "RequireforAllRole")]
        [Route("addnotification")]
        [HttpPost]
        public async Task<IActionResult> AddNotification([FromBody] NotificationInfoModelDTO obj)
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


                // 1. Validate model
                if (!ModelState.IsValid)
                {
                    return StatusCode(
                        501,
                        "The provided data is not in correct format."
                    );
                }

                //var ExistingUser = await Database.UserInfos
                //    .FirstOrDefaultAsync(x => x.Email == obj.CurrentUserEmail);

                //if (ExistingUser == null)
                //{
                //    return StatusCode(502, "User not found.");
                //}

              //  var Provider = await Database.UserInfos
              //.FirstOrDefaultAsync(x => x.Email == obj.ReceiverEmail);
              //  if (Provider == null)
              //  {
              //      return StatusCode(503, "Provider not found.");
              //  }

                var Data = new NotificationInfoModel
                {
                    ReceiverNumber=obj.ReceiverNumber,
                    Message= obj.Message,
                    Date = DateTime.UtcNow,
                };
                await Database.NotificationInfos.AddAsync(Data);
                await Database.SaveChangesAsync();
                return Ok("Insert data success in notification info table");
            }
            catch (Exception ex)
            {
                return StatusCode(500, ex.Message);
            }
        }


        [Authorize(Policy = "RequireforAllRole")]
        [Route("addnewnotification")]
        [HttpPost]
        public async Task<IActionResult> AddNewNotification([FromBody] NewNotificationInfoModelDTO obj)
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


                // 1. Validate model
                if (!ModelState.IsValid)
                {
                    return StatusCode(
                        501,
                        "The provided data is not in correct format."
                    );
                }

                // 1. Validate model
                if (!ModelState.IsValid)
                {
                    return StatusCode(
                        501,
                        "The provided data is not in correct format."
                    );
                }

                //var ExistingUser = await Database.UserInfos
                //    .FirstOrDefaultAsync(x => x.Email == obj.CurrentUserEmail);

                //if (ExistingUser == null)
                //{
                //    return StatusCode(502, "User not found.");
                //}

              //  var Provider = await Database.UserInfos
              //.FirstOrDefaultAsync(x => x.Email == obj.ReceiverEmail);
              //  if (Provider == null)
              //  {
              //      return StatusCode(503, "Provider not found.");
              //  }

                var Data = new NewNotificationInfoModel
                {
                    ReceiverNumber = obj.ReceiverNumber,
                    Status = obj.Status
                };

                var InsertData = await Database.NewNotificationInfos.FirstOrDefaultAsync(x => x.ReceiverNumber == obj.ReceiverNumber);


                if (InsertData != null)
                {
                    InsertData.Status = obj.Status;
                    await Database.SaveChangesAsync();
                    return Ok("New notification updated.");
                }
                else
                {

                    await Database.NewNotificationInfos.AddAsync(Data);
                    await Database.SaveChangesAsync();
                    return Ok("Insert data success in new notification info table");
                }
            }
            catch (Exception ex)
            {
                return StatusCode(500, ex.Message);
            }
        }




    }
}
