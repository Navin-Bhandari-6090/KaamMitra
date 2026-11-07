using application.Data;
using application.Models;
using application.Models.DTOModels;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using System.Security.Claims;

namespace application.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class AdminController : ControllerBase
    {

        public DatabaseController Database { get; set; }
        private readonly IWebHostEnvironment _environment;


        public AdminController(DatabaseController Database, IWebHostEnvironment Environment)
        {
            this.Database = Database;
            this._environment = Environment;

        }


        [Authorize(Policy = "RequireAdminRole")]
        [HttpGet]
        [Route("getservicenormal")]
        public async Task<IActionResult> GetServiceInfo()
        {

            try
            {


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

                var Service_Data = await Database.ServiceInfos.ToListAsync();
                if (Service_Data.Count > 0)
                {
                    return Ok(Service_Data);
                }
                else
                {
                    return StatusCode(500, "No service data available.");
                }

            }
            catch (Exception ex)
            {
                return StatusCode(501, ex.Message);
            }
        }


        [Authorize(Policy = "RequireAdminRole")]
        [HttpPost]
        [Route("registerservice")]
        public async Task<IActionResult> AddService([FromBody] ServiceInfoModel obj)
        {

            try
            {
                if (ModelState.IsValid)
                {

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

                    var Service_Data = await Database.ServiceInfos.AnyAsync(x => x.ServiceName == obj.ServiceName);
                    if (Service_Data == false)
                    {
                        // Use synchronous Add to avoid awaiting an EntityEntry which is not awaitable
                        await Database.ServiceInfos.AddAsync(obj);
                        await Database.SaveChangesAsync();
                        return Ok();
                    }
                    else
                    {
                        return StatusCode(502, "Service alread register in that name.");
                    }
                }
                else
                {
                    return StatusCode(500, "Data are not in correct format.");
                }
            }
            catch (Exception ex)
            {
                return StatusCode(501, ex.Message);
            }
        }

        [Authorize(Policy = "RequireAdminRole")]
        [HttpPut]
        [Route("updateservice")]
        public async Task<IActionResult> UpdateServicePrice([FromBody] RegServicePriceUpdateDTO obj)
        {

            try
            {

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

                if (ModelState.IsValid)
                {
                    var Service_Data = await Database.ServiceInfos.FirstOrDefaultAsync(x => x.ServiceId == obj.ServiceId);
                    if (Service_Data != null)
                    {
                        Service_Data.DomesticPrice = obj.DomesticPrice;
                        Service_Data.DomesticPriceDiscount = obj.DomesticPriceDiscount;
                        Service_Data.InternationalPrice = obj.InternationalPrice;
                        Service_Data.InternationalPriceDiscount = obj.InternationalPriceDiscount;
                        await Database.SaveChangesAsync();
                        return Ok();
                    }
                    else
                    {
                        return StatusCode(502, "No service data available with that id.");
                    }
                }
                else
                {
                    return StatusCode(500, "Data are not in correct format.");
                }
            }
            catch (Exception ex)
            {
                return StatusCode(501, ex.Message);
            }
        }



        [Authorize(Policy = "RequireAdminRole")]
        [HttpDelete]
        [Route("deleteservice")]
        public async Task<IActionResult> DeleteService([FromBody] ServiceIdDTO obj)
        {

            try
            {

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

                if (ModelState.IsValid)
                {
                    var Service_Data = await Database.ServiceInfos.FirstOrDefaultAsync(x => x.ServiceId == obj.ServiceId);
                    if (Service_Data != null)
                    {
                        Database.ServiceInfos.Remove(Service_Data);
                        await Database.SaveChangesAsync();
                        return Ok();
                  
                    }
                    else
                    {

                        return StatusCode(502, "Service not present with that id.");
                    }
                }
                else
                {
                    return StatusCode(500, "Data are not in correct format.");
                }
            }
            catch (Exception ex)
            {
                return StatusCode(501, ex.Message);
            }
        }




        [HttpPost]
        [Route("addadvertisement")]
        [RequestSizeLimit(2_147_483_648)]
        [RequestFormLimits(MultipartBodyLengthLimit = 2_147_483_648)]
        public async Task<IActionResult> AddAdvertisement(
    [FromForm] AdvertisementInfoModelDTO obj)
        {
            string? SavedPhotoPath = null;
            string? SavedVideoPath = null;

            try
            {

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

                Console.WriteLine("========== ADD ADVERTISEMENT ==========");

                // ---------------------------------------------------------
                // 1. Check ModelState
                // ---------------------------------------------------------
                if (!ModelState.IsValid)
                {
                    Console.WriteLine("ModelState is invalid.");

                    foreach (var item in ModelState)
                    {
                        foreach (var error in item.Value.Errors)
                        {
                            Console.WriteLine(
                                $"ModelState Error - {item.Key}: {error.ErrorMessage}");
                        }
                    }

                    return StatusCode(400, "Invalid advertisement data.");
                }
                else
                {
                    Console.WriteLine("ModelState is valid.");
                }

                // ---------------------------------------------------------
                // 2. Check Advertisement Title
                // Only Tittle is required
                // ---------------------------------------------------------
                if (string.IsNullOrWhiteSpace(obj.Tittle))
                {
                    Console.WriteLine("Advertisement title is empty.");

                    return StatusCode(400, "Advertisement title is required.");
                }
                else
                {
                    Console.WriteLine(
                        $"Advertisement title: {obj.Tittle.Trim()}");
                }

                // ---------------------------------------------------------
                // 3. WebRootPath
                // ---------------------------------------------------------
                if (string.IsNullOrWhiteSpace(_environment.WebRootPath))
                {
                    Console.WriteLine("WebRootPath is not configured.");

                    return StatusCode(500, "Server wwwroot folder is not configured.");
                }
                else
                {
                    Console.WriteLine(
                        $"WebRootPath: {_environment.WebRootPath}");
                }

                // ---------------------------------------------------------
                // 4. Advertisement folders
                // ---------------------------------------------------------
                string AdvertisementFolder =
                    Path.Combine(
                        _environment.WebRootPath,
                        "uploads",
                        "advertisements");

                string PhotoFolder =
                    Path.Combine(
                        AdvertisementFolder,
                        "photos");

                string VideoFolder =
                    Path.Combine(
                        AdvertisementFolder,
                        "videos");

                Console.WriteLine(
                    $"Advertisement folder: {AdvertisementFolder}");

                // ---------------------------------------------------------
                // 5. Create advertisement main folder
                // ---------------------------------------------------------
                if (!Directory.Exists(AdvertisementFolder))
                {
                    Directory.CreateDirectory(AdvertisementFolder);

                    Console.WriteLine(
                        "Advertisement folder created.");
                }
                else
                {
                    Console.WriteLine(
                        "Advertisement folder already exists.");
                }

                // =========================================================
                // 6. OPTIONAL PHOTO
                // =========================================================
                if (obj.Photo != null && obj.Photo.Length > 0)
                {
                    Console.WriteLine("Advertisement photo is provided.");

                    string PhotoExtension =
                        Path.GetExtension(obj.Photo.FileName)
                            .TrimStart('.')
                            .ToLower();

                    Console.WriteLine(
                        $"Photo extension: {PhotoExtension}");

                    if (PhotoExtension != "jpg" &&
                        PhotoExtension != "jpeg" &&
                        PhotoExtension != "png")
                    {
                        Console.WriteLine(
                            "Invalid advertisement photo extension.");

                        return StatusCode(
                            400,
                            "Only jpg, jpeg and png photo files are allowed.");
                    }
                    else
                    {
                        Console.WriteLine(
                            "Advertisement photo extension is valid.");
                    }

                    // Create photo folder
                    if (!Directory.Exists(PhotoFolder))
                    {
                        Directory.CreateDirectory(PhotoFolder);

                        Console.WriteLine(
                            "Advertisement photo folder created.");
                    }
                    else
                    {
                        Console.WriteLine(
                            "Advertisement photo folder already exists.");
                    }

                    // Generate unique filename
                    string PhotoFileName =
                        $"{Guid.NewGuid()}.{PhotoExtension}";

                    string PhysicalPhotoPath =
                        Path.Combine(
                            PhotoFolder,
                            PhotoFileName);

                    Console.WriteLine(
                        $"Photo physical path: {PhysicalPhotoPath}");

                    // Save photo
                    using (FileStream PhotoStream =
                           new FileStream(
                               PhysicalPhotoPath,
                               FileMode.Create))
                    {
                        await obj.Photo.CopyToAsync(PhotoStream);
                    }

                    Console.WriteLine(
                        "Advertisement photo saved successfully.");

                    // Save relative path in database
                    SavedPhotoPath =
                        $"/uploads/advertisements/photos/{PhotoFileName}";

                    Console.WriteLine(
                        $"Photo database path: {SavedPhotoPath}");
                }
                else
                {
                    Console.WriteLine(
                        "Advertisement photo is not provided.");
                }

                // =========================================================
                // 7. OPTIONAL VIDEO
                // =========================================================
                if (obj.Video != null && obj.Video.Length > 0)
                {
                    Console.WriteLine("Advertisement video is provided.");

                    string VideoExtension =
                        Path.GetExtension(obj.Video.FileName)
                            .TrimStart('.')
                            .ToLower();

                    Console.WriteLine(
                        $"Video extension: {VideoExtension}");

                    if (VideoExtension != "mp4")
                    {
                        Console.WriteLine(
                            "Invalid advertisement video extension.");

                        // Delete already saved photo if video validation fails
                        if (!string.IsNullOrWhiteSpace(SavedPhotoPath))
                        {
                            string SavedPhotoPhysicalPath =
                                Path.Combine(
                                    _environment.WebRootPath,
                                    SavedPhotoPath.TrimStart('/').Replace(
                                        "/",
                                        Path.DirectorySeparatorChar.ToString()));

                            if (System.IO.File.Exists(
                                SavedPhotoPhysicalPath))
                            {
                                System.IO.File.Delete(
                                    SavedPhotoPhysicalPath);

                                Console.WriteLine(
                                    "Previously saved photo deleted.");
                            }
                        }

                        return StatusCode(
                            400,
                            "Only mp4 video files are allowed.");
                    }
                    else
                    {
                        Console.WriteLine(
                            "Advertisement video extension is valid.");
                    }

                    // Create video folder
                    if (!Directory.Exists(VideoFolder))
                    {
                        Directory.CreateDirectory(VideoFolder);

                        Console.WriteLine(
                            "Advertisement video folder created.");
                    }
                    else
                    {
                        Console.WriteLine(
                            "Advertisement video folder already exists.");
                    }

                    // Generate unique filename
                    string VideoFileName =
                        $"{Guid.NewGuid()}.{VideoExtension}";

                    string PhysicalVideoPath =
                        Path.Combine(
                            VideoFolder,
                            VideoFileName);

                    Console.WriteLine(
                        $"Video physical path: {PhysicalVideoPath}");

                    // Save video
                    using (FileStream VideoStream =
                           new FileStream(
                               PhysicalVideoPath,
                               FileMode.Create))
                    {
                        await obj.Video.CopyToAsync(VideoStream);
                    }

                    Console.WriteLine(
                        "Advertisement video saved successfully.");

                    // Save relative path in database
                    SavedVideoPath =
                        $"/uploads/advertisements/videos/{VideoFileName}";

                    Console.WriteLine(
                        $"Video database path: {SavedVideoPath}");
                }
                else
                {
                    Console.WriteLine(
                        "Advertisement video is not provided.");
                }

                // =========================================================
                // 8. OPTIONAL URL
                // =========================================================
                string? AdvertisementUrl = null;

                if (!string.IsNullOrWhiteSpace(obj.UrlLink))
                {
                    AdvertisementUrl = obj.UrlLink.Trim();

                    Console.WriteLine(
                        $"Advertisement URL: {AdvertisementUrl}");
                }
                else
                {
                    Console.WriteLine(
                        "Advertisement URL is not provided.");
                }

                // =========================================================
                // 9. Create Advertisement database object
                // =========================================================
                AdvertisementInfoModel Advertisement =
                    new AdvertisementInfoModel
                    {
                        Tittle = obj.Tittle.Trim(),

                        Photo = SavedPhotoPath,

                        Video = SavedVideoPath,

                        UrlLink = AdvertisementUrl,

                            UploadedAt=DateTime.UtcNow
                    };

                // =========================================================
                // 10. Add to database
                // =========================================================
                await Database.AdvertisementInfos.AddAsync(Advertisement);

         

                await Database.SaveChangesAsync();

            

                return StatusCode(
                    200,
                    "Advertisement added successfully.");
            }
            catch (Exception ex)
            {
             

                // ---------------------------------------------------------
                // Delete saved photo if exception occurs
                // ---------------------------------------------------------
                try
                {
                    if (!string.IsNullOrWhiteSpace(SavedPhotoPath))
                    {
                        string SavedPhotoPhysicalPath =
                            Path.Combine(
                                _environment.WebRootPath,
                                SavedPhotoPath.TrimStart('/')
                                    .Replace(
                                        "/",
                                        Path.DirectorySeparatorChar.ToString()));

                        if (System.IO.File.Exists(
                            SavedPhotoPhysicalPath))
                        {
                            System.IO.File.Delete(
                                SavedPhotoPhysicalPath);

                            Console.WriteLine(
                                "Saved advertisement photo deleted after exception.");
                        }
                    }
                }
                catch (Exception CleanupPhotoException)
                {
                    Console.WriteLine(
                        $"Photo cleanup error: {CleanupPhotoException.Message}");
                }

                // ---------------------------------------------------------
                // Delete saved video if exception occurs
                // ---------------------------------------------------------
                try
                {
                    if (!string.IsNullOrWhiteSpace(SavedVideoPath))
                    {
                        string SavedVideoPhysicalPath =
                            Path.Combine(
                                _environment.WebRootPath,
                                SavedVideoPath.TrimStart('/')
                                    .Replace(
                                        "/",
                                        Path.DirectorySeparatorChar.ToString()));

                        if (System.IO.File.Exists(
                            SavedVideoPhysicalPath))
                        {
                            System.IO.File.Delete(
                                SavedVideoPhysicalPath);

                            Console.WriteLine(
                                "Saved advertisement video deleted after exception.");
                        }
                    }
                }
                catch (Exception CleanupVideoException)
                {
                    Console.WriteLine(
                        $"Video cleanup error: {CleanupVideoException.Message}");
                }

                return StatusCode(
                    500,
                    $"An error occurred while adding advertisement: {ex.Message}");
            }
        }


        [Authorize(Policy = "RequireAdminRole")]
        [HttpDelete]
        [Route("deleteadvertisement")]

        public async Task<IActionResult> DeleteAdvertisement(
    [FromBody] ADidDTO obj)
        {
            try
            {

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

                Console.WriteLine("========== DELETE ADVERTISEMENT ==========");

                // =========================================================
                // 1. Check ModelState
                // =========================================================

                if (!ModelState.IsValid)
                {
                    Console.WriteLine("ModelState is invalid.");

                    foreach (var item in ModelState)
                    {
                        foreach (var error in item.Value.Errors)
                        {
                            Console.WriteLine(
                                $"ModelState Error - {item.Key}: {error.ErrorMessage}");
                        }
                    }

                    return StatusCode(
                        400,
                        "Invalid advertisement data."
                    );
                }

                Console.WriteLine(
                    $"AdvertisementId received: {obj.AdvertisementId}"
                );

                // =========================================================
                // 2. Validate AdvertisementId
                // =========================================================

                if (obj.AdvertisementId <= 0)
                {
                    Console.WriteLine("Invalid AdvertisementId.");

                    return StatusCode(
                        400,
                        "Invalid AdvertisementId."
                    );
                }

                // =========================================================
                // 3. Find Advertisement
                // =========================================================

                var advertisement =
                    await Database.AdvertisementInfos
                        .FirstOrDefaultAsync(
                            x => x.AdvertisementId == obj.AdvertisementId
                        );

                if (advertisement == null)
                {
                    Console.WriteLine(
                        $"Advertisement not found. AdvertisementId: {obj.AdvertisementId}"
                    );

                    return StatusCode(
                        404,
                        "Advertisement not found."
                    );
                }

                Console.WriteLine(
                    $"Advertisement found. AdvertisementId: {advertisement.AdvertisementId}"
                );

                Console.WriteLine(
                    $"Advertisement Title: {advertisement.Tittle}"
                );

                Console.WriteLine(
                    $"Photo path: {advertisement.Photo ?? "NULL"}"
                );

                Console.WriteLine(
                    $"Video path: {advertisement.Video ?? "NULL"}"
                );

                // =========================================================
                // 4. Check WebRootPath
                // =========================================================

                if (string.IsNullOrWhiteSpace(_environment.WebRootPath))
                {
                    Console.WriteLine(
                        "WebRootPath is not configured."
                    );

                    return StatusCode(
                        500,
                        "Server wwwroot folder is not configured."
                    );
                }

                Console.WriteLine(
                    $"WebRootPath: {_environment.WebRootPath}"
                );

                // =========================================================
                // 5. Delete Photo File
                // =========================================================

                if (!string.IsNullOrWhiteSpace(advertisement.Photo))
                {
                    try
                    {
                        string PhotoRelativePath =
                            advertisement.Photo.TrimStart(
                                '/',
                                '\\'
                            );

                        string PhotoPhysicalPath =
                            Path.Combine(
                                _environment.WebRootPath,
                                PhotoRelativePath
                                    .Replace(
                                        '/',
                                        Path.DirectorySeparatorChar
                                    )
                                    .Replace(
                                        '\\',
                                        Path.DirectorySeparatorChar
                                    )
                            );

                        Console.WriteLine(
                            $"Photo physical path: {PhotoPhysicalPath}"
                        );

                        if (System.IO.File.Exists(PhotoPhysicalPath))
                        {
                            System.IO.File.Delete(PhotoPhysicalPath);

                            Console.WriteLine(
                                "Advertisement photo deleted successfully."
                            );
                        }
                        else
                        {
                            Console.WriteLine(
                                "Advertisement photo file does not exist. Skipping."
                            );
                        }
                    }
                    catch (Exception PhotoException)
                    {
                        Console.WriteLine(
                            "Exception while deleting advertisement photo."
                        );

                        Console.WriteLine(
                            $"Photo delete exception: {PhotoException.Message}"
                        );

                        // Do not crash because of a missing/unavailable file.
                        // Continue with video and database deletion.
                    }
                }
                else
                {
                    Console.WriteLine(
                        "Advertisement does not have a photo."
                    );
                }

                // =========================================================
                // 6. Delete Video File
                // =========================================================

                if (!string.IsNullOrWhiteSpace(advertisement.Video))
                {
                    try
                    {
                        string VideoRelativePath =
                            advertisement.Video.TrimStart(
                                '/',
                                '\\'
                            );

                        string VideoPhysicalPath =
                            Path.Combine(
                                _environment.WebRootPath,
                                VideoRelativePath
                                    .Replace(
                                        '/',
                                        Path.DirectorySeparatorChar
                                    )
                                    .Replace(
                                        '\\',
                                        Path.DirectorySeparatorChar
                                    )
                            );

                        Console.WriteLine(
                            $"Video physical path: {VideoPhysicalPath}"
                        );

                        if (System.IO.File.Exists(VideoPhysicalPath))
                        {
                            System.IO.File.Delete(VideoPhysicalPath);

                            Console.WriteLine(
                                "Advertisement video deleted successfully."
                            );
                        }
                        else
                        {
                            Console.WriteLine(
                                "Advertisement video file does not exist. Skipping."
                            );
                        }
                    }
                    catch (Exception VideoException)
                    {
                        Console.WriteLine(
                            "Exception while deleting advertisement video."
                        );

                        Console.WriteLine(
                            $"Video delete exception: {VideoException.Message}"
                        );

                        // Do not crash because of a missing/unavailable file.
                        // Continue with database deletion.
                    }
                }
                else
                {
                    Console.WriteLine(
                        "Advertisement does not have a video."
                    );
                }

                // =========================================================
                // 7. Delete Advertisement Database Row
                // =========================================================

                Database.AdvertisementInfos.Remove(advertisement);

                Console.WriteLine(
                    "Advertisement marked for database deletion."
                );

                await Database.SaveChangesAsync();

                Console.WriteLine(
                    "Advertisement database row deleted successfully."
                );

                // =========================================================
                // 8. Success
                // =========================================================

                Console.WriteLine(
                    "Advertisement deleted successfully."
                );

                return StatusCode(
                    200,
                    "Advertisement deleted successfully."
                );
            }
            catch (Exception ex)
            {
                // =========================================================
                // 9. Main Exception
                // =========================================================

                Console.WriteLine(
                    "========== DELETE ADVERTISEMENT ERROR =========="
                );

                Console.WriteLine(
                    $"Exception: {ex.Message}"
                );

                Console.WriteLine(
                    $"StackTrace: {ex.StackTrace}"
                );

                return StatusCode(
                    500,
                    "An error occurred while deleting advertisement."
                );
            }
        }


        [Authorize(Policy = "RequireAdminRole")]
        [HttpPut]
        [Route("updateloginaccess")]
        public async Task<IActionResult> UpdateLoginAccess([FromBody] UserNumberDTO obj)
        {

            try
            {

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

                if (ModelState.IsValid)
                {
                    var Service_Data = await Database.UserInfos.FirstOrDefaultAsync(x => x.UserNumber == obj.UserNumber);
                    if (Service_Data != null)
                    {
                        if (Service_Data.LoginAccess == true)
                        {
                            Service_Data.LoginAccess = false;
                            await Database.SaveChangesAsync();
                            return Ok();
                        }
                        else {
                            Service_Data.LoginAccess = true;
                            await Database.SaveChangesAsync();
                            return Ok();
                        }
                      
                    }
                    else
                    {
                        return StatusCode(502, "No user data available with that number.");
                    }
                }
                else
                {
                    return StatusCode(500, "Data are not in correct format.");
                }
            }
            catch (Exception ex)
            {
                return StatusCode(501, ex.Message);
            }
        }

        [Authorize(Policy = "RequireforAllRole")]
        [HttpGet]
        [Route("getuserinfo")]
        public async Task<IActionResult> GetUserInfo()
        {
            try
            {

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

                var user_data = await Database.UserInfos.ToListAsync();

                if (user_data.Count >= 1)
                {
                    var user_info = user_data.Select(user => new SendUserAdminScreenDTO
                    {
                        UserNumber = user.UserNumber,
                        FirstName = user.FirstName,
                        LastName = user.LastName,
                        Email = user.Email,
                        Address = user.Address,
                        PhoneNumber = user.PhoneNumber,
                        WhatsappPhoneNumber = user.WhatsappPhoneNumber,
                        Latitude = user.Latitude,
                        Longitude = user.Longitude,
                        Role = user.Role,
                        LoginAccess = (bool)user.LoginAccess,

                    }).ToList();

                    return Ok(user_info);
                }
                else
                {
                    return StatusCode(500, "No user data found.");
                }
            }
            catch (Exception ex)
            {
                return StatusCode(501, ex.Message);
            }
        }

        [Authorize(Policy = "RequireAdminRole")]
        [HttpPost]
        [Route("deleteservice")]
        public async Task<IActionResult> DeleteService(
     [FromBody] ProviderServiceIdDTO obj)
        {
            try
            {
                var userNumberClaim =
                    User.FindFirst(ClaimTypes.NameIdentifier)?.Value;

                if (!int.TryParse(userNumberClaim, out int userNumber))
                    return Forbid();

                var user = await Database.UserInfos
                    .FirstOrDefaultAsync(x => x.UserNumber == userNumber);

                if (user == null)
                    return StatusCode(505, "User not found.");

                if (user.LoginAccess == false)
                    return StatusCode(
                        506,
                        "You have been blocked by System. Contact the KaamMitra community.");

                if (obj == null)
                    return StatusCode(400, "Request data is required.");

                if (!ModelState.IsValid)
                    return StatusCode(400, "Data are not in the correct format.");

                if (obj.ProviderServiceId <= 0)
                    return StatusCode(400, "ProviderServiceId is required.");

                var serviceData = await Database.ProviderServiceInfo
                    .FirstOrDefaultAsync(x =>
                        x.ProviderServiceId == obj.ProviderServiceId);

                if (serviceData == null)
                    return StatusCode(404, "Registered service is not present.");

                var serviceResources = await Database.ProviderServiceResourcesInfo
                    .Where(x => x.ProviderServiceId == obj.ProviderServiceId)
                    .ToListAsync();

                var webRootPath = _environment.WebRootPath;

                if (string.IsNullOrWhiteSpace(webRootPath))
                {
                    webRootPath = Path.Combine(
                        Directory.GetCurrentDirectory(),
                        "wwwroot");
                }

                webRootPath = Path.GetFullPath(webRootPath);

                var rootPrefix = Path.TrimEndingDirectorySeparator(webRootPath)
                    + Path.DirectorySeparatorChar;

                var pathComparison = OperatingSystem.IsWindows()
                    ? StringComparison.OrdinalIgnoreCase
                    : StringComparison.Ordinal;

                var storedFilePaths = new List<string?>();

                // Collect the service document path.
                storedFilePaths.Add(serviceData.ServiceDocument);

                // Collect every resource photo, video, and service file path.
                foreach (var resource in serviceResources)
                {
                    if (resource == null)
                        continue;

                    storedFilePaths.Add(resource.ServicePhoto);
                    storedFilePaths.Add(resource.ServiceVideo);
                    storedFilePaths.Add(resource.ServiceFile);
                }

                // Resolve only paths that remain safely inside wwwroot.
                string? ResolvePhysicalPath(string? storedPath)
                {
                    if (string.IsNullOrWhiteSpace(storedPath))
                        return null;

                    var normalizedPath = storedPath.Trim()
                        .Replace('\\', Path.DirectorySeparatorChar)
                        .Replace('/', Path.DirectorySeparatorChar)
                        .TrimStart(Path.DirectorySeparatorChar);

                    if (string.IsNullOrWhiteSpace(normalizedPath) ||
                        Path.IsPathRooted(normalizedPath))
                    {
                        return null;
                    }

                    var physicalPath = Path.GetFullPath(
                        Path.Combine(webRootPath, normalizedPath));

                    if (!physicalPath.StartsWith(
                            rootPrefix,
                            pathComparison))
                    {
                        return null;
                    }

                    return physicalPath;
                }

                var physicalFilePaths = new HashSet<string>(
                    OperatingSystem.IsWindows()
                        ? StringComparer.OrdinalIgnoreCase
                        : StringComparer.Ordinal);

                foreach (var storedPath in storedFilePaths)
                {
                    var physicalPath = ResolvePhysicalPath(storedPath);

                    if (physicalPath != null)
                        physicalFilePaths.Add(physicalPath);
                }

                // Delete resource records and the registered service in one database save.
                if (serviceResources.Count > 0)
                {
                    Database.ProviderServiceResourcesInfo
                        .RemoveRange(serviceResources);
                }

                Database.ProviderServiceInfo.Remove(serviceData);

                await Database.SaveChangesAsync();

                // Delete the physical files only after the database deletion succeeds.
                bool fileCleanupIncomplete = false;

                foreach (var physicalPath in physicalFilePaths)
                {
                    try
                    {
                        if (System.IO.File.Exists(physicalPath))
                        {
                            System.IO.File.Delete(physicalPath);
                        }
                    }
                    catch (IOException)
                    {
                        fileCleanupIncomplete = true;
                    }
                    catch (UnauthorizedAccessException)
                    {
                        fileCleanupIncomplete = true;
                    }
                    catch (Exception)
                    {
                        fileCleanupIncomplete = true;
                    }
                }

                if (fileCleanupIncomplete)
                {
                    return Ok(new
                    {
                        Message = "Service and resource records were deleted, but some physical files could not be removed.",
              
                        FileCleanupIncomplete = true
                    });
                }

                return Ok(new
                {
                    Message = "Registered service and all associated resources deleted successfully.",
             
                    FileCleanupIncomplete = false
                });

            }
            catch (Exception)
            {
                return StatusCode(
                    500,
                    "An error occurred while deleting the registered service and its resources.");
            }
        }


        [Authorize(Policy = "RequireAdminRole")]
        [HttpGet]
        [Route("getallproviderservices")]
        public async Task<IActionResult> GetAllProviderServices()
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


                // Get all provider registered services of this user
                var serviceList = await Database.ProviderServiceInfo.ToListAsync();

                // No services found
                if (serviceList == null || serviceList.Count == 0)
                {
                    return StatusCode(404, "No registered services are present for this user.");
                }

                return Ok(serviceList);
            }
            catch (Exception ex)
            {
                return StatusCode(
                    500,
                    $"An error occurred while getting provider services: {ex.Message}"
                );
            }
        }

        [Authorize(Policy = "RequireAdminRole")]
        [HttpGet]
        [Route("getallproviderserviceresources")]
        public async Task<IActionResult> GetAllProviderServiceResources()
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


                // Get all provider service resources
                var resourceList = await Database.ProviderServiceResourcesInfo
                    .ToListAsync();

                // Check if data exists
                if (resourceList == null || resourceList.Count == 0)
                {
                    return StatusCode(404, "No provider service resources are present.");
                }

                // Return all data
                return Ok(resourceList);
            }
            catch (Exception ex)
            {
                return StatusCode(
                    500,
                    $"An error occurred while getting provider service resources: {ex.Message}"
                );
            }
        }

        [Authorize(Policy = "RequireAdminRole")]
        [HttpGet]
        [Route("getalladvancepaymentinfos")]
        public async Task<IActionResult> GetAllAdvancePaymentInfos()
        {
            try
            {
              

                // Check ModelState
                if (!ModelState.IsValid)
                {
                    return StatusCode(400, "Data are not in correct format.");
                }

                // Check user

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

                if (user.LoginAccess==false)
                {
                    return StatusCode(506,"You have been blocked by System.Contact to KaamMitra community.");
                }

                // Get all AdvancePaymentInfos
                var paymentInfoList = await Database.AdvancePaymentInfos
                    .ToListAsync();

                // Check data
                if (paymentInfoList == null || paymentInfoList.Count == 0)
                {
                    return StatusCode(404, "No advance payment information is present.");
                }

                return Ok(paymentInfoList);
            }
            catch (Exception ex)
            {
                return StatusCode(
                    500,
                    $"An error occurred while getting advance payment information: {ex.Message}"
                );
            }
        }

        [Authorize(Policy = "RequireAdminRole")]
        [HttpGet]
        [Route("getalladvancepaymentqrinfos")]
        public async Task<IActionResult> GetAllAdvancePaymentQrInfos()
        {
            try
            {
            

                // Check ModelState
                if (!ModelState.IsValid)
                {
                    return StatusCode(400, "Data are not in correct format.");
                }

                // Check user

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

                // Get all AdvancePaymentQrInfos
                var qrInfoList = await Database.AdvancePaymentQrInfos
                    .ToListAsync();

                // Check data
                if (qrInfoList == null || qrInfoList.Count == 0)
                {
                    return StatusCode(404, "No advance payment QR information is present.");
                }

                return Ok(qrInfoList);
            }
            catch (Exception ex)
            {
                return StatusCode(
                    500,
                    $"An error occurred while getting advance payment QR information: {ex.Message}"
                );
            }
        }

[Authorize(Policy = "RequireAdminRole")]
[HttpDelete]
[Route("deleteadvancepaymentinfo")]
public async Task<IActionResult> DeleteAdvancePaymentInfo(
    [FromBody] AdvancePayPhotoIdDTO obj)
        {
            try
            {
                // =========================================================
                // CHECK REQUEST DATA
                // =========================================================

                if (obj == null)
                {
                    return StatusCode(
                        400,
                        "Payment ID is required."
                    );
                }

                if (!ModelState.IsValid)
                {
                    return StatusCode(
                        400,
                        "Data are not in correct format."
                    );
                }


                // =========================================================
                // GET USER NUMBER FROM JWT
                // =========================================================

                var userNumberClaim =
                    User.FindFirst(ClaimTypes.NameIdentifier)?.Value;

                if (!int.TryParse(userNumberClaim, out int userNumber))
                {
                    return Forbid();
                }


                // =========================================================
                // CHECK LOGGED-IN USER
                // =========================================================

                var user = await Database.UserInfos
                    .FirstOrDefaultAsync(x =>
                        x.UserNumber == userNumber);

                if (user == null)
                {
                    return StatusCode(
                        404,
                        "User not found."
                    );
                }


                // =========================================================
                // CHECK LOGIN ACCESS
                // =========================================================

                if (user.LoginAccess == false)
                {
                    return StatusCode(
                        506,
                        "You have been blocked by System. Contact KaamMitra community."
                    );
                }


                // =========================================================
                // FIND PAYMENT INFORMATION
                // =========================================================

                var paymentInfo =
                    await Database.AdvancePaymentInfos
                        .FirstOrDefaultAsync(x =>
                            x.PaymentId == obj.PaymentId);

                if (paymentInfo == null)
                {
                    return StatusCode(
                        404,
                        "Advance payment information not found."
                    );
                }


                // =========================================================
                // DELETE PHYSICAL PAYMENT PHOTO
                // =========================================================

                try
                {
                    // Change PaymentPhoto to your actual
                    // database property name if different.
                    var relativeFilePath =
                        paymentInfo.PaymentPhoto;

                    if (!string.IsNullOrWhiteSpace(relativeFilePath))
                    {
                        // Example database path:
                        // /uploads/advance-payment/photo.png

                        var cleanRelativePath =
                            relativeFilePath
                                .TrimStart('/', '\\')
                                .Replace(
                                    '/',
                                    Path.DirectorySeparatorChar
                                )
                                .Replace(
                                    '\\',
                                    Path.DirectorySeparatorChar
                                );

                        var wwwrootPath =
                            Path.Combine(
                                Directory.GetCurrentDirectory(),
                                "wwwroot"
                            );

                        var physicalFilePath =
                            Path.Combine(
                                wwwrootPath,
                                cleanRelativePath
                            );

                        Console.WriteLine(
                            "========== DELETE PAYMENT FILE =========="
                        );

                        Console.WriteLine(
                            $"Database File Path: {relativeFilePath}"
                        );

                        Console.WriteLine(
                            $"Physical File Path: {physicalFilePath}"
                        );

                        if (System.IO.File.Exists(physicalFilePath))
                        {
                            System.IO.File.Delete(
                                physicalFilePath
                            );

                            Console.WriteLine(
                                "Payment physical file deleted successfully."
                            );
                        }
                        else
                        {
                            Console.WriteLine(
                                "Payment physical file was not found."
                            );
                        }
                    }
                    else
                    {
                        Console.WriteLine(
                            "Payment has no physical file path."
                        );
                    }
                }
                catch (Exception fileException)
                {
                    Console.WriteLine(
                        "========== PAYMENT FILE DELETE ERROR =========="
                    );

                    Console.WriteLine(
                        fileException.ToString()
                    );

                    return StatusCode(
                        500,
                        $"Payment database row was not deleted because the physical file could not be deleted: {fileException.Message}"
                    );
                }


                // =========================================================
                // DELETE DATABASE ROW
                // =========================================================

                Database.AdvancePaymentInfos.Remove(
                    paymentInfo
                );

                await Database.SaveChangesAsync();


                // =========================================================
                // SUCCESS
                // =========================================================

                return Ok(
                    "Advance payment information and physical file deleted successfully."
                );
            }
            catch (Exception ex)
            {
                Console.WriteLine(
                    "========== DELETE ADVANCE PAYMENT ERROR =========="
                );

                Console.WriteLine(
                    ex.ToString()
                );

                return StatusCode(
                    500,
                    $"An error occurred while deleting advance payment information: {ex.Message}"
                );
            }
        }



        [Authorize(Policy = "RequireAdminRole")]
        [HttpDelete]
        [Route("deleteadvancepaymentqrinfo")]
        public async Task<IActionResult> DeleteAdvancePaymentQrInfo(
            [FromBody] AdvPayQRIDDTO obj)
        {
            try
            {
                // =========================================================
                // CHECK REQUEST DATA
                // =========================================================

                if (obj == null)
                {
                    return StatusCode(
                        400,
                        "QR ID is required."
                    );
                }

                if (!ModelState.IsValid)
                {
                    return StatusCode(
                        400,
                        "Data are not in correct format."
                    );
                }


                // =========================================================
                // GET USER NUMBER FROM JWT
                // =========================================================

                var userNumberClaim =
                    User.FindFirst(ClaimTypes.NameIdentifier)?.Value;

                if (!int.TryParse(userNumberClaim, out int userNumber))
                {
                    return Forbid();
                }


                // =========================================================
                // CHECK LOGGED-IN USER
                // =========================================================

                var user = await Database.UserInfos
                    .FirstOrDefaultAsync(x =>
                        x.UserNumber == userNumber);

                if (user == null)
                {
                    return StatusCode(
                        404,
                        "User not found."
                    );
                }


                // =========================================================
                // CHECK LOGIN ACCESS
                // =========================================================

                if (user.LoginAccess == false)
                {
                    return StatusCode(
                        506,
                        "You have been blocked by System. Contact KaamMitra community."
                    );
                }


                // =========================================================
                // FIND QR INFORMATION
                // =========================================================

                var qrInfo =
                    await Database.AdvancePaymentQrInfos
                        .FirstOrDefaultAsync(x =>
                            x.QRId == obj.QRId);

                if (qrInfo == null)
                {
                    return StatusCode(
                        404,
                        "Advance payment QR information not found."
                    );
                }


                // =========================================================
                // DELETE PHYSICAL QR PHOTO
                // =========================================================

                try
                {
                    // Change QRPhoto to your actual
                    // database property name if different.
                    var relativeFilePath =
                        qrInfo.QRPhoto;

                    if (!string.IsNullOrWhiteSpace(relativeFilePath))
                    {
                        // Example database path:
                        // /uploads/advance-payment/qr.png

                        var cleanRelativePath =
                            relativeFilePath
                                .TrimStart('/', '\\')
                                .Replace(
                                    '/',
                                    Path.DirectorySeparatorChar
                                )
                                .Replace(
                                    '\\',
                                    Path.DirectorySeparatorChar
                                );

                        var wwwrootPath =
                            Path.Combine(
                                Directory.GetCurrentDirectory(),
                                "wwwroot"
                            );

                        var physicalFilePath =
                            Path.Combine(
                                wwwrootPath,
                                cleanRelativePath
                            );

                        Console.WriteLine(
                            "========== DELETE QR FILE =========="
                        );

                        Console.WriteLine(
                            $"Database File Path: {relativeFilePath}"
                        );

                        Console.WriteLine(
                            $"Physical File Path: {physicalFilePath}"
                        );

                        if (System.IO.File.Exists(physicalFilePath))
                        {
                            System.IO.File.Delete(
                                physicalFilePath
                            );

                            Console.WriteLine(
                                "QR physical file deleted successfully."
                            );
                        }
                        else
                        {
                            Console.WriteLine(
                                "QR physical file was not found."
                            );
                        }
                    }
                    else
                    {
                        Console.WriteLine(
                            "QR information has no physical file path."
                        );
                    }
                }
                catch (Exception fileException)
                {
                    Console.WriteLine(
                        "========== QR FILE DELETE ERROR =========="
                    );

                    Console.WriteLine(
                        fileException.ToString()
                    );

                    return StatusCode(
                        500,
                        $"QR database row was not deleted because the physical file could not be deleted: {fileException.Message}"
                    );
                }


                // =========================================================
                // DELETE DATABASE ROW
                // =========================================================

                Database.AdvancePaymentQrInfos.Remove(
                    qrInfo
                );

                await Database.SaveChangesAsync();


                // =========================================================
                // SUCCESS
                // =========================================================

                return Ok(
                    "Advance payment QR information and physical file deleted successfully."
                );
            }
            catch (Exception ex)
            {
                Console.WriteLine(
                    "========== DELETE ADVANCE PAYMENT QR ERROR =========="
                );

                Console.WriteLine(
                    ex.ToString()
                );

                return StatusCode(
                    500,
                    $"An error occurred while deleting advance payment QR information: {ex.Message}"
                );
            }
        }

        [Authorize(Policy = "RequireforAllRole")]
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
                var advertisementList = await Database.AdvertisementInfos.OrderBy(x=>x.UploadedAt)
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

        [Authorize(Policy = "RequireAdminRole")]
        [HttpPost]
        [RequestSizeLimit(209715200)] // 200 MB
        [RequestFormLimits(MultipartBodyLengthLimit = 209715200)]
        [Route("addadminqr")]
        public async Task<IActionResult> AddAdminQr(
    [FromForm] AdminQRDTO obj)
        {
            string? newDomesticPhysicalPath = null;
            string? newInternationalPhysicalPath = null;

            try
            {
                // =========================================================
                // 1. Validate ModelState
                // =========================================================

                if (!ModelState.IsValid)
                {
                    return StatusCode(
                        400,
                        "Data are not in correct format."
                    );
                }


                // =========================================================
                // 2. Get Current UserNumber From JWT
                // =========================================================

                var userNumberClaim =
                    User.FindFirst(ClaimTypes.NameIdentifier)?.Value;

                if (string.IsNullOrEmpty(userNumberClaim))
                {
                    return Forbid();
                }


                int currentUserNumber;

                if (!int.TryParse(
                        userNumberClaim,
                        out currentUserNumber))
                {
                    return Forbid();
                }

                Console.WriteLine(
                    $"Current UserNumber: {currentUserNumber}"
                );


                // =========================================================
                // 3. Get Current User
                // =========================================================

                var user = await Database.UserInfos
                    .FirstOrDefaultAsync(
                        x => x.UserNumber == currentUserNumber
                    );

                if (user == null)
                {
                    return StatusCode(
                        404,
                        "User not found"
                    );
                }


                // =========================================================
                // 4. Check Login Access
                // =========================================================

                if (user.LoginAccess == false)
                {
                    return StatusCode(
                        506,
                        "You have been blocked by System.Contact to KaamMitra community."
                    );
                }


                string currentUserEmail = user.Email;

                Console.WriteLine(
                    $"Current UserEmail: {currentUserEmail}"
                );


                // =========================================================
                // 5. At Least One QR Must Be Present
                // =========================================================

                if ((obj.DomesticQRPhoto == null ||
                     obj.DomesticQRPhoto.Length == 0) &&
                    (obj.InternationalQRPhoto == null ||
                     obj.InternationalQRPhoto.Length == 0))
                {
                    return StatusCode(
                        400,
                        "At least one QR photo is required."
                    );
                }


                // =========================================================
                // 6. wwwroot Path
                // =========================================================

                var webRootPath =
                    _environment.WebRootPath;

                if (string.IsNullOrWhiteSpace(webRootPath))
                {
                    return StatusCode(
                        500,
                        "Server wwwroot folder is not configured."
                    );
                }


                // =========================================================
                // 7. Main Admin QR Folder
                // =========================================================

                const string adminQrFolder =
                    "uploads/admin-qr";


                // =========================================================
                // 8. Domestic Folder
                // =========================================================

                var domesticFolder =
                    Path.Combine(
                        webRootPath,
                        adminQrFolder,
                        "domestic"
                    );


                // =========================================================
                // 9. International Folder
                // =========================================================

                var internationalFolder =
                    Path.Combine(
                        webRootPath,
                        adminQrFolder,
                        "international"
                    );


                // =========================================================
                // 10. Create Required Folders
                // =========================================================

                if (!Directory.Exists(domesticFolder))
                {
                    Directory.CreateDirectory(
                        domesticFolder
                    );
                }

                if (!Directory.Exists(internationalFolder))
                {
                    Directory.CreateDirectory(
                        internationalFolder
                    );
                }


                // =========================================================
                // 11. Get Existing Admin QR
                // =========================================================

                var existingAdminQr =
                    await Database.AdminQRPhotoInfos
                        .FirstOrDefaultAsync();


                // =========================================================
                // 12. Handle Domestic QR
                // =========================================================

                string? newDomesticRelativePath = null;
                string? oldDomesticRelativePath = null;

                if (obj.DomesticQRPhoto != null &&
                    obj.DomesticQRPhoto.Length > 0)
                {
                    // -----------------------------------------------------
                    // Validate extension
                    // -----------------------------------------------------

                    var domesticExtension =
                        Path.GetExtension(
                            obj.DomesticQRPhoto.FileName
                        )
                        .TrimStart('.')
                        .ToLowerInvariant();


                    var allowedExtensions =
                        new HashSet<string>(
                            StringComparer.OrdinalIgnoreCase)
                        {
                    "jpg",
                    "jpeg",
                    "png"
                        };


                    if (!allowedExtensions.Contains(
                            domesticExtension))
                    {
                        return StatusCode(
                            400,
                            "Invalid domestic QR photo format. Only JPG, JPEG and PNG are allowed."
                        );
                    }


                    // -----------------------------------------------------
                    // Generate unique filename
                    // -----------------------------------------------------

                    var domesticFileName =
                        $"{Guid.NewGuid():N}.{domesticExtension}";


                    // -----------------------------------------------------
                    // Physical path
                    // -----------------------------------------------------

                    newDomesticPhysicalPath =
                        Path.Combine(
                            domesticFolder,
                            domesticFileName
                        );


                    // -----------------------------------------------------
                    // Save new domestic QR
                    // -----------------------------------------------------

                    await using (
                        var domesticStream =
                            new FileStream(
                                newDomesticPhysicalPath,
                                FileMode.CreateNew,
                                FileAccess.Write,
                                FileShare.None))
                    {
                        await obj.DomesticQRPhoto
                            .CopyToAsync(domesticStream);
                    }


                    // -----------------------------------------------------
                    // Database path
                    // -----------------------------------------------------

                    newDomesticRelativePath =
                        $"/{adminQrFolder}/domestic/{domesticFileName}";


                    // -----------------------------------------------------
                    // Store old path
                    // -----------------------------------------------------

                    if (existingAdminQr != null)
                    {
                        oldDomesticRelativePath =
                            existingAdminQr.DomesticQRPhoto;
                    }


                    Console.WriteLine(
                        $"New Domestic QR: {newDomesticRelativePath}"
                    );
                }


                // =========================================================
                // 13. Handle International QR
                // =========================================================

                string? newInternationalRelativePath = null;
                string? oldInternationalRelativePath = null;

                if (obj.InternationalQRPhoto != null &&
                    obj.InternationalQRPhoto.Length > 0)
                {
                    // -----------------------------------------------------
                    // Validate extension
                    // -----------------------------------------------------

                    var internationalExtension =
                        Path.GetExtension(
                            obj.InternationalQRPhoto.FileName
                        )
                        .TrimStart('.')
                        .ToLowerInvariant();


                    var allowedExtensions =
                        new HashSet<string>(
                            StringComparer.OrdinalIgnoreCase)
                        {
                    "jpg",
                    "jpeg",
                    "png"
                        };


                    if (!allowedExtensions.Contains(
                            internationalExtension))
                    {
                        return StatusCode(
                            400,
                            "Invalid international QR photo format. Only JPG, JPEG and PNG are allowed."
                        );
                    }


                    // -----------------------------------------------------
                    // Generate unique filename
                    // -----------------------------------------------------

                    var internationalFileName =
                        $"{Guid.NewGuid():N}.{internationalExtension}";


                    // -----------------------------------------------------
                    // Physical path
                    // -----------------------------------------------------

                    newInternationalPhysicalPath =
                        Path.Combine(
                            internationalFolder,
                            internationalFileName
                        );


                    // -----------------------------------------------------
                    // Save new international QR
                    // -----------------------------------------------------

                    await using (
                        var internationalStream =
                            new FileStream(
                                newInternationalPhysicalPath,
                                FileMode.CreateNew,
                                FileAccess.Write,
                                FileShare.None))
                    {
                        await obj.InternationalQRPhoto
                            .CopyToAsync(internationalStream);
                    }


                    // -----------------------------------------------------
                    // Database path
                    // -----------------------------------------------------

                    newInternationalRelativePath =
                        $"/{adminQrFolder}/international/{internationalFileName}";


                    // -----------------------------------------------------
                    // Store old path
                    // -----------------------------------------------------

                    if (existingAdminQr != null)
                    {
                        oldInternationalRelativePath =
                            existingAdminQr.InternationalQRPhoto;
                    }


                    Console.WriteLine(
                        $"New International QR: {newInternationalRelativePath}"
                    );
                }


                // =========================================================
                // 14. Existing Admin QR Found
                // =========================================================

                if (existingAdminQr != null)
                {
                    // -----------------------------------------------------
                    // Update ONLY the QR types that were uploaded
                    // -----------------------------------------------------

                    if (newDomesticRelativePath != null)
                    {
                        existingAdminQr.DomesticQRPhoto =
                            newDomesticRelativePath;
                    }

                    if (newInternationalRelativePath != null)
                    {
                        existingAdminQr.InternationalQRPhoto =
                            newInternationalRelativePath;
                    }


                    // -----------------------------------------------------
                    // Save database changes
                    // -----------------------------------------------------

                    try
                    {
                        await Database.SaveChangesAsync();
                    }
                    catch
                    {
                        // Database failed.
                        // Delete newly uploaded files.

                        try
                        {
                            if (!string.IsNullOrWhiteSpace(
                                    newDomesticPhysicalPath) &&
                                System.IO.File.Exists(
                                    newDomesticPhysicalPath))
                            {
                                System.IO.File.Delete(
                                    newDomesticPhysicalPath
                                );
                            }
                        }
                        catch
                        {
                            // Ignore cleanup failure.
                        }


                        try
                        {
                            if (!string.IsNullOrWhiteSpace(
                                    newInternationalPhysicalPath) &&
                                System.IO.File.Exists(
                                    newInternationalPhysicalPath))
                            {
                                System.IO.File.Delete(
                                    newInternationalPhysicalPath
                                );
                            }
                        }
                        catch
                        {
                            // Ignore cleanup failure.
                        }

                        throw;
                    }


                    // =====================================================
                    // 15. Delete Old Domestic QR File
                    // =====================================================

                    if (newDomesticRelativePath != null &&
                        !string.IsNullOrWhiteSpace(
                            oldDomesticRelativePath))
                    {
                        try
                        {
                            var oldDomesticPhysicalPath =
                                Path.Combine(
                                    webRootPath,
                                    oldDomesticRelativePath
                                        .TrimStart('/', '\\')
                                        .Replace(
                                            '/',
                                            Path.DirectorySeparatorChar
                                        )
                                        .Replace(
                                            '\\',
                                            Path.DirectorySeparatorChar
                                        )
                                );


                            Console.WriteLine(
                                $"Old Domestic QR Physical Path: {oldDomesticPhysicalPath}"
                            );


                            if (System.IO.File.Exists(
                                    oldDomesticPhysicalPath))
                            {
                                System.IO.File.Delete(
                                    oldDomesticPhysicalPath
                                );

                                Console.WriteLine(
                                    "Old Domestic QR deleted."
                                );
                            }
                        }
                        catch (Exception ex)
                        {
                            // Database is already updated.
                            // Do not crash the API.

                            Console.WriteLine(
                                $"Old Domestic QR delete error: {ex.Message}"
                            );
                        }
                    }


                    // =====================================================
                    // 16. Delete Old International QR File
                    // =====================================================

                    if (newInternationalRelativePath != null &&
                        !string.IsNullOrWhiteSpace(
                            oldInternationalRelativePath))
                    {
                        try
                        {
                            var oldInternationalPhysicalPath =
                                Path.Combine(
                                    webRootPath,
                                    oldInternationalRelativePath
                                        .TrimStart('/', '\\')
                                        .Replace(
                                            '/',
                                            Path.DirectorySeparatorChar
                                        )
                                        .Replace(
                                            '\\',
                                            Path.DirectorySeparatorChar
                                        )
                                );


                            Console.WriteLine(
                                $"Old International QR Physical Path: {oldInternationalPhysicalPath}"
                            );


                            if (System.IO.File.Exists(
                                    oldInternationalPhysicalPath))
                            {
                                System.IO.File.Delete(
                                    oldInternationalPhysicalPath
                                );

                                Console.WriteLine(
                                    "Old International QR deleted."
                                );
                            }
                        }
                        catch (Exception ex)
                        {
                            // Database is already updated.
                            // Do not crash the API.

                            Console.WriteLine(
                                $"Old International QR delete error: {ex.Message}"
                            );
                        }
                    }


                    // =====================================================
                    // 17. Existing QR Updated Successfully
                    // =====================================================

                    return Ok(
                        "Admin QR information updated successfully."
                    );
                }


                // =========================================================
                // 18. No Existing Admin QR - Create New Row
                // =========================================================

                var newAdminQr =
                    new AdminQRPhotoModel
                    {
                        DomesticQRPhoto =
                            newDomesticRelativePath,

                        InternationalQRPhoto =
                            newInternationalRelativePath
                    };


                // =========================================================
                // 19. Add Database Entity
                // =========================================================

                await Database.AdminQRPhotoInfos
                    .AddAsync(newAdminQr);


                // =========================================================
                // 20. Save Database
                // =========================================================

                try
                {
                    await Database.SaveChangesAsync();
                }
                catch
                {
                    // Database failed.
                    // Delete newly uploaded files.

                    try
                    {
                        if (!string.IsNullOrWhiteSpace(
                                newDomesticPhysicalPath) &&
                            System.IO.File.Exists(
                                newDomesticPhysicalPath))
                        {
                            System.IO.File.Delete(
                                newDomesticPhysicalPath
                            );
                        }
                    }
                    catch
                    {
                        // Ignore cleanup failure.
                    }


                    try
                    {
                        if (!string.IsNullOrWhiteSpace(
                                newInternationalPhysicalPath) &&
                            System.IO.File.Exists(
                                newInternationalPhysicalPath))
                        {
                            System.IO.File.Delete(
                                newInternationalPhysicalPath
                            );
                        }
                    }
                    catch
                    {
                        // Ignore cleanup failure.
                    }

                    throw;
                }


                // =========================================================
                // 21. Success
                // =========================================================

                return Ok(
                    "Admin QR information added successfully."
                );
            }
            catch (Exception ex)
            {
                // =========================================================
                // 22. Unexpected Error Cleanup
                // =========================================================

                try
                {
                    if (!string.IsNullOrWhiteSpace(
                            newDomesticPhysicalPath) &&
                        System.IO.File.Exists(
                            newDomesticPhysicalPath))
                    {
                        System.IO.File.Delete(
                            newDomesticPhysicalPath
                        );
                    }
                }
                catch
                {
                    // Ignore cleanup failure.
                }


                try
                {
                    if (!string.IsNullOrWhiteSpace(
                            newInternationalPhysicalPath) &&
                        System.IO.File.Exists(
                            newInternationalPhysicalPath))
                    {
                        System.IO.File.Delete(
                            newInternationalPhysicalPath
                        );
                    }
                }
                catch
                {
                    // Ignore cleanup failure.
                }


                // =========================================================
                // 23. Server Error
                // =========================================================

                return StatusCode(
                    500,
                    $"An error occurred while saving admin QR information: {ex.Message}"
                );
            }
        }

        [Authorize(Policy = "RequireAdminProRole")]
        [HttpGet]
        [Route("getadminqr")]
        public async Task<IActionResult> GetAdminQr()
        {
            try
            {
                Console.WriteLine("========== GET ADMIN QR ==========");

                if (!ModelState.IsValid)
                {
                    return StatusCode(
                        400,
                        "Data are not in correct format."
                    );
                }

               // Get current Admin UserNumber from JWT
               var userNumberClaim =
                   User.FindFirst(ClaimTypes.NameIdentifier)?.Value;

                if (!int.TryParse(
                        userNumberClaim,
                        out int currentUserNumber))
                {
                    Console.WriteLine("Admin UserNumber not found in JWT.");

                    return Forbid();
                }

                Console.WriteLine(
                    $"Current Admin UserNumber: {currentUserNumber}"
                );

                // Check admin exists
                var CurrentUserData = await Database.UserInfos
                    .FirstOrDefaultAsync(
                        x => x.UserNumber == currentUserNumber
                    );

                if (CurrentUserData == null)
                {
                    Console.WriteLine("Admin user not found.");

                    return StatusCode(
                        404,
                        "Admin user not found."
                    );
                }

                // Check login access
                if (CurrentUserData.LoginAccess == false)
                {
                    Console.WriteLine("Admin login access is blocked.");

                    return StatusCode(
                        506,
                        "You have been blocked by System. Contact KaamMitra community."
                    );
                }

                // Get Admin QR information
                var adminQrInfo = await Database.AdminQRPhotoInfos
                    .FirstOrDefaultAsync();

                if (adminQrInfo == null)
                {
                    Console.WriteLine("Admin QR information not found.");

                    return StatusCode(
                        404,
                        "Admin QR information is not present."
                    );
                }

                Console.WriteLine(
                    $"Admin QR ID: {adminQrInfo.AdminQRID}"
                );

                Console.WriteLine(
                    $"Domestic QR: {adminQrInfo.DomesticQRPhoto}"
                );

                Console.WriteLine(
                    $"International QR: {adminQrInfo.InternationalQRPhoto}"
                );

                return Ok(adminQrInfo);
            }
            catch (Exception ex)
            {
                Console.WriteLine("========== GET ADMIN QR ERROR ==========");
                Console.WriteLine($"Error: {ex.Message}");
                Console.WriteLine($"StackTrace: {ex.StackTrace}");

                return StatusCode(
                    500,
                    $"An error occurred while getting admin QR information: {ex.Message}"
                );
            }
        }


        [Authorize(Policy = "RequireAdminRole")]
        [HttpGet]
        [Route("getalltaskcompletepayments")]
        public async Task<IActionResult> GetAllTaskCompletePayments()
        {
            try
            {
                Console.WriteLine("========== GET ALL BOOKING + TASK COMPLETE PAYMENT INFORMATION ==========");

                // 1. Admin number from JWT
                var userNumberClaim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
                if (!int.TryParse(userNumberClaim, out int currentAdminNumber))
                {
                    return Forbid();
                }

                // 2. Check admin user
                var adminUser = await Database.UserInfos
                    .FirstOrDefaultAsync(x => x.UserNumber == currentAdminNumber);

                if (adminUser == null)
                {
                    return StatusCode(404, "Admin user not found.");
                }

                // 3. Check login access
                if (adminUser.LoginAccess == false)
                {
                    return StatusCode(506, "You have been blocked by System. Contact KaamMitra community.");
                }

                // 4. Load data
                var bookingList = await Database.BookingInfos.ToListAsync();
                var paymentList = await Database.ProTaskCompletePaymentInfos.ToListAsync();
                var userList = await Database.UserInfos.ToListAsync();
                var providerServiceList = await Database.ProviderServiceInfo.ToListAsync();
                var serviceList = await Database.ServiceInfos.ToListAsync();

                Console.WriteLine($"Bookings: {bookingList.Count}");
                Console.WriteLine($"Task complete payments: {paymentList.Count}");

                var result = new List<AdminTaskCompletePaymentDTO>();

                // Local helper: entity -> flat DTO (no navigation properties serialized)
                TaskCompletePaymentInfoDTO ToPaymentDto(ProTaskCompletePaymentInfos p)
                {
                    return new TaskCompletePaymentInfoDTO
                    {
                        TaskCompletePaymentId = p.TaskCompletePaymentId,
                        BookId = p.BookId,
                        PaymentAmount = p.PaymentAmount,
                        PaymentMethod = p.PaymentMethod,
                        PaymentPhoto = p.PaymentPhoto,
                        PaymentDate = p.PaymentDate
                    };
                }

                // 5. Newest bookings first.
                //    NOTE: no early return when there are no bookings,
                //    because orphan payments must still be returned.
                var bookingIds = new HashSet<int>();
                foreach (var b in bookingList)
                {
                    bookingIds.Add((int)b.BookId);
                }

                // 6. A) EVERY booking.
                //    - no payment      -> one item with PaymentInfo = null
                //    - 1..n payments   -> one item per payment (same BookingInfo)
                foreach (var booking in bookingList.OrderByDescending(x => x.CreatedAt))
                {
                    var user = userList.FirstOrDefault(x => x.UserNumber == booking.UserNumber);
                    var provider = userList.FirstOrDefault(x => x.UserNumber == booking.ProviderNumber);

                    var providerService = providerServiceList.FirstOrDefault(
                        x => x.UserNumber == booking.ProviderNumber &&
                             x.ServiceName == booking.ServiceName);

                    var service =
                        serviceList.FirstOrDefault(x => x.ServiceId == booking.ServiceId)
                        ?? serviceList.FirstOrDefault(x => x.ServiceName == booking.ServiceName);

                    var bookingInfo = new SendBookingInfoUserDTO
                    {
                        UserAddress = user?.Address ?? "",
                        UserPhoneNumber = user?.PhoneNumber ?? "",
                        UserWhatsappPhoneNumber = user?.WhatsappPhoneNumber ?? "",

                        ProviderAddress = provider?.Address ?? "",
                        ProviderPhoneNumber = provider?.PhoneNumber ?? "",
                        ProviderWhatsappPhoneNumber = provider?.WhatsappPhoneNumber ?? "",

                        ProviderNumber = booking.ProviderNumber,
                        UserNumber = booking.UserNumber,

                        UserLatitude = user?.Latitude ?? 0,
                        UserLongitude = user?.Longitude ?? 0,
                        ProviderLatitude = provider?.Latitude ?? 0,
                        ProviderLongitude = provider?.Longitude ?? 0,

                        BookId = booking.BookId,
                        StartDate = booking.StartDate,
                        EndDate = booking.EndDate,

                        ProviderBookingDescription = booking.ProviderBookingDescription,
                        UserBookingDescription = booking.UserBookingDescription,

                        ServiceName = booking.ServiceName,
                        ProviderServiceId = providerService?.ProviderServiceId ?? 0,
                        ServiceId = booking.ServiceId,
                        Distance = booking.Distance,

                        UserEmail = user?.Email ?? "",
                        ProviderEmail = provider?.Email ?? "",

                        ProviderApprovalStatus = booking.ProviderApprovalStatus,
                        UserApprovalStatus = booking.UserApprovalStatus,
                        ProviderTaskCompleteStatus = booking.ProviderTaskCompleteStatus,
                        UserTaskCompleteStatus = booking.UserTaskCompleteStatus,

                        AdvancePaymentAmount = booking.AdvancePaymentAmount,
                        CreatedAt = booking.CreatedAt,
                        RatingValueUser = booking.RatingValueUser,
                        RequiredAdvancePayment = booking.RequiredAdvancePayment,

                        DomesticPrice = service?.DomesticPrice ?? 0,
                        DomesticPriceDiscount = service?.DomesticPriceDiscount ?? 0,
                        InternationalPrice = service?.InternationalPrice ?? 0,
                        InternationalPriceDiscount = service?.InternationalPriceDiscount ?? 0
                    };

                    var bookingPayments = paymentList
                        .Where(x => x.BookId == booking.BookId)
                        .OrderByDescending(x => x.TaskCompletePaymentId)
                        .ToList();

                    if (bookingPayments.Count == 0)
                    {
                        result.Add(new AdminTaskCompletePaymentDTO
                        {
                            BookingInfo = bookingInfo,
                            PaymentInfo = null
                        });
                    }
                    else
                    {
                        foreach (var pay in bookingPayments)
                        {
                            result.Add(new AdminTaskCompletePaymentDTO
                            {
                                BookingInfo = bookingInfo,
                                PaymentInfo = ToPaymentDto(pay)
                            });
                        }
                    }
                }

                // 6. B) ORPHAN payments (their booking no longer exists) -> still returned
                var orphanPayments = paymentList
                    .Where(p => !bookingIds.Contains((int)p.BookId))
                    .OrderByDescending(p => p.TaskCompletePaymentId)
                    .ToList();

                foreach (var pay in orphanPayments)
                {
                    result.Add(new AdminTaskCompletePaymentDTO
                    {
                        BookingInfo = null,
                        PaymentInfo = ToPaymentDto(pay)
                    });
                }

             

                return Ok(result);
            }
            catch (Exception ex)
            {
               

                return StatusCode(
                    500,
                    $"An error occurred while getting booking and task complete payment information: {ex.Message}"
                );
            }
        }




        [Authorize(Policy = "RequireAdminRole")]
        [Route("proupdatetaskcompletestatus")]
        [HttpPut]
        public async Task<IActionResult> UpdateTaskCompleteStatus([FromBody] UpdateProviderApprovalStatusDTO obj)
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


                var Data = await Database.BookingInfos
                    .FirstOrDefaultAsync(x => x.BookId == obj.BookId);
                if (Data != null)
                {
                    if (Data.ProviderTaskCompleteStatus == false)
                    {
                        Data.ProviderTaskCompleteStatus = true;
                        await Database.SaveChangesAsync();
                        return Ok();

                    }
                    else
                    {
                        Data.ProviderTaskCompleteStatus = false;
                        await Database.SaveChangesAsync();
                        return Ok();
                    }
                }
                else
                {
                    return StatusCode(503, "No booking data present of current user wmail.");
                }

            }
            catch (Exception ex)
            {
                return StatusCode(500, ex.Message);
            }
        }


        [Authorize(Policy = "RequireAdminRole")]
        [HttpDelete]
        [Route("deletebooking")]
        public async Task<IActionResult> DeleteBooking(
         [FromBody] OnlyBookingIDDTO model)
        {
            try
            {
          
                // Validate DTO
             
                if (model == null)
                {
                    return StatusCode(
                        400,
                        "Booking information is required."
                    );
                }

                if (model.BookId <= 0)
                {
                    return StatusCode(
                        400,
                        "Invalid BookId."
                    );
                }

                // Get admin number from JWT
       
                var adminNumberClaim =
                    User.FindFirst(ClaimTypes.NameIdentifier)?.Value;

                if (!int.TryParse(
                    adminNumberClaim,
                    out int currentAdminNumber))
                {
                    return Forbid();
                }

                // --------------------------------------------------
                // Check admin exists
                // --------------------------------------------------
                var adminUser = await Database.UserInfos
                    .FirstOrDefaultAsync(
                        x => x.UserNumber == currentAdminNumber
                    );

                if (adminUser == null)
                {
                    return StatusCode(
                        404,
                        "Admin user not found."
                    );
                }

            
                // Check admin login access
      
                if (adminUser.LoginAccess == false)
                {
                    return StatusCode(
                        506,
                        "You have been blocked by System. Contact KaamMitra community."
                    );
                }

                // Find booking
  
                var booking = await Database.BookingInfos
                    .FirstOrDefaultAsync(
                        x => x.BookId == model.BookId
                    );

                if (booking == null)
                {
                    return StatusCode(
                        404,
                        "Booking information not found."
                    );
                }

                var ratingList = await Database.RatingInfos
    .Where(x => x.BookId == model.BookId)
    .ToListAsync();



                // Get wwwroot path

                var webRootPath = _environment.WebRootPath;

                if (string.IsNullOrWhiteSpace(webRootPath))
                {
                    webRootPath = Path.Combine(
                        Directory.GetCurrentDirectory(),
                        "wwwroot"
                    );
                }


                // Delete booking file if present

                if (!string.IsNullOrWhiteSpace(booking.BookingFile))
                {
                    var fileRelativePath = booking.BookingFile.TrimStart('/')
                        .Replace('/', Path.DirectorySeparatorChar);

                    var physicalFilePath = Path.Combine(
                        webRootPath,
                        fileRelativePath
                    );

                    if (System.IO.File.Exists(physicalFilePath))
                    {
                        System.IO.File.Delete(physicalFilePath);
                    }
                }


                // Delete booking video if present

                if (!string.IsNullOrWhiteSpace(booking.BookingVideo))
                {
                    var videoRelativePath = booking.BookingVideo.TrimStart('/')
                        .Replace('/', Path.DirectorySeparatorChar);

                    var physicalVideoPath = Path.Combine(
                        webRootPath,
                        videoRelativePath
                    );

                    if (System.IO.File.Exists(physicalVideoPath))
                    {
                        System.IO.File.Delete(physicalVideoPath);
                    }
                }


                if (ratingList.Count > 0)
                {
                    Database.RatingInfos.RemoveRange(ratingList);
                    await Database.SaveChangesAsync();
                }

                // Delete booking from database

                Database.BookingInfos.Remove(booking);

                await Database.SaveChangesAsync();

                return StatusCode(
                    200,
                    "Booking information and its attached files deleted successfully."
                );
            }
            catch (Exception ex)
            {
                return StatusCode(
                    500,
                    $"An error occurred while deleting booking information: {ex.Message}"
                );
            }
        }



        [Authorize(Policy = "RequireAdminRole")]
        [HttpDelete]
        [Route("deletetaskcompletepayment")]
        public async Task<IActionResult> DeleteTaskCompletePayment(
      [FromBody] ProTaskComPayIDDTO model)
        {
            try
            {
               

                // =========================================================
                // 1. Check request body
                // =========================================================

                try
                {
                    if (model == null)
                    {
                        Console.WriteLine(
                            "ERROR: Request body is null."
                        );

                        return StatusCode(
                            400,
                            "Task complete payment information is required."
                        );
                    }

                  

                    if (model.TaskCompletePaymentId <= 0)
                    {
                        Console.WriteLine(
                            "ERROR: Invalid TaskCompletePaymentId."
                        );

                        return StatusCode(
                            400,
                            "Invalid TaskCompletePaymentId."
                        );
                    }
                }
                catch (Exception ex)
                {
                    

                    return StatusCode(
                        400,
                        "Invalid task complete payment information."
                    );
                }

                // =========================================================
                // 2. Get Admin Number from JWT
                // =========================================================

                int currentAdminNumber;

                try
                {
                    var adminNumberClaim =
                        User.FindFirst(ClaimTypes.NameIdentifier)?.Value;

                 

                    if (!int.TryParse(
                            adminNumberClaim,
                            out currentAdminNumber))
                    {
                        Console.WriteLine(
                            "ERROR: Invalid admin JWT."
                        );

                        return StatusCode(
                            401,
                            "Invalid admin authentication information."
                        );
                    }

                
                }
                catch (Exception ex)
                {
                   
                    return StatusCode(
                        401,
                        "Unable to verify admin authentication."
                    );
                }

                // =========================================================
                // 3. Find Admin
                // =========================================================

                UserInfo? adminUser;

                try
                {
                    adminUser = await Database.UserInfos
                        .FirstOrDefaultAsync(
                            x => x.UserNumber == currentAdminNumber
                        );

                    if (adminUser == null)
                    {
                        Console.WriteLine(
                            "ERROR: Admin user not found."
                        );

                        return StatusCode(
                            404,
                            "Admin user not found."
                        );
                    }

                 
                }
                catch (Exception ex)
                {
                   

                    return StatusCode(
                        500,
                        "Unable to verify admin information."
                    );
                }

                // =========================================================
                // 4. Check Admin Login Access
                // =========================================================

                try
                {
                    if (adminUser.LoginAccess == false)
                    {
                     

                        return StatusCode(
                            506,
                            "You have been blocked by System. Contact KaamMitra community."
                        );
                    }
                }
                catch (Exception ex)
                {
                

                    return StatusCode(
                        500,
                        "Unable to verify admin access."
                    );
                }

                // =========================================================
                // 5. Find Task Complete Payment
                // =========================================================

                ProTaskCompletePaymentInfos? paymentInfo;

                try
                {
                    paymentInfo =
                        await Database.ProTaskCompletePaymentInfos
                            .FirstOrDefaultAsync(
                                x =>
                                    x.TaskCompletePaymentId ==
                                    model.TaskCompletePaymentId
                            );

                    if (paymentInfo == null)
                    {
                        Console.WriteLine(
                            "ERROR: Task complete payment not found."
                        );

                        return StatusCode(
                            404,
                            "Task complete payment information not found."
                        );
                    }

                 
                }
                catch (Exception ex)
                {
                 

                    return StatusCode(
                        500,
                        "Unable to find task complete payment information."
                    );
                }

                // =========================================================
                // 6. Prepare physical photo path
                // =========================================================

                string? physicalPhotoPath = null;

                try
                {
                    if (!string.IsNullOrWhiteSpace(
                            paymentInfo.PaymentPhoto))
                    {
                        var webRootPath = _environment.WebRootPath;

                        if (string.IsNullOrWhiteSpace(webRootPath))
                        {
                            Console.WriteLine(
                                "WARNING: wwwroot path is not configured."
                            );

                            // Do not stop database deletion.
                            physicalPhotoPath = null;
                        }
                        else
                        {
                            var cleanRelativePath =
                                paymentInfo.PaymentPhoto
                                    .TrimStart('/', '\\')
                                    .Replace(
                                        '/',
                                        Path.DirectorySeparatorChar)
                                    .Replace(
                                        '\\',
                                        Path.DirectorySeparatorChar);

                            var calculatedPath =
                                Path.GetFullPath(
                                    Path.Combine(
                                        webRootPath,
                                        cleanRelativePath
                                    )
                                );

                            var uploadsRoot =
                                Path.GetFullPath(
                                    Path.Combine(
                                        webRootPath,
                                        "uploads"
                                    )
                                );

                            var uploadsRootWithSeparator =
                                uploadsRoot.TrimEnd(
                                    Path.DirectorySeparatorChar
                                )
                                + Path.DirectorySeparatorChar;

                            // Security check.
                            if (!calculatedPath.StartsWith(
                                    uploadsRootWithSeparator,
                                    StringComparison.OrdinalIgnoreCase))
                            {
                                Console.WriteLine(
                                    "WARNING: Payment photo is outside "
                                    + "wwwroot/uploads."
                                );

                                physicalPhotoPath = null;
                            }
                            else
                            {
                                physicalPhotoPath = calculatedPath;

                                Console.WriteLine(
                                    $"Physical photo path: "
                                    + $"{physicalPhotoPath}"
                                );
                            }
                        }
                    }
                    else
                    {
                        Console.WriteLine(
                            "PaymentPhoto is empty/null."
                        );
                    }
                }
                catch (Exception ex)
                {
                

                    // We can still delete the database record.
                    physicalPhotoPath = null;
                }

                // =========================================================
                // 7. Delete database row
                // =========================================================

                try
                {
                    Database.ProTaskCompletePaymentInfos.Remove(
                        paymentInfo
                    );

                    Console.WriteLine(
                        "Payment row marked for database deletion."
                    );
                }
                catch (Exception ex)
                {
                

                    return StatusCode(
                        500,
                        "Unable to prepare task complete payment for deletion."
                    );
                }

                // =========================================================
                // 8. Save database deletion
                // =========================================================

                try
                {
                    await Database.SaveChangesAsync();

                }
                catch (DbUpdateException ex)
                {
                    

                    return StatusCode(
                        500,
                        "Unable to delete task complete payment from database."
                    );
                }
                catch (Exception ex)
                {
                   

                    return StatusCode(
                        500,
                        "Unable to save task complete payment deletion."
                    );
                }

                // =========================================================
                // 9. Delete physical photo
                // =========================================================

                bool physicalPhotoDeleted = false;
                bool physicalPhotoAlreadyMissing = false;
                bool physicalPhotoDeleteFailed = false;

                if (!string.IsNullOrWhiteSpace(
                        physicalPhotoPath))
                {
                    try
                    {
                        if (System.IO.File.Exists(
                                physicalPhotoPath))
                        {
                            System.IO.File.Delete(
                                physicalPhotoPath
                            );

                            physicalPhotoDeleted = true;

                            Console.WriteLine(
                                "Physical payment photo deleted successfully."
                            );
                        }
                        else
                        {
                            physicalPhotoAlreadyMissing = true;

                            Console.WriteLine(
                                "Physical payment photo was not found."
                            );
                        }
                    }
                    catch (UnauthorizedAccessException ex)
                    {
                        physicalPhotoDeleteFailed = true;

                      
                    }
                    catch (IOException ex)
                    {
                        physicalPhotoDeleteFailed = true;

                      
                    }
                    catch (Exception ex)
                    {
                        physicalPhotoDeleteFailed = true;

                      
                    }
                }
                else
                {
                    Console.WriteLine(
                        "No physical payment photo path available."
                    );
                }

                // =========================================================
                // 10. Return correct success information
                // =========================================================

                try
                {
                    Console.WriteLine(
                        "========== DELETE TASK COMPLETE PAYMENT FINISHED =========="
                    );

                    if (physicalPhotoDeleted)
                    {
                        return StatusCode(
                            200,
                            "Task complete payment and payment photo deleted successfully."
                        );
                    }

                    if (physicalPhotoAlreadyMissing)
                    {
                        return StatusCode(
                            200,
                            "Task complete payment deleted successfully. Payment photo was already not available."
                        );
                    }

                    if (physicalPhotoDeleteFailed)
                    {
                        // Database deletion succeeded.
                        // File deletion failed, so don't tell the user
                        // that the entire operation failed.
                        return StatusCode(
                            200,
                            "Task complete payment deleted successfully, but the payment photo could not be deleted from the server."
                        );
                    }

                    return StatusCode(
                        200,
                        "Task complete payment deleted successfully."
                    );
                }
                catch (Exception ex)
                {
                    Console.WriteLine(
                        $"Success response preparation error: {ex.Message}"
                    );

                    // At this point database deletion already succeeded.
                    return StatusCode(
                        200,
                        "Task complete payment deleted successfully."
                    );
                }
            }
            catch (Exception ex)
            {
                // =========================================================
                // FINAL SAFETY CATCH
                // =========================================================

               

                return StatusCode(
                    500,
                    "An unexpected error occurred while deleting task complete payment."
                );
            }
        }


        [HttpPost("addfooterinfo")]
        [Authorize(Policy = "RequireAdminRole")]
        public async Task<IActionResult> AddFooterInfo([FromBody] FooterInfoModel model)
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

                // =========================
                // MODEL STATE CHECK
                // =========================
                if (!ModelState.IsValid)
                {
                    return StatusCode(400, ModelState);
                }

                // =========================
                // CHECK EXISTING FOOTER ROW
                // =========================
                var existingFooter = await Database.FooterInfos
                    .FirstOrDefaultAsync();

                // =========================
                // IF ROW EXISTS -> UPDATE
                // =========================
                if (existingFooter != null)
                {
                    existingFooter.ContactNumber = model.ContactNumber;
                    existingFooter.Address = model.Address;
                    existingFooter.Email = model.Email;
                    existingFooter.SocialMediaInfo = model.SocialMediaInfo;

                    await Database.SaveChangesAsync();

                    return Ok();
                }

                // =========================
                // IF ROW DOES NOT EXIST -> ADD
                // =========================
                var newFooter = new FooterInfoModel
                {
                    ContactNumber = model.ContactNumber,
                    Address = model.Address,
                    Email = model.Email,
                    SocialMediaInfo = model.SocialMediaInfo
                };

                await Database.FooterInfos.AddAsync(newFooter);
                await Database.SaveChangesAsync();

                return Ok();
            }
            catch (Exception ex)
            {
                return StatusCode(500, new
                {
                    message = "Something went wrong while saving footer information.",
                    error = ex.Message
                });
            }
        }

        [Authorize(Policy = "RequireAdminRole")]
        [HttpDelete]
        [Route("deleteuserinfo")]
        public async Task<IActionResult> DeleteUserInfo(
    [FromBody] UserNumberDTO obj)
        {
            string? physicalPhotoPath = null;

            try { 

                // 1. Validate ModelState


                if (!ModelState.IsValid)
                {
                    return StatusCode(
                        400,
                        "The provided data is not in correct format."
                    );
                }


                // 2. Validate admin JWT
                // RequireAdminRole validates the admin authorization first.


                var adminNumberClaim =
                    User.FindFirst(ClaimTypes.NameIdentifier)?.Value;

                if (!int.TryParse(
                    adminNumberClaim,
                    out int currentAdminNumber))
                {
                    return Forbid();
                }


                // 3. Find target user
 

                var user = await Database.UserInfos
                    .FirstOrDefaultAsync(
                        x => x.UserNumber == obj.UserNumber
                    );

                if (user == null)
                {
                    return StatusCode(404, "User not found.");
                }

                // 4. Get wwwroot path


                var webRootPath = _environment.WebRootPath;

                if (string.IsNullOrWhiteSpace(webRootPath))
                {
                    return StatusCode(
                        500,
                        "Server wwwroot folder is not configured."
                    );
                }

                // 5. Delete profile photo first
   

                if (!string.IsNullOrWhiteSpace(user.Photo))
                {
                    var photoPath = user.Photo.Trim();

                    // Accept only a profile-photo URL/path such as:
                    // /uploads/profile/707fe5a6e88143e7938430656f4e742d.png

                    var normalizedPath = photoPath.Replace('\\', '/');

                    const string allowedPrefix = "/uploads/profile/";

                    if (!normalizedPath.StartsWith(
                        allowedPrefix,
                        StringComparison.OrdinalIgnoreCase))
                    {
                        return StatusCode(
                            400,
                            "Invalid profile photo path. User data was not deleted."
                        );
                    }

                    // Only allow a filename, not nested paths or traversal.
                    var fileName = normalizedPath.Substring(
                        allowedPrefix.Length
                    );

                    if (string.IsNullOrWhiteSpace(fileName) ||
                        fileName.Contains('/') ||
                        fileName.Contains('\\') ||
                        fileName == "." ||
                        fileName == "..")
                    {
                        return StatusCode(
                            400,
                            "Invalid profile photo path. User data was not deleted."
                        );
                    }

                    var profileFolder = Path.GetFullPath(
                        Path.Combine(
                            webRootPath,
                            "uploads",
                            "profile"
                        )
                    );

                    physicalPhotoPath = Path.GetFullPath(
                        Path.Combine(
                            profileFolder,
                            fileName
                        )
                    );

                    // Ensure the resolved file stays in the profile folder.
                    var expectedPrefix =
                        profileFolder.TrimEnd(
                            Path.DirectorySeparatorChar
                        ) + Path.DirectorySeparatorChar;

                    if (!physicalPhotoPath.StartsWith(
                        expectedPrefix,
                        StringComparison.OrdinalIgnoreCase))
                    {
                        return StatusCode(
                            400,
                            "Invalid profile photo path. User data was not deleted."
                        );
                    }

                    // If the photo path exists in the database but the file
                    // is missing, stop instead of deleting the user record.
                    if (!System.IO.File.Exists(physicalPhotoPath))
                    {
                        return StatusCode(
                            500,
                            "Profile photo was not found on the server. User data was not deleted."
                        );
                    }

                    // Delete photo BEFORE deleting the database record.
                    System.IO.File.Delete(physicalPhotoPath);

                    // Verify the photo was deleted.
                    if (System.IO.File.Exists(physicalPhotoPath))
                    {
                        return StatusCode(
                            500,
                            "Failed to delete profile photo. User data was not deleted."
                        );
                    }
                }

                BlackListUsersModel BlackListUser = new BlackListUsersModel
                {
                    Email = user.Email,
                    PhoneNumber = user.PhoneNumber,
                    WhatsappPhoneNumber = user.WhatsappPhoneNumber
                };


                await Database.BlaclistUsers.AddAsync(BlackListUser);

                // Get related records
                var Msg_Data = await Database.ChatInfos
                    .Where(x => x.SenderNumber == obj.UserNumber)
                    .ToListAsync();

                var New_Msg_Status_data = await Database.NewMessageStatusInfos
                    .Where(x => x.MessageReceiverNumber == obj.UserNumber)
                    .ToListAsync();

                var Not_Data = await Database.NotificationInfos
                    .Where(x => x.ReceiverNumber == obj.UserNumber)
                    .ToListAsync();

                var New_Not_Status_Data = await Database.NewNotificationInfos
                    .Where(x => x.ReceiverNumber == obj.UserNumber)
                    .ToListAsync();

                // Delete available related records
                if (Msg_Data.Count > 0)
                {
                    Database.ChatInfos.RemoveRange(Msg_Data);
                }

                if (New_Msg_Status_data.Count > 0)
                {
                    Database.NewMessageStatusInfos.RemoveRange(New_Msg_Status_data);
                }

                if (Not_Data.Count > 0)
                {
                    Database.NotificationInfos.RemoveRange(Not_Data);
                }

                if (New_Not_Status_Data.Count > 0)
                {
                    Database.NewNotificationInfos.RemoveRange(New_Not_Status_Data);
                }

                // Delete user
                Database.UserInfos.Remove(user);

                // Save all changes together
                await Database.SaveChangesAsync();

                return Ok("User and related information deleted successfully.");

            }
            catch (Exception ex)
            {
              

                return StatusCode(
                    500,
                    $"An error occurred while deleting user data: {ex.Message}"
                );
            }
        }


        [Authorize(Policy = "RequireAdminRole")]
        [HttpGet]
        [Route("getsharedmedia")]
        public async Task<IActionResult> GetSharedMedia()
        {
            try
            {
                // 1. Extract UserNumber from JWT token
                var userNumberClaim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;

                if (string.IsNullOrEmpty(userNumberClaim) ||
                    !int.TryParse(userNumberClaim, out int UserNumber))
                {
                    return StatusCode(401, "Invalid user authentication.");
                }

                // 2. Check whether the logged-in user exists
                var userExists = await Database.UserInfos
                    .FirstOrDefaultAsync(x => x.UserNumber == UserNumber);

                if (userExists == null)
                {
                    return StatusCode(520, "User account not found.");
                }


                if (userExists.LoginAccess == false)
                {
                    return StatusCode(
                        506,
                        "You have been blocked by System. Contact the KaamMitra community."
                    );
                }

                // 3. Retrieve media where the user is sender or receiver
                var SharedMediaList = await Database.SharedMediaInfos
                    .OrderByDescending(x => x.CreatedAt)
                    .Select(x => new SendSharedMediaDTO
                    {
                        SharedMediaId = x.SharedMediaId,
                        MediaDescription = x.MediaDescription,
                        ServicePhoto = x.ServicePhoto,
                        ServiceVideo = x.ServiceVideo,
                        ServiceFile = x.ServiceFile,
                        CreatedAt = x.CreatedAt,
                        SenderNumber = x.SenderNumber,
                        ReceiverNumber = x.ReceiverNumber,
                        SenderName = Database.UserInfos
    .Where(u => u.UserNumber == x.SenderNumber)
    .Select(u => (u.FirstName + " " + u.LastName).Trim())
    .FirstOrDefault() ?? string.Empty,

                        ReceiverName = Database.UserInfos
    .Where(u => u.UserNumber == x.ReceiverNumber)
    .Select(u => (u.FirstName + " " + u.LastName).Trim())
    .FirstOrDefault() ?? string.Empty
                    })
                    .ToListAsync();

                // 4. Return shared media
                return StatusCode(200, SharedMediaList);
            }
            catch (Exception ex)
            {
                return StatusCode(500,
                    "An error occurred while retrieving shared media: " + ex.Message);
            }
        }

        [Authorize(Policy = "RequireAdminRole")]
        [HttpDelete]
        [Route("deletesharedmedia")]
        public async Task<IActionResult> DeleteSharedMedia(
  [FromBody] SharedMediaIDDTO obj)
        {
            List<string> PhysicalFilePaths = new List<string>();

            try
            {
                // 1. Validate ModelState
                if (!ModelState.IsValid)
                {
                    return StatusCode(
                        400,
                        "Invalid shared media information."
                    );
                }

                // 2. Extract UserNumber from JWT token
                var userNumberClaim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;

                if (string.IsNullOrEmpty(userNumberClaim) ||
                    !int.TryParse(userNumberClaim, out int UserNumber))
                {
                    return StatusCode(401, "Invalid user authentication.");
                }

                // 3. Check current user
                var CurrentUser = await Database.UserInfos
                    .FirstOrDefaultAsync(x => x.UserNumber == UserNumber);

                if (CurrentUser == null)
                {
                    return StatusCode(520, "User account not found.");
                }

                // 4. Check whether current user is blocked
                if (CurrentUser.LoginAccess == false)
                {
                    return StatusCode(
                        506,
                        "You have been blocked by System. Contact the KaamMitra community."
                    );
                }

                // 5. Find shared media
                var SharedMedia = await Database.SharedMediaInfos
                    .FirstOrDefaultAsync(x =>
                        x.SharedMediaId == obj.SharedMediaId);

                if (SharedMedia == null)
                {
                    return StatusCode(404, "Shared media not found.");
                }

          

                // 7. Get wwwroot directory
                string WebRootPath = _environment.WebRootPath;

                if (string.IsNullOrEmpty(WebRootPath))
                {
                    WebRootPath = Path.Combine(
                        Directory.GetCurrentDirectory(),
                        "wwwroot"
                    );
                }

                if (!Directory.Exists(WebRootPath))
                {
                    return StatusCode(
                        500,
                        "Server wwwroot folder is not configured."
                    );
                }

                // 8. Collect physical file paths
                if (!string.IsNullOrWhiteSpace(SharedMedia.ServicePhoto))
                {
                    string PhotoPath = Path.Combine(
                        WebRootPath,
                        SharedMedia.ServicePhoto.TrimStart('/')
                            .Replace('/', Path.DirectorySeparatorChar)
                    );

                    PhysicalFilePaths.Add(PhotoPath);
                }

                if (!string.IsNullOrWhiteSpace(SharedMedia.ServiceVideo))
                {
                    string VideoPath = Path.Combine(
                        WebRootPath,
                        SharedMedia.ServiceVideo.TrimStart('/')
                            .Replace('/', Path.DirectorySeparatorChar)
                    );

                    PhysicalFilePaths.Add(VideoPath);
                }

                if (!string.IsNullOrWhiteSpace(SharedMedia.ServiceFile))
                {
                    string FilePath = Path.Combine(
                        WebRootPath,
                        SharedMedia.ServiceFile.TrimStart('/')
                            .Replace('/', Path.DirectorySeparatorChar)
                    );

                    PhysicalFilePaths.Add(FilePath);
                }

                // 9. Delete physical files
                foreach (string PhysicalPath in PhysicalFilePaths)
                {
                    if (System.IO.File.Exists(PhysicalPath))
                    {
                        System.IO.File.Delete(PhysicalPath);
                    }
                }

                // 10. Delete database record after successful file deletion
                Database.SharedMediaInfos.Remove(SharedMedia);

                await Database.SaveChangesAsync();

                return StatusCode(
                    200,
                    "Shared media deleted successfully."
                );
            }
            catch (Exception ex)
            {
                return StatusCode(
                    500,
                    "An error occurred while deleting shared media: " + ex.Message
                );
            }
        }


        [Authorize(Policy = "RequireAdminRole")]
        [HttpPost]
        [Route("deleteproserviceares")]
        public async Task<IActionResult> DeleteService([FromBody] serv_res_id_DTO obj)
        {
            try
            {
                var userNumberClaim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;

                if (!int.TryParse(userNumberClaim, out int userNumber))
                    return Forbid();

                var user = await Database.UserInfos
                    .FirstOrDefaultAsync(x => x.UserNumber == userNumber);

                if (user == null)
                    return StatusCode(505, "User not found.");

                if (user.LoginAccess == false)
                    return StatusCode(506,
                        "You have been blocked by System. Contact the KaamMitra community.");

                if (obj == null)
                    return StatusCode(400, "Request data is required.");

                if (!ModelState.IsValid)
                    return StatusCode(400, "Data are not in the correct format.");

                // Null, 0 or a negative number means "not provided".
                bool hasServiceId = obj.ProviderServiceId.HasValue && obj.ProviderServiceId.Value > 0;
                bool hasResourceId = obj.ProviderServiceResourcesId.HasValue && obj.ProviderServiceResourcesId.Value > 0;

                if (hasServiceId && hasResourceId)
                    return StatusCode(512,
                        "Send only one id at a time: either ProviderServiceId or ProviderServiceResourcesId, not both.");

                if (!hasServiceId && !hasResourceId)
                    return StatusCode(400,
                        "Send ProviderServiceId or ProviderServiceResourcesId.");

                // ---- file helpers (paths must stay inside wwwroot) ----
                var webRootPath = _environment.WebRootPath;

                if (string.IsNullOrWhiteSpace(webRootPath))
                    webRootPath = Path.Combine(Directory.GetCurrentDirectory(), "wwwroot");

                webRootPath = Path.GetFullPath(webRootPath);

                var rootPrefix = Path.TrimEndingDirectorySeparator(webRootPath)
                    + Path.DirectorySeparatorChar;

                var pathComparison = OperatingSystem.IsWindows()
                    ? StringComparison.OrdinalIgnoreCase
                    : StringComparison.Ordinal;

                string? ResolvePhysicalPath(string? storedPath)
                {
                    if (string.IsNullOrWhiteSpace(storedPath))
                        return null;

                    var normalizedPath = storedPath.Trim()
                        .Replace('\\', Path.DirectorySeparatorChar)
                        .Replace('/', Path.DirectorySeparatorChar)
                        .TrimStart(Path.DirectorySeparatorChar);

                    if (string.IsNullOrWhiteSpace(normalizedPath) ||
                        Path.IsPathRooted(normalizedPath))
                        return null;

                    var physicalPath = Path.GetFullPath(Path.Combine(webRootPath, normalizedPath));

                    return physicalPath.StartsWith(rootPrefix, pathComparison)
                        ? physicalPath
                        : null;
                }

                // Deletes the files and returns true if any file could not be removed.
                bool DeleteFiles(IEnumerable<string?> storedPaths)
                {
                    var physicalFilePaths = new HashSet<string>(
                        OperatingSystem.IsWindows()
                            ? StringComparer.OrdinalIgnoreCase
                            : StringComparer.Ordinal);

                    foreach (var storedPath in storedPaths)
                    {
                        var physicalPath = ResolvePhysicalPath(storedPath);
                        if (physicalPath != null)
                            physicalFilePaths.Add(physicalPath);
                    }

                    bool incomplete = false;

                    foreach (var physicalPath in physicalFilePaths)
                    {
                        try
                        {
                            if (System.IO.File.Exists(physicalPath))
                                System.IO.File.Delete(physicalPath);
                        }
                        catch (Exception)
                        {
                            incomplete = true;
                        }
                    }

                    return incomplete;
                }

                IActionResult Done(string okMessage, string partialMessage, bool incomplete)
                {
                    return Ok(new
                    {
                        Message = incomplete ? partialMessage : okMessage,
                        FileCleanupIncomplete = incomplete
                    });
                }

                // ================= CASE 1: delete ONE resource =================
                if (hasResourceId)
                {
                    var resource = await Database.ProviderServiceResourcesInfo
                        .FirstOrDefaultAsync(x =>
                            x.ProviderServiceResourcesId == obj.ProviderServiceResourcesId);

                    if (resource == null)
                        return StatusCode(404, "Service resource is not present.");

                    var resourcePaths = new List<string?>
            {
                resource.ServicePhoto,
                resource.ServiceVideo,
                resource.ServiceFile
            };

                    Database.ProviderServiceResourcesInfo.Remove(resource);
                    await Database.SaveChangesAsync();

                    // Files are removed only after the database delete succeeded.
                    bool incompleteResource = DeleteFiles(resourcePaths);

                    return Done(
                        "Service resource deleted successfully.",
                        "Service resource record was deleted, but some physical files could not be removed.",
                        incompleteResource);
                }

                // ============ CASE 2: delete the SERVICE + all its resources ============
                var serviceData = await Database.ProviderServiceInfo
                    .FirstOrDefaultAsync(x =>
                        x.ProviderServiceId == obj.ProviderServiceId);

                if (serviceData == null)
                    return StatusCode(404, "Registered service is not present.");

                var serviceResources = await Database.ProviderServiceResourcesInfo
                    .Where(x => x.ProviderServiceId == obj.ProviderServiceId)
                    .ToListAsync();

                var servicePaths = new List<string?> { serviceData.ServiceDocument };

                foreach (var resource in serviceResources)
                {
                    if (resource == null)
                        continue;

                    servicePaths.Add(resource.ServicePhoto);
                    servicePaths.Add(resource.ServiceVideo);
                    servicePaths.Add(resource.ServiceFile);
                }

                if (serviceResources.Count > 0)
                    Database.ProviderServiceResourcesInfo.RemoveRange(serviceResources);

                Database.ProviderServiceInfo.Remove(serviceData);

                await Database.SaveChangesAsync();

                bool incompleteService = DeleteFiles(servicePaths);

                return Done(
                    "Registered service and all associated resources deleted successfully.",
                    "Service and resource records were deleted, but some physical files could not be removed.",
                    incompleteService);
            }
            catch (Exception)
            {
                return StatusCode(500,
                    "An error occurred while deleting the registered service or resource.");
            }
        }


        [Authorize(Policy = "RequireAdminRole")]
        [HttpPost]
        [Route("getuserlinkedresources")]
        public async Task<IActionResult> GetUserLinkedResources(
            [FromBody] UserNumberDTO obj)
        {
            try
            {
                // Validate Admin JWT claim.
                var userNumberClaim =
                    User.FindFirst(ClaimTypes.NameIdentifier)?.Value;

                if (!int.TryParse(userNumberClaim, out int adminUserNumber))
                    return Forbid();

                // Validate Admin account.
                var admin = await Database.UserInfos
                    .FirstOrDefaultAsync(x => x.UserNumber == adminUserNumber);

                if (admin == null)
                    return StatusCode(505, "Admin account not found.");

                if (admin.LoginAccess == false)
                    return StatusCode(
                        506,
                        "You have been blocked by System. Contact the KaamMitra community.");

                // Validate request data.
                if (obj == null)
                    return StatusCode(400, "Request data is required.");

                if (!ModelState.IsValid)
                    return StatusCode(400, "Data are not in the correct format.");

                if (obj.UserNumber <= 0)
                    return StatusCode(400, "Valid UserNumber is required.");

                // Verify requested user exists.
                var userExists = await Database.UserInfos
                    .AnyAsync(x => x.UserNumber == obj.UserNumber);

                if (!userExists)
                    return StatusCode(404, "User not found.");

                // Retrieve provider service IDs.
                var providerServiceIds = await Database.ProviderServiceInfo
                    .Where(x => x.UserNumber == obj.UserNumber)
                    .Select(x => x.ProviderServiceId)
                    .ToListAsync();

                // Retrieve provider service resource IDs.
                var providerServiceResourceIds = await Database.ProviderServiceResourcesInfo
                    .Where(x => x.UserNumber == obj.UserNumber)
                    .Select(x => x.ProviderServiceResourcesId)
                    .ToListAsync();

                // Retrieve notification IDs.
                var notificationIds = await Database.NotificationInfos
                    .Where(x => x.ReceiverNumber == obj.UserNumber)
                    .Select(x => x.NotId)
                    .ToListAsync();

                // Retrieve booking IDs.
                var bookingIds = await Database.BookingInfos
                    .Where(x => x.UserNumber == obj.UserNumber)
                    .Select(x => x.BookId)
                    .ToListAsync();

                // Retrieve rating IDs linked to the user's bookings.
                var ratingIds = await Database.RatingInfos
                    .Where(x => bookingIds.Contains(x.BookId))
                    .Select(x => x.RtingId)
                    .ToListAsync();

                // Retrieve advance payment IDs linked to the user's bookings.
                var advancePaymentIds = await Database.AdvancePaymentInfos
                    .Where(x => bookingIds.Contains(x.BookId))
                    .Select(x => x.PaymentId)
                    .ToListAsync();



                // Retrieve new notification IDs.
                var newNotificationIds = await Database.NewNotificationInfos
                    .Where(x => x.ReceiverNumber == obj.UserNumber)
                    .Select(x => x.NewNotId)
                    .ToListAsync();

                // Retrieve advance payment QR IDs.
                var advancePaymentQrIds = await Database.AdvancePaymentQrInfos
                    .Where(x => x.ProviderNumber == obj.UserNumber)
                    .Select(x => x.QRId)
                    .ToListAsync();

                // Retrieve chat IDs.
                var chatIds = await Database.ChatInfos
                    .Where(x => x.SenderNumber == obj.UserNumber)
                    .Select(x => x.ChatId)
                    .ToListAsync();

                // Retrieve new message status IDs.
                var newMessageStatusIds = await Database.NewMessageStatusInfos
                    .Where(x => x.MessageReceiverNumber == obj.UserNumber)
                    .Select(x => x.NewMsgId)
                    .ToListAsync();

                // Retrieve shared media IDs.
                var sharedMediaIds = await Database.SharedMediaInfos
                    .Where(x => x.SenderNumber == obj.UserNumber)
                    .Select(x => x.SharedMediaId)
                    .ToListAsync();

                // Prepare linked resource response.
                var result = new UserLinkedResourcesDTO
                {
                    ProviderServiceInfo = string.Join("&", providerServiceIds),
                    ProviderServiceResourcesInfo = string.Join("&", providerServiceResourceIds),
                    NotificationInfos = string.Join("&", notificationIds),
                    BookingInfos = string.Join("&", bookingIds),
                    RatingInfos = string.Join("&", ratingIds),
                    AdvancePaymentInfos = string.Join("&", advancePaymentIds),
                    NewNotificationInfos = string.Join("&", newNotificationIds),
                    AdvancePaymentQrInfos = string.Join("&", advancePaymentQrIds),
                    ChatInfos = string.Join("&", chatIds),
                    NewMessageStatusInfos = string.Join("&", newMessageStatusIds),
                    SharedMediaInfos = string.Join("&", sharedMediaIds)
                };

                return Ok(result);
            }
            catch (Exception)
            {
                return StatusCode(
                    500,
                    "An error occurred while retrieving user linked resources.");
            }
        }

       




























    }
}
