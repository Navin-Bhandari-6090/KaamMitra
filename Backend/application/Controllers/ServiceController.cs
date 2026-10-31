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
        private readonly IWebHostEnvironment _environment;

        public ServiceController(DatabaseController database, IWebHostEnvironment environment)
        {
            this.Database = database;
            this._environment = environment;
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

                var userNumberClaim =
User.FindFirst(ClaimTypes.NameIdentifier)?.Value;

                if (!int.TryParse(userNumberClaim, out int currentUserNumber))
                {
                    return StatusCode(404);
                }


                var user = await Database.UserInfos
                    .FirstOrDefaultAsync(x => x.UserNumber == currentUserNumber);

                if (user == null)
                {

                    return StatusCode(404, "User not found");
                }


                if (user.LoginAccess == false)
                {
                    return StatusCode(404, "You have been blocked by System.Contact to KaamMitra community.");
                }

                if (!ModelState.IsValid)
                {
                    return StatusCode(502, "Invalid input data.");
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
                        Photo = x.Photo,
                        Address=x.Address
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


                var ServiceInfo = await Database.ProviderServiceInfo
      .Select(x => new ProviderServicesResponseDTO
      {
          ProviderServiceId = x.ProviderServiceId,
          ServiceName = x.ServiceName,
          ServiceDocument = x.ServiceDocument,

          UserNumber = x.UserNumber,
          ProRegServiceDescription=x.ProRegServiceDescription
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
        public async Task<IActionResult> AddBookingInfo([FromForm] BookingInfoDTO obj)
        {
            string? physicalFilePath = null;
            string? physicalVideoPath = null;

            try
            {
                // 1. Validate JWT user number
                var userNumberClaim =
                    User.FindFirst(ClaimTypes.NameIdentifier)?.Value;

                if (!int.TryParse(userNumberClaim, out int currentUserNumber))
                {
                    return StatusCode(401, "Invalid user authentication.");
                }

                // 2. Find current user
                var user = await Database.UserInfos
                    .FirstOrDefaultAsync(x => x.UserNumber == currentUserNumber);

                if (user == null)
                {
                    return StatusCode(502, "User not found.");
                }

                // 3. Check user access
                if (user.LoginAccess == false)
                {
                    return StatusCode(
                        506,
                        "You have been blocked by System. Contact the KaamMitra community."
                    );
                }

                // 4. Validate booking data
                if (!ModelState.IsValid)
                {
                    return StatusCode(
                        400,
                        "The provided booking data is not in the correct format."
                    );
                }

                // 5. Find provider
                var Provider = await Database.UserInfos
                    .FirstOrDefaultAsync(
                        x => x.UserNumber == obj.ProviderNumber
                    );

                if (Provider == null)
                {
                    return StatusCode(503, "Provider not found.");
                }

                // 6. Prepare wwwroot upload folders
                var webRootPath = _environment.WebRootPath;

                if (string.IsNullOrWhiteSpace(webRootPath))
                {
                    webRootPath = Path.Combine(
                        Directory.GetCurrentDirectory(),
                        "wwwroot"
                    );
                }

                var bookingFileFolder = Path.Combine(
                    webRootPath,
                    "uploads",
                    "booking",
                    "file"
                );

                var bookingVideoFolder = Path.Combine(
                    webRootPath,
                    "uploads",
                    "booking",
                    "video"
                );

                Directory.CreateDirectory(bookingFileFolder);
                Directory.CreateDirectory(bookingVideoFolder);

                // 7. Save optional booking file
                string? bookingFileRelativePath = null;

                if (obj.BookingFile != null && obj.BookingFile.Length > 0)
                {
                    var fileExtension =
                        Path.GetExtension(obj.BookingFile.FileName);

                    var fileName = $"{Guid.NewGuid():N}{fileExtension}";

                    physicalFilePath = Path.Combine(
                        bookingFileFolder,
                        fileName
                    );

                    using (var stream = new FileStream(
                        physicalFilePath,
                        FileMode.CreateNew,
                        FileAccess.Write))
                    {
                        await obj.BookingFile.CopyToAsync(stream);
                    }

                    bookingFileRelativePath =
                        $"/uploads/booking/file/{fileName}";
                }

                // 8. Save optional booking video
                string? bookingVideoRelativePath = null;

                if (obj.BookingVideo != null && obj.BookingVideo.Length > 0)
                {
                    var videoExtension =
                        Path.GetExtension(obj.BookingVideo.FileName);

                    var fileName = $"{Guid.NewGuid():N}{videoExtension}";

                    physicalVideoPath = Path.Combine(
                        bookingVideoFolder,
                        fileName
                    );

                    using (var stream = new FileStream(
                        physicalVideoPath,
                        FileMode.CreateNew,
                        FileAccess.Write))
                    {
                        await obj.BookingVideo.CopyToAsync(stream);
                    }

                    bookingVideoRelativePath =
                        $"/uploads/booking/video/{fileName}";
                }

                // 9. Create booking information
                var Data = new BookinInfoModel
                {
                 
                    Distance = obj.Distance,
                    ServiceName = obj.ServiceName,

                    ProviderNumber = Provider.UserNumber,
                    ProviderApprovalStatus = false,
                    ProviderTaskCompleteStatus = false,
                    UserTaskCompleteStatus = false,

                    UserNumber = currentUserNumber,
                    CreatedAt = DateTime.UtcNow,
                    UserApprovalStatus = true,
                    UserBookingDescription = obj.UserBookingDescription,

                    RequiredAdvancePayment = false,

                    // Optional uploaded file paths
                    BookingFile = bookingFileRelativePath,
                    BookingVideo = bookingVideoRelativePath
                };

                // 10. Save booking to database
                await Database.BookingInfos.AddAsync(Data);
                await Database.SaveChangesAsync();

                // 11. Return success
                return Ok();
            }
            catch (Exception ex)
            {

                // 12. Remove uploaded files if booking creation fails
                try
                {
                    if (physicalFilePath != null &&
                        System.IO.File.Exists(physicalFilePath))
                    {
                        System.IO.File.Delete(physicalFilePath);
                    }

                    if (physicalVideoPath != null &&
                        System.IO.File.Exists(physicalVideoPath))
                    {
                        System.IO.File.Delete(physicalVideoPath);
                    }
                }
                catch
                {
                    // Preserve the original exception.
                }

                return StatusCode(
                    500,
                    $"Failed to create booking: {ex.Message}"
                );

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

       

                var Data = new NewNotificationInfoModel
                {
                    ReceiverNumber = obj.ReceiverNumber,
                    Status = true
                };

                var InsertData = await Database.NewNotificationInfos.FirstOrDefaultAsync(x => x.ReceiverNumber == obj.ReceiverNumber);


                if (InsertData != null)
                {
                    InsertData.Status = true;
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
