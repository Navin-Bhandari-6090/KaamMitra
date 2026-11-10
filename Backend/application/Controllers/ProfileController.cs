using application.Data;
using application.Models;
using application.Models.DTOModels;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.RateLimiting;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using System.Reflection;
using System.Security.Claims;
using System.Security.Cryptography;
using System.Text;

namespace application.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class ProfileController : ControllerBase
    {

        public DatabaseController Database { get; set; }
        private readonly IWebHostEnvironment _environment;

        public ProfileController(DatabaseController Database,IWebHostEnvironment Environment)
        {
            this.Database = Database;
            this._environment = Environment;


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
                    return StatusCode(500);
                }


                var user = await Database.UserInfos
                    .FirstOrDefaultAsync(x => x.UserNumber == currentUserNumber);

                if (user == null)
                {

                    return StatusCode(500, "User not found");
                }


                if (user.LoginAccess == false)
                {
                    return StatusCode(500, "You have been blocked by System.Contact to KaamMitra community.");
                }

                var user_data = await Database.UserInfos
                    .FirstOrDefaultAsync(x => x.UserNumber == currentUserNumber);

                if (user_data != null)
                {
   

                    UserInfoProfileScreenDTO user_info = new UserInfoProfileScreenDTO
                    {
                        UserNumber = user_data.UserNumber,
                        FirstName = user_data.FirstName,
                        LastName = user_data.LastName,
                        Email = user_data.Email,
                        Address = user_data.Address,
                        PhoneNumber = user_data.PhoneNumber,
                        WhatsappPhoneNumber = user_data.WhatsappPhoneNumber,
                        Latitude = user_data.Latitude,
                        Longitude = user_data.Longitude,
                        Photo = user_data.Photo,
                        Role = user_data.Role,
                        LoginAccess = (bool)user_data.LoginAccess,
                        Status=(bool)user_data.Status
                        
                    };

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



        [Authorize(Policy = "RequireProviderUserRole")]
        [HttpPut]
        [Route("updateprofilephoto")]
        public async Task<IActionResult> UpdateProfilePhoto(
     [FromForm] UserProviderPhoto obj)
        {
            try
            {
                // =========================================================
                // 1. Validate ModelState
                // =========================================================

                if (!ModelState.IsValid)
                {
                    return StatusCode(
                        400,
                        "The provided data is not in correct format."
                    );
                }

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


                // =========================================================
                // 2. Find user
                // =========================================================

                var userData = await Database.UserInfos
                    .FirstOrDefaultAsync(x => x.UserNumber == currentUserNumber);

                if (userData == null)
                {
                    return StatusCode(
                        404,
                        "No user found."
                    );
                }


                // =========================================================
                // 3. Validate photo
                // =========================================================

                if (obj.Photo == null || obj.Photo.Length == 0)
                {
                    return StatusCode(
                        400,
                        "Photo is empty."
                    );
                }


                // =========================================================
                // 4. Validate extension
                // =========================================================

                var extension = obj.PhotoExtension
                    .Trim()
                    .ToLowerInvariant();

                if (extension.StartsWith("."))
                {
                    extension = extension.Substring(1);
                }

                var allowedExtensions = new HashSet<string>(
                    StringComparer.OrdinalIgnoreCase)
        {
            "jpg",
            "jpeg",
            "png"
        };

                if (!allowedExtensions.Contains(extension))
                {
                    return StatusCode(
                        400,
                        "Invalid photo format. Only JPG, JPEG and PNG are allowed."
                    );
                }


                // =========================================================
                // 5. Photo folder
                // =========================================================

                const string photoFolder = "uploads/profile";


                // =========================================================
                // 6. Get wwwroot
                // =========================================================

                var webRootPath = _environment.WebRootPath;

                if (string.IsNullOrWhiteSpace(webRootPath))
                {
                    return StatusCode(
                        500,
                        "Server wwwroot folder is not configured."
                    );
                }


                // =========================================================
                // 7. Create physical folder
                // =========================================================

                var physicalFolderPath = Path.Combine(
                    webRootPath,
                    photoFolder.Replace(
                        '/',
                        Path.DirectorySeparatorChar
                    )
                );

                if (!Directory.Exists(physicalFolderPath))
                {
                    Directory.CreateDirectory(
                        physicalFolderPath
                    );
                }


                // =========================================================
                // 8. Generate unique filename
                // =========================================================

                var fileName =
                    $"{Guid.NewGuid():N}.{extension}";


                // =========================================================
                // 9. Physical file path
                // =========================================================

                var newPhysicalFilePath = Path.Combine(
                    physicalFolderPath,
                    fileName
                );


                // =========================================================
                // 10. Save new photo
                // =========================================================

                await using (var fileStream = new FileStream(
                    newPhysicalFilePath,
                    FileMode.CreateNew,
                    FileAccess.Write,
                    FileShare.None))
                {
                    await obj.Photo.CopyToAsync(fileStream);
                }


                // =========================================================
                // 11. Store relative path
                // =========================================================

                var relativePhotoPath =
                    $"/{photoFolder}/{fileName}";


                // =========================================================
                // 12. Keep old photo path
                // =========================================================

                var oldPhotoPath = userData.Photo;


                // =========================================================
                // 13. Update database
                // =========================================================

                userData.Photo = relativePhotoPath;


                try
                {
                    await Database.SaveChangesAsync();
                }
                catch
                {
                    // Database update failed.
                    // Delete newly uploaded photo.

                    try
                    {
                        if (System.IO.File.Exists(
                            newPhysicalFilePath))
                        {
                            System.IO.File.Delete(
                                newPhysicalFilePath
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
                // 14. Delete old photo
                // =========================================================

                if (!string.IsNullOrWhiteSpace(oldPhotoPath))
                {
                    try
                    {
                        var oldRelativePath =
                            oldPhotoPath
                                .TrimStart('/')
                                .TrimStart('\\');

                        var oldPhysicalFilePath = Path.Combine(
                            webRootPath,
                            oldRelativePath.Replace(
                                '/',
                                Path.DirectorySeparatorChar
                            )
                        );

                        if (System.IO.File.Exists(
                            oldPhysicalFilePath))
                        {
                            System.IO.File.Delete(
                                oldPhysicalFilePath
                            );
                        }
                    }
                    catch
                    {
                        // Do not fail successful update
                        // if old photo cannot be deleted.
                    }
                }


                // =========================================================
                // 15. Success
                // =========================================================

                return Ok();
            }
            catch (Exception ex)
            {
                // =========================================================
                // 16. Server error
                // =========================================================

                return StatusCode(
                    500,
                    $"An error occurred while updating profile photo: {ex.Message}"
                );
            }
        }



     
        [Authorize(Policy = "RequireProviderRole")]
        [HttpPost]
        [Route("addservice")]
        public async Task<IActionResult> AddService(
    [FromForm] ProviderServicesDTO obj)
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

                string? currentUserEmail =
    User.FindFirst(ClaimTypes.Email)?.Value;

                if (string.IsNullOrWhiteSpace(currentUserEmail))
                {
                    return Forbid();
                }

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
                // 2. Validate service name
                // =========================================================

                if (string.IsNullOrWhiteSpace(obj.ServiceName))
                {
                    return StatusCode(
                        400,
                        "ServiceName is required."
                    );
                }


                // =========================================================
                // 3. Validate email
                // =========================================================

                if (string.IsNullOrWhiteSpace(obj.Email))
                {
                    return StatusCode(
                        400,
                        "Email is required."
                    );
                }


                // =========================================================
                // 4. Validate document
                // =========================================================

                if (obj.ServiceDocument == null ||
                    obj.ServiceDocument.Length == 0)
                {
                    return StatusCode(
                        400,
                        "Service document is required."
                    );
                }


                // =========================================================
                // 5. Check duplicate service
                // =========================================================

                var serviceExists =
                    await Database.ProviderServiceInfo
                        .AnyAsync(x =>
                            x.UserNumber == currentUserNumber &&
                            x.ServiceName == obj.ServiceName);

                if (serviceExists)
                {
                    return StatusCode(
                        409,
                        "Current user service already registered in that service."
                    );
                }


                // =========================================================
                // 6. Get document extension
                // =========================================================

                var extension =
                    Path.GetExtension(
                        obj.ServiceDocument.FileName
                    )
                    .TrimStart('.')
                    .ToLowerInvariant();


                // =========================================================
                // 7. Allowed document extensions
                // =========================================================

                var allowedExtensions =
                    new HashSet<string>(
                        StringComparer.OrdinalIgnoreCase)
                    {
                "pdf"
                    };

                if (!allowedExtensions.Contains(extension))
                {
                    return StatusCode(
                        400,
                        "Invalid document format. Only PDF files are allowed."
                    );
                }


                // =========================================================
                // 8. Document folder
                // =========================================================

                const string documentFolder =
                    "uploads/service-documents";


                // =========================================================
                // 9. Get wwwroot
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
                // 10. Create physical folder
                // =========================================================

                var physicalFolderPath =
                    Path.Combine(
                        webRootPath,
                        documentFolder.Replace(
                            '/',
                            Path.DirectorySeparatorChar
                        )
                    );

                if (!Directory.Exists(
                    physicalFolderPath))
                {
                    Directory.CreateDirectory(
                        physicalFolderPath
                    );
                }


                // =========================================================
                // 11. Generate unique filename
                // =========================================================

                var fileName =
                    $"{Guid.NewGuid():N}.{extension}";


                // =========================================================
                // 12. Physical file path
                // =========================================================

                var physicalFilePath =
                    Path.Combine(
                        physicalFolderPath,
                        fileName
                    );


                // =========================================================
                // 13. Save document
                // =========================================================

                await using (var fileStream =
                    new FileStream(
                        physicalFilePath,
                        FileMode.CreateNew,
                        FileAccess.Write,
                        FileShare.None))
                {
                    await obj.ServiceDocument
                        .CopyToAsync(fileStream);
                }


                // =========================================================
                // 14. Database relative path
                // =========================================================

                var relativeDocumentPath =
                    $"/{documentFolder}/{fileName}";


                ////Finding user
                //var User_Data = await Database.UserInfos.FirstOrDefaultAsync(x => x.Email == obj.Email);



                // =========================================================
                // 15. Create entity
                // =========================================================

                var service =
                    new ProviderRegisterServices
                    {
                        ServiceName =
                            obj.ServiceName.Trim(),

                        ServiceDocument =
                            relativeDocumentPath,

                        UserNumber=currentUserNumber,

                        ProRegServiceDescription=obj.ProRegServiceDescription
                        

                    };


                // =========================================================
                // 16. Insert entity
                // =========================================================

                await Database.ProviderServiceInfo
                    .AddAsync(service);


                // =========================================================
                // 17. Save database
                // =========================================================

                try
                {
                    await Database.SaveChangesAsync();
                }
                catch
                {
                    // Database failed.
                    // Delete uploaded document.

                    try
                    {
                        if (System.IO.File.Exists(
                            physicalFilePath))
                        {
                            System.IO.File.Delete(
                                physicalFilePath
                            );
                        }
                    }
                    catch
                    {
                        // Ignore cleanup failure.
                    }

                    throw;
                }

                return Ok();
;

            }
            catch (Exception ex)
            {
                // =========================================================
                // 19. Server error
                // =========================================================

                return StatusCode(
                    500,
                    $"An error occurred while adding service: {ex.Message}"
                );
            }
        }

        [Authorize(Policy = "RequireProviderRole")]
        [HttpPost]
        [Route("getserviceinfo")]
        public async Task<IActionResult> GetServiceInfo([FromBody] UserEmailInfoModel obj)
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

                string? currentUserEmail =
    User.FindFirst(ClaimTypes.Email)?.Value;

                if (string.IsNullOrWhiteSpace(currentUserEmail))
                {
                    return StatusCode(500, "No user found.");
                }


                    var Service_Data = await Database.ServiceInfos.OrderBy(x => x.ServiceName).ToListAsync();
                    return Ok(Service_Data);

             
            }
            catch (Exception ex)
            {
                return StatusCode(501, ex.Message);
            }
        }





        [Authorize(Policy = "")]
        [HttpPost]
        [RequestSizeLimit(2_147_483_648)]
        [RequestFormLimits(MultipartBodyLengthLimit = 2_147_483_648)]
        [Route("addserviceresources")]
        public async Task<IActionResult> AddServiceResources(
            [FromForm] ProviderServiceResourcesDTO obj)
        {
            string? physicalPhotoPath = null;
            string? physicalVideoPath = null;
            string? physicalFilePath = null;

            try
            {
                // Validate required fields.
                if (obj == null)
                {
                    return StatusCode(400, "Service resource information is required.");
                }

                if (string.IsNullOrWhiteSpace(obj.ServiceTitle))
                {
                    return StatusCode(400, "Service title is required.");
                }

                if (obj.ServiceFile == null || obj.ServiceFile.Length == 0)
                {
                    return StatusCode(400, "Service file is required.");
                }

                if (obj.ProviderServiceId <= 0)
                {
                    return StatusCode(400, "ProviderServiceId is required.");
                }

                if (!ModelState.IsValid)
                {
                    return StatusCode(400, "The provided data is not in the correct format.");
                }

                // Get the authenticated provider number.
                var userNumberClaim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;

                if (!int.TryParse(userNumberClaim, out int currentUserNumber))
                {
                    return StatusCode(401, "Invalid provider authentication.");
                }

                // Check provider account.
                var user = await Database.UserInfos
                    .FirstOrDefaultAsync(x => x.UserNumber == currentUserNumber);

                if (user == null)
                {
                    return StatusCode(502, "Provider account not found.");
                }

                if (user.LoginAccess == false)
                {
                    return StatusCode(
                        506,
                        "You have been blocked by System. Contact the KaamMitra community."
                    );
                }

                // Check that the service belongs to the authenticated provider.
                var serviceData = await Database.ProviderServiceInfo
                    .FirstOrDefaultAsync(x =>
                        x.ProviderServiceId == obj.ProviderServiceId &&
                        x.UserNumber == currentUserNumber);

                if (serviceData == null)
                {
                    return StatusCode(
                        404,
                        "Service not found or does not belong to the current provider."
                    );
                }

                // Enforce the existing maximum of three resources per service.
                var serviceResources = await Database.ProviderServiceResourcesInfo
                    .Where(x =>
                        x.ProviderServiceId == obj.ProviderServiceId &&
                        x.UserNumber == currentUserNumber)
                    .ToListAsync();

                if (serviceResources.Count >= 3)
                {
                    return StatusCode(
                        508,
                        "You can only add a maximum of 3 resources for this service."
                    );
                }

                // Resolve the wwwroot directory.
                var webRootPath = _environment.WebRootPath;

                if (string.IsNullOrWhiteSpace(webRootPath))
                {
                    webRootPath = Path.Combine(
                        Directory.GetCurrentDirectory(),
                        "wwwroot"
                    );
                }

                // Create the upload folders.
                var photoFolder = Path.Combine(
                    webRootPath,
                    "uploads",
                    "service-resources",
                    "photos"
                );

                var videoFolder = Path.Combine(
                    webRootPath,
                    "uploads",
                    "service-resources",
                    "videos"
                );

                var fileFolder = Path.Combine(
                    webRootPath,
                    "uploads",
                    "service-resources",
                    "files"
                );

                Directory.CreateDirectory(photoFolder);
                Directory.CreateDirectory(videoFolder);
                Directory.CreateDirectory(fileFolder);

                string? relativePhotoPath = null;
                string? relativeVideoPath = null;
                string? relativeFilePath = null;

                // Save the optional photo when provided.
                if (obj.ServicePhoto != null && obj.ServicePhoto.Length > 0)
                {
                    var photoExtension = Path.GetExtension(obj.ServicePhoto.FileName);
                    var photoFileName = $"{Guid.NewGuid():N}{photoExtension}";

                    physicalPhotoPath = Path.Combine(photoFolder, photoFileName);

                    await using (var photoStream = new FileStream(
                        physicalPhotoPath,
                        FileMode.CreateNew,
                        FileAccess.Write,
                        FileShare.None))
                    {
                        await obj.ServicePhoto.CopyToAsync(photoStream);
                    }

                    relativePhotoPath =
                        $"/uploads/service-resources/photos/{photoFileName}";
                }

                // Save the optional video when provided.
                if (obj.ServiceVideo != null && obj.ServiceVideo.Length > 0)
                {
                    var videoExtension = Path.GetExtension(obj.ServiceVideo.FileName);
                    var videoFileName = $"{Guid.NewGuid():N}{videoExtension}";

                    physicalVideoPath = Path.Combine(videoFolder, videoFileName);

                    await using (var videoStream = new FileStream(
                        physicalVideoPath,
                        FileMode.CreateNew,
                        FileAccess.Write,
                        FileShare.None))
                    {
                        await obj.ServiceVideo.CopyToAsync(videoStream);
                    }

                    relativeVideoPath =
                        $"/uploads/service-resources/videos/{videoFileName}";
                }

                // Save the mandatory service file.
                var fileExtension = Path.GetExtension(obj.ServiceFile.FileName);
                var serviceFileName = $"{Guid.NewGuid():N}{fileExtension}";

                physicalFilePath = Path.Combine(fileFolder, serviceFileName);

                await using (var serviceFileStream = new FileStream(
                    physicalFilePath,
                    FileMode.CreateNew,
                    FileAccess.Write,
                    FileShare.None))
                {
                    await obj.ServiceFile.CopyToAsync(serviceFileStream);
                }

                relativeFilePath =
                    $"/uploads/service-resources/files/{serviceFileName}";

                // Create the database entity.
                var serviceResource = new ProviderRegisterServiceResources
                {
                    ServiceTitle = obj.ServiceTitle.Trim(),
                    ServiceFile = relativeFilePath,
                    ServicePhoto = relativePhotoPath ?? string.Empty,
                    ServiceVideo = relativeVideoPath ?? string.Empty,
                    ProviderServiceId = obj.ProviderServiceId,
                    UserNumber = currentUserNumber
                };

                await Database.ProviderServiceResourcesInfo.AddAsync(serviceResource);

                // Save the resource record.
                await Database.SaveChangesAsync();

                return Ok();
            }
            catch (Exception)
            {
                // Remove uploaded files if the operation fails.
                try
                {
                    if (!string.IsNullOrWhiteSpace(physicalPhotoPath) &&
                        System.IO.File.Exists(physicalPhotoPath))
                    {
                        System.IO.File.Delete(physicalPhotoPath);
                    }

                    if (!string.IsNullOrWhiteSpace(physicalVideoPath) &&
                        System.IO.File.Exists(physicalVideoPath))
                    {
                        System.IO.File.Delete(physicalVideoPath);
                    }

                    if (!string.IsNullOrWhiteSpace(physicalFilePath) &&
                        System.IO.File.Exists(physicalFilePath))
                    {
                        System.IO.File.Delete(physicalFilePath);
                    }
                }
                catch
                {
                    // Preserve the original operation failure.
                }

                return StatusCode(
                    500,
                    "An error occurred while adding service resources."
                );
            }
        }



        // NEW: hashes all new and changed passwords
        private static string HashPassword(string password) =>
            BCrypt.Net.BCrypt.HashPassword(password, 12);


        [Authorize(Policy = "RequireProviderUserRole")]
        [EnableRateLimiting("auth")]
        [HttpPut]
        [Route("updatepassword")]
        public async Task<IActionResult> UpdatePassword([FromBody] LoginModel obj)
        {
            try
            {
                if (!ModelState.IsValid)
                    return BadRequest("Password must be between 8 and 72 characters.");

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

                string? currentUserEmail =
    User.FindFirst(ClaimTypes.Email)?.Value;

                if (string.IsNullOrWhiteSpace(currentUserEmail))
                {
                    return Forbid();
                }


        

                var user_data = await Database.UserInfos
                    .FirstOrDefaultAsync(x => x.Email.ToLower() == currentUserEmail);

                if (user_data == null || !(bool)user_data.LoginAccess)
                    return Forbid();

                user_data.Password = HashPassword(obj.Password);
                await Database.SaveChangesAsync();
                return Ok();
            }
            catch (Exception ex)
            {
                return StatusCode(500, "Something went wrong. Please try again.");
            }
        }



        [Authorize(Policy = "RequireProviderRole")]
        [HttpPut]
        [Route("updateservicedocument")]
        public async Task<IActionResult> UpdateServiceFile(
      [FromForm] UpdateServiceFile obj)
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

                string? currentUserEmail =
    User.FindFirst(ClaimTypes.Email)?.Value;

                if (string.IsNullOrWhiteSpace(currentUserEmail))
                {
                    return Forbid();
                }
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
                // 2. Validate document
                // =========================================================

                if (obj.ServiceDocument == null ||
                    obj.ServiceDocument.Length == 0)
                {
                    return StatusCode(
                        400,
                        "Service document is required."
                    );
                }

                // =========================================================
                // 3. Check user
                // =========================================================

                //var userData = await Database.UserInfos
                //    .FirstOrDefaultAsync(x =>
                //        x.Email == obj.Email);

                //if (userData == null)
                //{
                //    return StatusCode(
                //        404,
                //        "User not found."
                //    );
                //}

                // =========================================================
                // 4. Check service belongs to this user
                // =========================================================

                var serviceData =
                    await Database.ProviderServiceInfo
                        .FirstOrDefaultAsync(x =>
                            x.UserNumber == currentUserNumber &&
                            x.ProviderServiceId ==
                                obj.ProviderServiceId);

                if (serviceData == null)
                {
                    return StatusCode(
                        404,
                        "No service available."
                    );
                }

                // =========================================================
                // 5. Get wwwroot
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
                // 6. Document folder
                // =========================================================

                const string documentFolder =
                    "uploads/service-documents";

                // =========================================================
                // 7. Physical folder path
                // =========================================================

                var physicalFolderPath =
                    Path.Combine(
                        webRootPath,
                        documentFolder.Replace(
                            '/',
                            Path.DirectorySeparatorChar
                        )
                    );

                // =========================================================
                // 8. Create folder if it doesn't exist
                // =========================================================

                if (!Directory.Exists(physicalFolderPath))
                {
                    Directory.CreateDirectory(
                        physicalFolderPath
                    );
                }

                // =========================================================
                // 9. Get extension
                // =========================================================

                var extension =
                    Path.GetExtension(
                        obj.ServiceDocument.FileName
                    )
                    .TrimStart('.')
                    .ToLowerInvariant();

                // =========================================================
                // 10. Generate new unique filename
                // =========================================================

                var fileName =
                    $"{Guid.NewGuid():N}.{extension}";

                // =========================================================
                // 11. Physical file path
                // =========================================================

                var physicalFilePath =
                    Path.Combine(
                        physicalFolderPath,
                        fileName
                    );

                // =========================================================
                // 12. Save new document to server disk
                // =========================================================

                await using (var fileStream =
                    new FileStream(
                        physicalFilePath,
                        FileMode.CreateNew,
                        FileAccess.Write,
                        FileShare.None))
                {
                    await obj.ServiceDocument
                        .CopyToAsync(fileStream);
                }

                // =========================================================
                // 13. New relative database path
                // =========================================================

                var relativeDocumentPath =
                    $"/{documentFolder}/{fileName}";

                // =========================================================
                // 14. Get old document path
                // =========================================================

                var oldDocumentPath =
                    serviceData.ServiceDocument;

                // =========================================================
                // 15. Update database path
                // =========================================================

                serviceData.ServiceDocument =
                    relativeDocumentPath;

                // =========================================================
                // 16. Save database
                // =========================================================

                try
                {
                    await Database.SaveChangesAsync();
                }
                catch
                {
                    // Database update failed.
                    // Delete newly uploaded document.

                    try
                    {
                        if (System.IO.File.Exists(
                            physicalFilePath))
                        {
                            System.IO.File.Delete(
                                physicalFilePath
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
                // 17. Delete old document
                // =========================================================

                if (!string.IsNullOrWhiteSpace(oldDocumentPath))
                {
                    var oldPhysicalPath =
                        Path.Combine(
                            webRootPath,
                            oldDocumentPath
                                .TrimStart('/')
                                .Replace(
                                    '/',
                                    Path.DirectorySeparatorChar
                                )
                        );

                    try
                    {
                        if (System.IO.File.Exists(
                            oldPhysicalPath))
                        {
                            System.IO.File.Delete(
                                oldPhysicalPath
                            );
                        }
                    }
                    catch
                    {
                        // Ignore old file deletion failure.
                    }
                }

                // =========================================================
                // 18. Success
                // =========================================================

                return StatusCode(
                    200,
                    "Service document updated successfully."
                );
            }
            catch (Exception ex)
            {
                // =========================================================
                // 19. Server error
                // =========================================================

                return StatusCode(
                    500,
                    $"An error occurred while updating service document: {ex.Message}"
                );
            }
        }


        [Authorize(Policy = "RequireProviderRole")]
        [HttpPut]
        [Route("updateserviceresourcesphoto")]
        public async Task<IActionResult> UpdateServiceResourcesPhoto(
          [FromForm] UpdateServiceResPhoto obj)
        {
            string? physicalPhotoPath = null;

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
                // 2. Validate Email
                // =========================================================

         

                // =========================================================
                // 3. Validate ProviderServiceId
                // =========================================================

                if (obj.ProviderServiceId <= 0)
                {
                    return StatusCode(
                        400,
                        "ProviderServiceId is required."
                    );
                }

                // =========================================================
                // 4. Validate ProviderServiceResourcesId
                // =========================================================

                if (obj.ProviderServiceResourcesId <= 0)
                {
                    return StatusCode(
                        400,
                        "ProviderServiceResourcesId is required."
                    );
                }

                // =========================================================
                // 5. Validate Photo
                // =========================================================

                if (obj.ServicePhoto == null ||
                    obj.ServicePhoto.Length == 0)
                {
                    return StatusCode(
                        400,
                        "Service photo is required."
                    );
                }

                // =========================================================
                // 6. Check User
                // =========================================================

                var userData = await Database.UserInfos
                    .FirstOrDefaultAsync(x =>
                        x.UserNumber == currentUserNumber);

                if (userData == null)
                {
                    return StatusCode(
                        404,
                        "User not found."
                    );
                }

                // =========================================================
                // 7. Check Service Resource
                // =========================================================

                var resourceData =
                    await Database.ProviderServiceResourcesInfo
                        .FirstOrDefaultAsync(x =>
                            x.ProviderServiceResourcesId ==
                                obj.ProviderServiceResourcesId &&
                            x.ProviderServiceId ==
                                obj.ProviderServiceId &&
                            x.UserNumber == currentUserNumber);

                if (resourceData == null)
                {
                    return StatusCode(
                        404,
                        "Service resource not found or current user does not own this resource."
                    );
                }

                // =========================================================
                // 8. Get wwwroot
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
                // 9. Photo folder
                // =========================================================

                const string photoFolder =
                    "uploads/service-resources/photos";

                // =========================================================
                // 10. Physical photo folder
                // =========================================================

                var physicalPhotoFolderPath =
                    Path.Combine(
                        webRootPath,
                        photoFolder.Replace(
                            '/',
                            Path.DirectorySeparatorChar
                        )
                    );

                // =========================================================
                // 11. Create folder
                // =========================================================

                if (!Directory.Exists(
                    physicalPhotoFolderPath))
                {
                    Directory.CreateDirectory(
                        physicalPhotoFolderPath
                    );
                }

                // =========================================================
                // 12. Get photo extension
                // =========================================================

                var extension =
                    Path.GetExtension(
                        obj.ServicePhoto.FileName
                    )
                    .TrimStart('.')
                    .ToLowerInvariant();

                // =========================================================
                // 13. Generate new unique filename
                // =========================================================

                var photoFileName =
                    $"{Guid.NewGuid():N}.{extension}";

                // =========================================================
                // 14. Physical new photo path
                // =========================================================

                physicalPhotoPath =
                    Path.Combine(
                        physicalPhotoFolderPath,
                        photoFileName
                    );

                // =========================================================
                // 15. Save new photo to server disk
                // =========================================================

                await using (var photoStream =
                    new FileStream(
                        physicalPhotoPath,
                        FileMode.CreateNew,
                        FileAccess.Write,
                        FileShare.None))
                {
                    await obj.ServicePhoto
                        .CopyToAsync(photoStream);
                }

                // =========================================================
                // 16. Store old database path
                // =========================================================

                var oldPhotoPath =
                    resourceData.ServicePhoto;

                // =========================================================
                // 17. New relative database path
                // =========================================================

                var relativePhotoPath =
                    $"/{photoFolder}/{photoFileName}";

                // =========================================================
                // 18. Update database path
                // =========================================================

                resourceData.ServicePhoto =
                    relativePhotoPath;

                // =========================================================
                // 19. Save database
                // =========================================================

                try
                {
                    await Database.SaveChangesAsync();
                }
                catch
                {
                    // Database failed.
                    // Delete newly uploaded photo.

                    try
                    {
                        if (System.IO.File.Exists(
                            physicalPhotoPath))
                        {
                            System.IO.File.Delete(
                                physicalPhotoPath
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
                // 20. Delete old photo
                // =========================================================

                if (!string.IsNullOrWhiteSpace(oldPhotoPath))
                {
                    var oldPhysicalPhotoPath =
                        Path.Combine(
                            webRootPath,
                            oldPhotoPath
                                .TrimStart('/')
                                .Replace(
                                    '/',
                                    Path.DirectorySeparatorChar
                                )
                        );

                    try
                    {
                        if (System.IO.File.Exists(
                            oldPhysicalPhotoPath))
                        {
                            System.IO.File.Delete(
                                oldPhysicalPhotoPath
                            );
                        }
                    }
                    catch
                    {
                        // Ignore old photo deletion failure.
                    }
                }

                // =========================================================
                // 21. Success
                // =========================================================

                return StatusCode(
                    200,
                    "Service resource photo updated successfully."
                );
            }
            catch (Exception ex)
            {
                // =========================================================
                // 22. Cleanup new photo if unexpected error occurs
                // =========================================================

                try
                {
                    if (!string.IsNullOrWhiteSpace(
                            physicalPhotoPath) &&
                        System.IO.File.Exists(
                            physicalPhotoPath))
                    {
                        System.IO.File.Delete(
                            physicalPhotoPath
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
                    $"An error occurred while updating service resource photo: {ex.Message}"
                );
            }
        }



        [Authorize(Policy = "RequireProviderRole")]
        [HttpPut]
        [Route("updateserviceresourcesvideo")]
        public async Task<IActionResult> UpdateServiceResourcesVideo(
            [FromForm] UpdateResVideoDTO obj)
        {
            string? newVideoPhysicalPath = null;

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
                // 3. Validate ProviderServiceId
                // =========================================================

                if (obj.ProviderServiceId <= 0)
                {
                    return StatusCode(
                        400,
                        "ProviderServiceId is required."
                    );
                }

                // =========================================================
                // 4. Validate ProviderServiceResourcesId
                // =========================================================

                if (obj.ProviderServiceResourcesId <= 0)
                {
                    return StatusCode(
                        400,
                        "ProviderServiceResourcesId is required."
                    );
                }

                // =========================================================
                // 5. Validate video exists
                // =========================================================

                if (obj.ServiceVideo == null ||
                    obj.ServiceVideo.Length == 0)
                {
                    return StatusCode(
                        400,
                        "Service video is required."
                    );
                }

                // =========================================================
                // 7. Find existing service resource
                // =========================================================

                var resourceData =
                    await Database.ProviderServiceResourcesInfo
                        .FirstOrDefaultAsync(x =>
                            x.ProviderServiceResourcesId ==
                                obj.ProviderServiceResourcesId
                            &&
                            x.ProviderServiceId ==
                                obj.ProviderServiceId
                            &&
                            x.UserNumber == currentUserNumber
                        );

                if (resourceData == null)
                {
                    return StatusCode(
                        404,
                        "Service resource not found or you do not own this resource."
                    );
                }

                // =========================================================
                // 8. Check wwwroot
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
                // 9. Video folder
                // =========================================================

                const string videoFolder =
                    "uploads/service-resources/videos";

                var physicalVideoFolderPath =
                    Path.Combine(
                        webRootPath,
                        videoFolder.Replace(
                            '/',
                            Path.DirectorySeparatorChar
                        )
                    );

                // =========================================================
                // 10. Create folder if necessary
                // =========================================================

                if (!Directory.Exists(
                        physicalVideoFolderPath))
                {
                    Directory.CreateDirectory(
                        physicalVideoFolderPath
                    );
                }

                // =========================================================
                // 11. Get extension only for filename
                // =========================================================

                // This is NOT validation.
                // Frontend is responsible for extension validation.

                var extension =
                    Path.GetExtension(
                        obj.ServiceVideo.FileName
                    );

                extension =
                    extension.TrimStart('.')
                        .ToLowerInvariant();

                // =========================================================
                // 12. Generate unique filename
                // =========================================================

                var videoFileName =
                    $"{Guid.NewGuid():N}.{extension}";

                newVideoPhysicalPath =
                    Path.Combine(
                        physicalVideoFolderPath,
                        videoFileName
                    );

                // =========================================================
                // 13. Save new video to disk
                // =========================================================

                await using (
                    var videoStream =
                        new FileStream(
                            newVideoPhysicalPath,
                            FileMode.CreateNew,
                            FileAccess.Write,
                            FileShare.None
                        ))
                {
                    await obj.ServiceVideo.CopyToAsync(
                        videoStream
                    );
                }

                // =========================================================
                // 14. Save old database path
                // =========================================================

                var oldVideoPath =
                    resourceData.ServiceVideo;

                // =========================================================
                // 15. Create new relative path
                // =========================================================

                var relativeVideoPath =
                    $"/{videoFolder}/{videoFileName}";

                // =========================================================
                // 16. Update database entity
                // =========================================================

                resourceData.ServiceVideo =
                    relativeVideoPath;

                // =========================================================
                // 17. Save database
                // =========================================================

                try
                {
                    await Database.SaveChangesAsync();
                }
                catch
                {
                    // =====================================================
                    // DB failed -> delete newly uploaded video
                    // =====================================================

                    try
                    {
                        if (!string.IsNullOrWhiteSpace(
                                newVideoPhysicalPath)
                            &&
                            System.IO.File.Exists(
                                newVideoPhysicalPath))
                        {
                            System.IO.File.Delete(
                                newVideoPhysicalPath
                            );
                        }
                    }
                    catch
                    {
                        // Ignore cleanup error
                    }

                    throw;
                }

                // =========================================================
                // 18. Delete old video
                // =========================================================

                if (!string.IsNullOrWhiteSpace(
                        oldVideoPath))
                {
                    var oldPhysicalVideoPath =
                        Path.Combine(
                            webRootPath,
                            oldVideoPath
                                .TrimStart('/')
                                .Replace(
                                    '/',
                                    Path.DirectorySeparatorChar
                                )
                        );

                    try
                    {
                        if (System.IO.File.Exists(
                                oldPhysicalVideoPath))
                        {
                            System.IO.File.Delete(
                                oldPhysicalVideoPath
                            );
                        }
                    }
                    catch
                    {
                        // Do not fail successful DB update
                        // because old-file cleanup failed.
                    }
                }

                // =========================================================
                // 19. Success
                // =========================================================

                return StatusCode(
                    200,
                    "Service resource video updated successfully."
                );
            }
            catch (Exception ex)
            {
                // =========================================================
                // Delete newly uploaded video if exception occurred
                // =========================================================

                try
                {
                    if (!string.IsNullOrWhiteSpace(
                            newVideoPhysicalPath)
                        &&
                        System.IO.File.Exists(
                            newVideoPhysicalPath))
                    {
                        System.IO.File.Delete(
                            newVideoPhysicalPath
                        );
                    }
                }
                catch
                {
                    // Ignore cleanup error
                }

                // =========================================================
                // Server error
                // =========================================================

                return StatusCode(
                    500,
                    $"An error occurred while updating service resource video: {ex.Message}"
                );
            }
        }




        [Authorize(Policy = "RequireProviderUserRole")]
        [HttpPost]
        [Route("getservicephotoinfo")]
        public async Task<IActionResult> GetServicePhotoInfo(
            [FromBody] ProviderServiceEmailServiceNameModel obj)
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
                // 2. Validate Email
                // =========================================================

                if (string.IsNullOrWhiteSpace(obj.Email))
                {
                    return StatusCode(
                        400,
                        "Email is required."
                    );
                }

                obj.Email = obj.Email.Trim();

                // =========================================================
                // 3. Validate ServiceName
                // =========================================================

                if (string.IsNullOrWhiteSpace(obj.ServiceName))
                {
                    return StatusCode(
                        400,
                        "Service name is required."
                    );
                }

                obj.ServiceName = obj.ServiceName.Trim();

                var User_Data = await Database.UserInfos.FirstOrDefaultAsync(x => x.Email == obj.Email);

                if (User_Data == null)
                {
                    return StatusCode(404);
                }

                var Provider_User_Nuber = User_Data.UserNumber;



                var servicePhotos =
    await (
        from service in Database.ProviderServiceInfo
        join resource in Database.ProviderServiceResourcesInfo
            on service.ProviderServiceId equals resource.ProviderServiceId
        where service.UserNumber == Provider_User_Nuber
              && service.ServiceName == obj.ServiceName
        select new SendServicePhoto
        {
            ServiceName = service.ServiceName,

            ProviderServiceResourcesId =
                resource.ProviderServiceResourcesId,

            ServicePhoto =
                resource.ServicePhoto,

            ProviderServiceId =
                resource.ProviderServiceId,

            ServiceTitle=resource.ServiceTitle
        }
    ).ToListAsync();

                // =========================================================
                // 6. Check resources
                // =========================================================

                if (servicePhotos.Count == 0)
                {
                    return StatusCode(
                        404,
                        "No service resources found for the current user."
                    );
                }

                // =========================================================
                // 7. Return service photos
                // =========================================================

                return StatusCode(
                    200,
                    servicePhotos
                );
            }
            catch (Exception ex)
            {
                // =========================================================
                // 8. Exception
                // =========================================================

                return StatusCode(
                    500,
                    $"An error occurred while getting service photos: {ex.Message}"
                );
            }
        }

        [Authorize(Policy = "RequireProviderUserRole")]
        [HttpPost]
        [Route("getserviceresourcesfileinfo")]
        public async Task<IActionResult> GetServiceResourcesFileInfo(
    [FromBody] ProviderServiceEmailServiceNameModel obj)
        {
            try
            {
                if (obj == null)
                {
                    return StatusCode(
                        400,
                        "Request data is required."
                    );
                }

                var userNumberClaim =
                    User.FindFirst(ClaimTypes.NameIdentifier)?.Value;

                if (!int.TryParse(userNumberClaim, out int currentUserNumber))
                {
                    return StatusCode(
                        401,
                        "Invalid user authentication."
                    );
                }

                var user = await Database.UserInfos
                    .FirstOrDefaultAsync(x => x.UserNumber == currentUserNumber);

                if (user == null)
                {
                    return StatusCode(404, "User not found.");
                }

                if (user.LoginAccess == false)
                {
                    return StatusCode(
                        403,
                        "You have been blocked by System. Contact the KaamMitra community."
                    );
                }

                if (!ModelState.IsValid)
                {
                    return StatusCode(
                        400,
                        "Data are not in the correct format."
                    );
                }

                if (string.IsNullOrWhiteSpace(obj.Email))
                {
                    return StatusCode(400, "Email is required.");
                }

                if (string.IsNullOrWhiteSpace(obj.ServiceName))
                {
                    return StatusCode(400, "Service name is required.");
                }

                obj.Email = obj.Email.Trim();
                obj.ServiceName = obj.ServiceName.Trim();

                var userData = await Database.UserInfos
                    .FirstOrDefaultAsync(x => x.Email == obj.Email);

                if (userData == null)
                {
                    return StatusCode(404, "User not found for the provided email.");
                }

                var providerUserNumber = userData.UserNumber;

                var serviceResourceFiles = await (
                    from service in Database.ProviderServiceInfo
                    join resource in Database.ProviderServiceResourcesInfo
                        on service.ProviderServiceId equals resource.ProviderServiceId
                    where service.UserNumber == providerUserNumber
                          && service.ServiceName == obj.ServiceName
                    select new SendServResouFileDTO
                    {
                        ServiceName = service.ServiceName,
                        ProviderServiceResourcesId =
                            resource.ProviderServiceResourcesId,
                        ResourceFile = resource.ServiceFile,
                        ProviderServiceId = resource.ProviderServiceId,
                        ServiceTitle = resource.ServiceTitle
                    }
                ).ToListAsync();

                if (serviceResourceFiles.Count == 0)
                {
                    return StatusCode(
                        404,
                        "No service resource files found for the specified service."
                    );
                }

                return Ok(serviceResourceFiles);
            }
            catch (Exception)
            {
                return StatusCode(
                    500,
                    "An error occurred while getting service resource file information."
                );
            }
        }


        [Authorize(Policy = "RequireProviderUserRole")]
        [HttpPost]
        [Route("getproviderregisterserviceinfo")]
        public async Task<IActionResult> GetProviderServiceInfo(
            [FromBody] UserEmailInfoModel obj)
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

                var User_Data = await Database.UserInfos.FirstOrDefaultAsync(x=>x.Email==obj.Email);

                var Provider_User_Nuber = User_Data.UserNumber;

                var Service_Data = await Database.ProviderServiceInfo
                    .Where(x => x.UserNumber == Provider_User_Nuber)
                    .Select(x => new
                    {
                        ServiceName = x.ServiceName,
                        ServiceID = x.ProviderServiceId,
                        ProRegServiceDescription=x.ProRegServiceDescription
                    })
                    .OrderBy(x => x.ServiceName)
                    .ToListAsync();

                if (Service_Data.Count > 0)
                {
                    return Ok(Service_Data);
                }
                else
                {
                    return NotFound("No service registered for current user.");
                }
            }
            catch (Exception ex)
            {
                return StatusCode(500, ex.Message);
            }
        }


        [Authorize(Policy = "RequireProviderUserRole")]
        [HttpPost]
        [Route("getservicefileinfo")]
        public async Task<IActionResult> GetServiceFileInfo(
            [FromBody] ProviderServiceEmailServiceNameModel obj)
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
                // ============================================================
                // 1. VALIDATE MODEL
                // ============================================================

                if (!ModelState.IsValid)
                {
                    return StatusCode(
                        400,
                        "The provided data is not in correct format."
                    );
                }

                // ============================================================
                // 2. VALIDATE EMAIL
                // ============================================================

                if (string.IsNullOrWhiteSpace(obj.Email))
                {
                    return StatusCode(
                        400,
                        "Email is required."
                    );
                }

                obj.Email = obj.Email.Trim();

                // ============================================================
                // 3. VALIDATE SERVICE NAME
                // ============================================================

                if (string.IsNullOrWhiteSpace(obj.ServiceName))
                {
                    return StatusCode(
                        400,
                        "Service name is required."
                    );
                }

                obj.ServiceName = obj.ServiceName.Trim();



                var User_Data = await Database.UserInfos.FirstOrDefaultAsync(x => x.Email == obj.Email);
                if (User_Data == null)
                {
                    return StatusCode(404);
                }

                var Provider_User_Nuber = User_Data.UserNumber;

                // ============================================================
                // 5. GET SERVICE FILE
                // ============================================================

                var serviceFiles = await Database.ProviderServiceInfo
                    .Where(x =>
                        x.UserNumber == Provider_User_Nuber &&
                        x.ServiceName == obj.ServiceName
                    )
                    .Select(x => new SendServDocumentDTO
                    {
                        ProviderServiceId =
                            x.ProviderServiceId,

                        ServiceName =
                            x.ServiceName,

                        ServiceDocument =
                            x.ServiceDocument
                    })
                    .ToListAsync();

                // ============================================================
                // 6. CHECK SERVICE
                // ============================================================

                if (serviceFiles.Count == 0)
                {
                    return StatusCode(
                        404,
                        "No service found for the current user."
                    );
                }

                // ============================================================
                // 7. CHECK DOCUMENT PATH
                // ============================================================

                var validFiles = serviceFiles
                    .Where(x =>
                        !string.IsNullOrWhiteSpace(
                            x.ServiceDocument
                        )
                    )
                    .ToList();

                if (validFiles.Count == 0)
                {
                    return StatusCode(
                        404,
                        "No service document found."
                    );
                }

                // ============================================================
                // 8. RETURN FILE PATH
                // ============================================================

                return StatusCode(
                    200,
                    validFiles
                );
            }
            catch (Exception ex)
            {
                // ============================================================
                // 9. EXCEPTION
                // ============================================================

                return StatusCode(
                    500,
                    $"An error occurred while getting service file: {ex.Message}"
                );
            }
        }




        [Authorize(Policy = "RequireProviderUserRole")]
        [HttpPost]
        [Route("getservicevideoinfo")]
        public async Task<IActionResult> GetServiceVideoInfo(
            [FromBody] ProviderServiceEmailServiceNameModel obj)
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
                // 3. Validate ServiceName
                // =========================================================

                if (string.IsNullOrWhiteSpace(obj.ServiceName))
                {
                    return StatusCode(
                        400,
                        "Service name is required."
                    );
                }

                obj.ServiceName = obj.ServiceName.Trim();


                var User_Data = await Database.UserInfos.FirstOrDefaultAsync(x => x.Email == obj.Email);
                if (User_Data == null)
                {
                    return StatusCode(404);
                }

                var Provider_User_Nuber = User_Data.UserNumber;

                var serviceVideos =
    await (
        from service in Database.ProviderServiceInfo
        join resource in Database.ProviderServiceResourcesInfo
            on service.ProviderServiceId equals resource.ProviderServiceId
        where service.UserNumber == Provider_User_Nuber
              && service.ServiceName == obj.ServiceName
        select new SendResVideoDTO
        {
            ServiceName =
                service.ServiceName,

            ProviderServiceResourcesId =
                resource.ProviderServiceResourcesId,

            ServiceVideo =
                resource.ServiceVideo,

            ProviderServiceId =
                resource.ProviderServiceId,


            ServiceTitle = resource.ServiceTitle
        }
    ).ToListAsync();

                // =========================================================
                // 6. Check resources
                // =========================================================

                if (serviceVideos.Count == 0)
                {
                    return StatusCode(
                        404,
                        "No service videos found for the current user."
                    );
                }

                // =========================================================
                // 7. Return service videos
                // =========================================================

                return StatusCode(
                    200,
                    serviceVideos
                );
            }
            catch (Exception ex)
            {
                // =========================================================
                // 8. Exception
                // =========================================================

                return StatusCode(
                    500,
                    $"An error occurred while getting service videos: {ex.Message}"
                );
            }
        }



        [Authorize(Policy = "RequireProviderUserRole")]
        [HttpPut]
        [Route("updateemail")]
        public async Task<IActionResult> UpdateEmail([FromBody] UpdateEmailDTO obj)
        {
            try
            {
                if (!ModelState.IsValid) 
                {
                    return StatusCode(501, "Details are not in correct format.");
                }


                var userNumberClaim =
User.FindFirst(ClaimTypes.NameIdentifier)?.Value;

                if (!int.TryParse(userNumberClaim, out int currentUserNumber))
                {
                    return StatusCode(502);
                }


                var user = await Database.UserInfos
                    .FirstOrDefaultAsync(x => x.UserNumber == currentUserNumber);

                if (user == null)
                {

                    return StatusCode(502, "User not found");
                }


                if (user.LoginAccess == false)
                {
                    return StatusCode(502, "You have been blocked by System.Contact to KaamMitra community.");
                }

             
                    user.Email = obj.NewEmail;
                    await Database.SaveChangesAsync();
                    return Ok("Update success.");
            

            }
            catch (Exception e) {

                return StatusCode(500
                    ,
                    new
                    {
                        message = "Exception caught while updating email.",
                        error = e.Message
                    }
                    );
            }
            }


        [Authorize(Policy = "RequireProviderUserRole")]
        [HttpPut]
        [Route("updatelocation")]
        public async Task<IActionResult> UpdateUserLocation([FromBody] Update_Loccation_DTO obj)
        {
            try
            {

                if (!ModelState.IsValid)
                {
                    return StatusCode(501, "Details are not in correct format.");
                }


                var userNumberClaim =
User.FindFirst(ClaimTypes.NameIdentifier)?.Value;

                if (!int.TryParse(userNumberClaim, out int currentUserNumber))
                {
                    return StatusCode(502);
                }


                var user = await Database.UserInfos
                    .FirstOrDefaultAsync(x => x.UserNumber == currentUserNumber);

                if (user == null)
                {

                    return StatusCode(502, "User not found");
                }


                if (user.LoginAccess == false)
                {
                    return StatusCode(502, "You have been blocked by System.Contact to KaamMitra community.");
                }




                user.Latitude = obj.Latitude;
                user.Longitude = obj.Longitude;
                    await Database.SaveChangesAsync();
                    return Ok("Location Update success.");


            }
            catch (Exception e)
            {

                return StatusCode(500, "Exception caught while updating location.");
            }
        }


        [Authorize(Policy = "RequireProviderUserRole")]
        [HttpPut]
        [Route("updateusername")]
        public async Task<IActionResult> UpdateUserName([FromBody] Update_UserName_DTO obj)
        {
            try
            {

                if (!ModelState.IsValid)
                {
                    return StatusCode(501, "Details are not in correct format.");
                }


                var userNumberClaim =
User.FindFirst(ClaimTypes.NameIdentifier)?.Value;

                if (!int.TryParse(userNumberClaim, out int currentUserNumber))
                {
                    return StatusCode(502);
                }


                var user = await Database.UserInfos
                    .FirstOrDefaultAsync(x => x.UserNumber == currentUserNumber);

                if (user == null)
                {

                    return StatusCode(502, "User not found");
                }


                if (user.LoginAccess == false)
                {
                    return StatusCode(502, "You have been blocked by System.Contact to KaamMitra community.");
                }



                    user.FirstName = obj.FirstName;
                user.LastName = obj.LastName;
                    await Database.SaveChangesAsync();
                    return Ok("Username Update success.");

            }
            catch (Exception e)
            {

                return StatusCode(500, "Exception caught while updating username.");
            }
        }


        [Authorize(Policy = "RequireProviderRole")]
        [HttpPost]
        [RequestSizeLimit(104857600)] // 100 MB
        [RequestFormLimits(MultipartBodyLengthLimit = 104857600)]
        [Route("addfonepayqr")]
        public async Task<IActionResult> AddFonepayQr(
       [FromForm] AdvancePaymentQRInfoModelDTO obj)

        {



            string? physicalQrPhotoPath = null;
            string? newRelativeQrPhotoPath = null;

            try
            {


                var userNumberClaim =
       User.FindFirst(ClaimTypes.NameIdentifier)?.Value;

                if (string.IsNullOrEmpty(userNumberClaim))
                {
                    return Forbid();
                }

                int CurrentUserNumber;

                if (!int.TryParse(userNumberClaim, out CurrentUserNumber))
                {
                    return Forbid();
                }

                Console.WriteLine($"UserNumber: {CurrentUserNumber}");

                var user = await Database.UserInfos
                    .FirstOrDefaultAsync(x => x.UserNumber == CurrentUserNumber);

                if (user == null)
                {

                    return StatusCode(404, "User not found");
                }


                if (user.LoginAccess == false)
                {
                    return StatusCode(506, "You have been blocked by System.Contact to KaamMitra community.");
                }

                string CurrentUserEmail = user.Email;

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
                // 3. Validate QR Photo
                // =========================================================

                if (obj.QRPhoto == null ||
                    obj.QRPhoto.Length == 0)
                {
                    return StatusCode(
                        400,
                        "QR photo is required."
                    );
                }



                // =========================================================
                // 7. Get Existing Fonepay QR
                // =========================================================

                var existingQr =
                    await Database.AdvancePaymentQrInfos
                        .FirstOrDefaultAsync(
                            x => x.ProviderNumber == CurrentUserNumber
                        );



                // =========================================================
                // 8. Main Folder
                // =========================================================

                const string qrFolder =
                    "uploads/advance-payment-qr";


                // =========================================================
                // 9. Get wwwroot
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
                // 10. Physical QR Folder
                // =========================================================

                var physicalQrFolderPath =
                    Path.Combine(
                        webRootPath,
                        qrFolder.Replace(
                            '/',
                            Path.DirectorySeparatorChar
                        )
                    );


                // =========================================================
                // 11. Create QR Folder
                // =========================================================

                if (!Directory.Exists(
                        physicalQrFolderPath))
                {
                    Directory.CreateDirectory(
                        physicalQrFolderPath
                    );
                }


                // =========================================================
                // 12. Get Uploaded Extension
                // =========================================================

                var qrExtension =
                    Path.GetExtension(
                        obj.QRPhoto.FileName)
                    .TrimStart('.')
                    .ToLowerInvariant();


                // =========================================================
                // 13. Validate QR Extension
                // =========================================================

                var allowedExtensions =
                    new HashSet<string>(
                        StringComparer.OrdinalIgnoreCase)
                    {
                "jpg",
                "jpeg",
                "png"
                    };

                if (!allowedExtensions.Contains(
                        qrExtension))
                {
                    return StatusCode(
                        400,
                        "Invalid QR photo format. Only JPG, JPEG and PNG are allowed."
                    );
                }


                // =========================================================
                // 14. Generate Unique Filename
                // =========================================================

                var qrFileName =
                    $"{Guid.NewGuid():N}.{qrExtension}";


                // =========================================================
                // 15. Physical QR Photo Path
                // =========================================================

                physicalQrPhotoPath =
                    Path.Combine(
                        physicalQrFolderPath,
                        qrFileName
                    );


                // =========================================================
                // 16. Save New QR Photo
                // =========================================================

                await using (
                    var qrStream =
                        new FileStream(
                            physicalQrPhotoPath,
                            FileMode.CreateNew,
                            FileAccess.Write,
                            FileShare.None))
                {
                    await obj.QRPhoto
                        .CopyToAsync(qrStream);
                }


                // =========================================================
                // 17. Database QR Photo Path
                // =========================================================

                newRelativeQrPhotoPath =
                    $"/{qrFolder}/{qrFileName}";


                // =========================================================
                // 18. Existing QR Found
                // =========================================================

                if (existingQr != null)
                {
                    // -----------------------------------------------------
                    // Store old database path
                    // -----------------------------------------------------

                    var oldQrPhotoPath =
                        existingQr.QRPhoto;


                    // -----------------------------------------------------
                    // Update existing database row
                    // -----------------------------------------------------

                    existingQr.ProviderNumber =
                        CurrentUserNumber;

                    existingQr.QRPhoto =
                        newRelativeQrPhotoPath;


                    // -----------------------------------------------------
                    // Save database
                    // -----------------------------------------------------

                    try
                    {
                        await Database.SaveChangesAsync();
                    }
                    catch
                    {
                        // Database update failed.
                        // Delete newly uploaded QR photo.

                        try
                        {
                            if (System.IO.File.Exists(
                                    physicalQrPhotoPath))
                            {
                                System.IO.File.Delete(
                                    physicalQrPhotoPath
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
                    // 19. Delete Old QR Photo
                    // =====================================================

                    try
                    {
                        if (!string.IsNullOrWhiteSpace(
                                oldQrPhotoPath))
                        {
                            var oldPhysicalPath =
                                Path.Combine(
                                    webRootPath,
                                    oldQrPhotoPath
                                        .TrimStart('/')
                                        .Replace(
                                            '/',
                                            Path.DirectorySeparatorChar
                                        )
                                );

                            if (System.IO.File.Exists(
                                    oldPhysicalPath))
                            {
                                System.IO.File.Delete(
                                    oldPhysicalPath
                                );
                            }
                        }
                    }
                    catch
                    {
                        // Database is already updated.
                        // Ignore old file cleanup failure.
                    }


                    // =====================================================
                    // 20. Return Updated
                    // =====================================================

                    return StatusCode(
                        200
                    );
                }


                // =========================================================
                // 21. No Existing QR - Create New Row
                // =========================================================

                var newQr =
                    new AdvancePaymentQrInfoModel
                    {
                        

                        ProviderNumber =
                            CurrentUserNumber,

                        QRPhoto =
                            newRelativeQrPhotoPath
                    };


                // =========================================================
                // 22. Add Database Entity
                // =========================================================

                await Database
                    .AdvancePaymentQrInfos
                    .AddAsync(newQr);


                // =========================================================
                // 23. Save Database
                // =========================================================

                try
                {
                    await Database.SaveChangesAsync();
                }
                catch
                {
                    // Database save failed.
                    // Delete uploaded QR photo.

                    try
                    {
                        if (System.IO.File.Exists(
                                physicalQrPhotoPath))
                        {
                            System.IO.File.Delete(
                                physicalQrPhotoPath
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
                // 24. Success
                // =========================================================

                return StatusCode(
                    200

                );
            }
            catch (Exception ex)
            {
                // =========================================================
                // 25. Cleanup Unexpected Error
                // =========================================================

                try
                {
                    if (!string.IsNullOrWhiteSpace(
                            physicalQrPhotoPath) &&
                        System.IO.File.Exists(
                            physicalQrPhotoPath))
                    {
                        System.IO.File.Delete(
                            physicalQrPhotoPath
                        );
                    }
                }
                catch
                {
                    // Ignore cleanup failure.
                }


                // =========================================================
                // 26. Server Error
                // =========================================================

                return StatusCode(
                    500,
                    $"An error occurred while saving Fonepay QR photo: {ex.Message}"
                );
            }
        }


        [Authorize(Policy = "RequireProviderUserRole")]
        [HttpPut]
        [Route("updateaddress")]
        public async Task<IActionResult> UpdateAddress([FromBody] UpdateAddressDTO obj)
        {
            try
            {

                var userNumberClaim =
User.FindFirst(ClaimTypes.NameIdentifier)?.Value;

                if (!int.TryParse(userNumberClaim, out int currentUserNumber))
                {
                    return StatusCode(502);
                }


                var user = await Database.UserInfos
                    .FirstOrDefaultAsync(x => x.UserNumber == currentUserNumber);

                if (user == null)
                {

                    return StatusCode(502, "User not found");
                }


                if (user.LoginAccess == false)
                {
                    return StatusCode(502, "You have been blocked by System.Contact to KaamMitra community.");
                }
                if (!ModelState.IsValid)
                {
                    return StatusCode(501, "Details are not in correct format.");
                }

               
                    user.Address = obj.Address;
                    await Database.SaveChangesAsync();
                    return Ok("Address Update success.");

            }
            catch (Exception e)
            {

                return StatusCode(500, "Exception caught while updating address.");
            }
        }

        [HttpPut("updatedescription")]
        [Authorize(Policy = "RequireProviderRole")]
        public async Task<IActionResult> UpdateProviderServiceDescription(
    [FromBody] ProServDescpDTO model)
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
                // FIND SERVICE BELONGING TO PROVIDER
                // =========================
                var providerService = await Database.ProviderServiceInfo
                    .FirstOrDefaultAsync(x =>
                        x.ProviderServiceId == model.ProviderServiceId &&
                        x.UserNumber == currentUserNumber);

                // =========================
                // SERVICE NOT FOUND
                // =========================
                if (providerService == null)
                {
                    return StatusCode(404, new
                    {
                        message = "Provider service not found."
                    });
                }

                // =========================
                // UPDATE DESCRIPTION
                // =========================
                providerService.ProRegServiceDescription =
                    model.ProRegServiceDescription;

                await Database.SaveChangesAsync();

                return Ok();
            }
            catch (Exception ex)
            {
                return StatusCode(500, new
                {
                    message = "Something went wrong while updating provider service description.",
                    error = ex.Message
                });
            }
        }

        [Authorize(Policy = "RequireProviderRole")]
        [HttpPut]
        [RequestSizeLimit(2_147_483_648)]
        [RequestFormLimits(MultipartBodyLengthLimit = 2_147_483_648)]
        [Route("updateserviceresourcefile")]
        public async Task<IActionResult> UpdateServiceResourceFile(
    [FromForm] ResouIDFILEDTO obj)
        {
            string? newPhysicalFilePath = null;
            bool databaseUpdated = false;

            try
            {
                // 1. Validate the request.
                if (obj == null)
                {
                    return StatusCode(
                        400,
                        "Service resource information is required."
                    );
                }

                if (obj.ProviderServiceResourcesId <= 0)
                {
                    return StatusCode(
                        400,
                        "A valid service resource ID is required."
                    );
                }

                if (obj.ServiceFile == null || obj.ServiceFile.Length == 0)
                {
                    return StatusCode(
                        400,
                        "Please select a valid service file to upload."
                    );
                }

                if (!ModelState.IsValid)
                {
                    return StatusCode(
                        400,
                        "The provided data is not in the correct format."
                    );
                }

                // 2. Retrieve UserNumber from the authenticated JWT.
                var userNumberClaim =
                    User.FindFirst(ClaimTypes.NameIdentifier)?.Value;

                if (!int.TryParse(userNumberClaim, out int currentUserNumber))
                {
                    return StatusCode(
                        401,
                        "Invalid provider authentication."
                    );
                }

                // 3. Verify that the provider account exists.
                var user = await Database.UserInfos
                    .FirstOrDefaultAsync(x =>
                        x.UserNumber == currentUserNumber);

                if (user == null)
                {
                    return StatusCode(
                        404,
                        "Provider account not found."
                    );
                }

                if (user.LoginAccess == false)
                {
                    return StatusCode(
                        506,
                        "You have been blocked by System. Contact the KaamMitra community."
                    );
                }

                // 4. Find the resource belonging to the authenticated provider.
                // A resource belonging to another provider will not be returned.
                var resource = await Database.ProviderServiceResourcesInfo
                    .FirstOrDefaultAsync(x =>
                        x.ProviderServiceResourcesId ==
                            obj.ProviderServiceResourcesId &&
                        x.UserNumber == currentUserNumber);

                if (resource == null)
                {
                    return StatusCode(
                        404,
                        "Service resource not found or does not belong to the current provider."
                    );
                }

                // 5. Resolve wwwroot.
                var webRootPath = _environment.WebRootPath;

                if (string.IsNullOrWhiteSpace(webRootPath))
                {
                    webRootPath = Path.Combine(
                        Directory.GetCurrentDirectory(),
                        "wwwroot"
                    );
                }

                var fileFolder = Path.Combine(
                    webRootPath,
                    "uploads",
                    "service-resources",
                    "files"
                );

                Directory.CreateDirectory(fileFolder);

                // 6. Generate a unique filename for the new file.
                var fileExtension =
                    Path.GetExtension(obj.ServiceFile.FileName);

                var newFileName = $"{Guid.NewGuid():N}{fileExtension}";

                newPhysicalFilePath = Path.Combine(
                    fileFolder,
                    newFileName
                );

                var newRelativeFilePath =
                    $"/uploads/service-resources/files/{newFileName}";

                // 7. Save the new file to wwwroot.
                await using (var fileStream = new FileStream(
                    newPhysicalFilePath,
                    FileMode.CreateNew,
                    FileAccess.Write,
                    FileShare.None))
                {
                    await obj.ServiceFile.CopyToAsync(fileStream);
                }

                // 8. Keep the old database path until the new file is saved.
                var oldRelativeFilePath = resource.ServiceFile;

                // Update the database with the new relative path.
                resource.ServiceFile = newRelativeFilePath;

                await Database.SaveChangesAsync();

                // The database now points to the new file.
                databaseUpdated = true;

                // 9. Delete the old physical file, if it is inside
                // the expected service-resource files directory.
                try
                {
                    if (!string.IsNullOrWhiteSpace(oldRelativeFilePath))
                    {
                        var normalizedOldPath =
                            oldRelativeFilePath.Replace('\\', '/');

                        const string expectedPrefix =
                            "/uploads/service-resources/files/";

                        if (normalizedOldPath.StartsWith(
                            expectedPrefix,
                            StringComparison.OrdinalIgnoreCase))
                        {
                            var oldFileName =
                                Path.GetFileName(normalizedOldPath);

                            if (!string.IsNullOrWhiteSpace(oldFileName))
                            {
                                var oldPhysicalFilePath = Path.Combine(
                                    fileFolder,
                                    oldFileName
                                );

                                // Do not delete the new file by mistake.
                                if (!string.Equals(
                                    Path.GetFullPath(oldPhysicalFilePath),
                                    Path.GetFullPath(newPhysicalFilePath),
                                    StringComparison.OrdinalIgnoreCase))
                                {
                                    if (System.IO.File.Exists(
                                        oldPhysicalFilePath))
                                    {
                                        System.IO.File.Delete(
                                            oldPhysicalFilePath);
                                    }
                                }
                            }
                        }
                    }
                }
                catch (IOException)
                {
                    // The database update has succeeded.
                    // Keep the new file; do not roll back its physical file.
                    // The old file may need manual cleanup.
                }
                catch (UnauthorizedAccessException)
                {
                    // The database update has succeeded, but the old file
                    // could not be deleted because of filesystem permissions.
                }

                return Ok("Service file updated successfully.");
            }
            catch (Exception)
            {
                // Delete the newly uploaded file only when the database
                // update did not succeed.
                if (!databaseUpdated)
                {
                    try
                    {
                        if (!string.IsNullOrWhiteSpace(newPhysicalFilePath) &&
                            System.IO.File.Exists(newPhysicalFilePath))
                        {
                            System.IO.File.Delete(newPhysicalFilePath);
                        }
                    }
                    catch (IOException)
                    {
                        // Preserve the original operation failure.
                    }
                    catch (UnauthorizedAccessException)
                    {
                        // Preserve the original operation failure.
                    }
                }

                return StatusCode(
                    500,
                    "An error occurred while updating the service resource file."
                );
            }
        }

        [Authorize(Policy = "RequireProviderRole")]
        [HttpPut]
        [Route("updateserviceresourcetitle")]
        public async Task<IActionResult> UpdateServiceResourceTitle(
    [FromBody] ResIdTitleDTO obj)
        {
            try
            {
                // 1. Validate request.
                if (obj == null)
                {
                    return StatusCode(
                        400,
                        "Service resource information is required."
                    );
                }

                if (obj.ProviderServiceResourcesId <= 0)
                {
                    return StatusCode(
                        400,
                        "A valid service resource ID is required."
                    );
                }

                if (string.IsNullOrWhiteSpace(obj.ServiceTitle))
                {
                    return StatusCode(
                        400,
                        "Service title is required."
                    );
                }

                if (!ModelState.IsValid)
                {
                    return StatusCode(
                        400,
                        "The provided data is not in the correct format."
                    );
                }

                // 2. Retrieve authenticated UserNumber from JWT.
                var userNumberClaim =
                    User.FindFirst(ClaimTypes.NameIdentifier)?.Value;

                if (!int.TryParse(userNumberClaim, out int currentUserNumber))
                {
                    return StatusCode(
                        401,
                        "Invalid provider authentication."
                    );
                }

                // 3. Verify provider account.
                var user = await Database.UserInfos
                    .FirstOrDefaultAsync(x =>
                        x.UserNumber == currentUserNumber);

                if (user == null)
                {
                    return StatusCode(
                        404,
                        "Provider account not found."
                    );
                }

                if (user.LoginAccess == false)
                {
                    return StatusCode(
                        506,
                        "You have been blocked by System. Contact the KaamMitra community."
                    );
                }

                // 4. Find the resource owned by this provider.
                var resource = await Database.ProviderServiceResourcesInfo
                    .FirstOrDefaultAsync(x =>
                        x.ProviderServiceResourcesId ==
                            obj.ProviderServiceResourcesId &&
                        x.UserNumber == currentUserNumber);

                if (resource == null)
                {
                    return StatusCode(
                        404,
                        "Service resource not found or does not belong to the current provider."
                    );
                }

                // 5. Update title.
                resource.ServiceTitle = obj.ServiceTitle.Trim();

                await Database.SaveChangesAsync();

                return Ok("Service resource title updated successfully.");
            }
            catch (Exception)
            {
                return StatusCode(
                    500,
                    "An error occurred while updating the service resource title."
                );
            }
        }

        [Authorize(Policy = "RequireProviderUserRole")]
        [HttpPut]
        [Route("updatephonenumbers")]
        public async Task<IActionResult> UpdatePhoneNumbers(
    [FromBody] PhoneNumberDTO obj)
        {
            try
            {
                // 1. Validate request.
                if (obj == null)
                {
                    return StatusCode(
                        400,
                        "Phone number information is required."
                    );
                }

                bool updatePhoneNumber =
                    obj.PhoneNumber != null;

                bool updateWhatsappPhoneNumber =
                    obj.WhatsappPhoneNumber != null;

                if (!updatePhoneNumber && !updateWhatsappPhoneNumber)
                {
                    return StatusCode(
                        400,
                        "Please provide at least one phone number to update."
                    );
                }

                if (!ModelState.IsValid)
                {
                    return StatusCode(
                        400,
                        "The provided phone number format is invalid."
                    );
                }

                // 2. Retrieve UserNumber from the authenticated JWT.
                var userNumberClaim =
                    User.FindFirst(ClaimTypes.NameIdentifier)?.Value;

                if (!int.TryParse(userNumberClaim, out int currentUserNumber))
                {
                    return StatusCode(
                        401,
                        "Invalid user authentication."
                    );
                }

                // 3. Retrieve the authenticated user's account.
                var user = await Database.UserInfos
                    .FirstOrDefaultAsync(
                        x => x.UserNumber == currentUserNumber
                    );

                if (user == null)
                {
                    return StatusCode(
                        404,
                        "User account not found."
                    );
                }

                // 4. Check account access.
                if (user.LoginAccess == false)
                {
                    return StatusCode(
                        506,
                        "You have been blocked by System. Contact the KaamMitra community."
                    );
                }

                // 5. Update only the fields provided.
                if (updatePhoneNumber)
                {
                    if (string.IsNullOrWhiteSpace(obj.PhoneNumber))
                    {
                        return StatusCode(
                            400,
                            "Phone number cannot be empty."
                        );
                    }

                    user.PhoneNumber = obj.PhoneNumber.Trim();
                }

                if (updateWhatsappPhoneNumber)
                {
                    if (string.IsNullOrWhiteSpace(obj.WhatsappPhoneNumber))
                    {
                        return StatusCode(
                            400,
                            "WhatsApp phone number cannot be empty."
                        );
                    }

                    user.WhatsappPhoneNumber =
                        obj.WhatsappPhoneNumber.Trim();
                }

                // 6. Save the changes.
                await Database.SaveChangesAsync();

                if (updatePhoneNumber && updateWhatsappPhoneNumber)
                {
                    return Ok(
                        "Phone number and WhatsApp phone number updated successfully."
                    );
                }

                if (updatePhoneNumber)
                {
                    return Ok(
                        "Phone number updated successfully."
                    );
                }

                return Ok(
                    "WhatsApp phone number updated successfully."
                );
            }
            catch (Exception)
            {
                return StatusCode(
                    500,
                    "An error occurred while updating phone numbers."
                );
            }
        }



        [Authorize(Policy = "RequireProviderUserRole")]
        [HttpPost]
        [RequestSizeLimit(600L * 1024 * 1024)]
        [RequestFormLimits(MultipartBodyLengthLimit = 600L * 1024 * 1024)]
        [Route("addmedia")]
    public async Task<IActionResult> AddMedia([FromForm] SharedMediaDTO obj)
    {
        string? physicalPhotoPath = null;
        string? physicalVideoPath = null;
        string? physicalFilePath = null;

        try
        {
            // 1. Validate the request.
            if (obj == null)
            {
                return StatusCode(400, "Media information is required.");
            }

            if (!ModelState.IsValid)
            {
                return StatusCode(
                    400,
                    "The provided data is not in the correct format."
                );
            }

                bool hasPhoto = obj.ServicePhoto != null &&
                         obj.ServicePhoto.Length > 0;

                bool hasVideo = obj.ServiceVideo != null &&
                                obj.ServiceVideo.Length > 0;

                bool hasFile = obj.ServiceFile != null &&
                               obj.ServiceFile.Length > 0;

                // At least one media file is mandatory.
                if (!hasPhoto && !hasVideo && !hasFile)
                {
                    return StatusCode(
                        523,
                        "At least one photo, video, or file is required."
                    );
                }


                // 2. Get the sender's UserNumber from the JWT.
                var userNumberClaim =
                User.FindFirst(ClaimTypes.NameIdentifier)?.Value;

            if (!int.TryParse(userNumberClaim, out int senderNumber) ||
                senderNumber <= 0)
            {
                return StatusCode(401, "Invalid sender authentication.");
            }

                if (senderNumber==obj.ReceiverNumber) {
                    return StatusCode(525,"Sender number and receiver number same.");
                }

            // 3. Verify the sender's account.
            var sender = await Database.UserInfos
                .FirstOrDefaultAsync(x => x.UserNumber == senderNumber);

            if (sender == null)
            {
                return StatusCode(520, "Sender account not found.");
            }

            if (sender.LoginAccess == false)
            {
                return StatusCode(
                    506,
                    "You have been blocked by System. Contact the KaamMitra community."
                );
            }

            // 4. Verify that the receiver exists.
            var receiver = await Database.UserInfos
                .FirstOrDefaultAsync(x => x.UserNumber == obj.ReceiverNumber);

            if (receiver == null)
            {
                return StatusCode(521, "Receiver account not found.");
            }

            if (receiver.LoginAccess == false)
            {
                return StatusCode(522, "The receiver account is blocked.");
            }

            // 5. Resolve wwwroot.
            var webRootPath = _environment.WebRootPath;

            if (string.IsNullOrWhiteSpace(webRootPath))
            {
                webRootPath = Path.Combine(
                    Directory.GetCurrentDirectory(),
                    "wwwroot"
                );
            }

            if (!Directory.Exists(webRootPath))
            {
                return StatusCode(
                    500,
                    "The server wwwroot folder is not configured."
                );
            }

            // 6. Create media directories.
            var photoFolder = Path.Combine(
                webRootPath, "uploads", "media", "photos");

            var videoFolder = Path.Combine(
                webRootPath, "uploads", "media", "videos");

            var fileFolder = Path.Combine(
                webRootPath, "uploads", "media", "files");

            Directory.CreateDirectory(photoFolder);
            Directory.CreateDirectory(videoFolder);
            Directory.CreateDirectory(fileFolder);

            string? relativePhotoPath = null;
            string? relativeVideoPath = null;
            string? relativeFilePath = null;

            // 7. Save the optional photo.
            if (hasPhoto)
            {
                var photo = obj.ServicePhoto!;


                var extension = Path.GetExtension(photo.FileName)
                    .ToLowerInvariant();

    

                var fileName = $"{Guid.NewGuid():N}{extension}";

                physicalPhotoPath = Path.Combine(photoFolder, fileName);

                await using (var stream = new FileStream(
                    physicalPhotoPath,
                    FileMode.CreateNew,
                    FileAccess.Write,
                    FileShare.None))
                {
                    await photo.CopyToAsync(stream);
                }

                relativePhotoPath = $"/uploads/media/photos/{fileName}";
            }

            // 8. Save the optional video.
            if (hasVideo)
            {
                var video = obj.ServiceVideo!;

             

                var extension = Path.GetExtension(video.FileName)
                    .ToLowerInvariant();

              

                var fileName = $"{Guid.NewGuid():N}{extension}";

                physicalVideoPath = Path.Combine(videoFolder, fileName);

                await using (var stream = new FileStream(
                    physicalVideoPath,
                    FileMode.CreateNew,
                    FileAccess.Write,
                    FileShare.None))
                {
                    await video.CopyToAsync(stream);
                }

                relativeVideoPath = $"/uploads/media/videos/{fileName}";
            }

            // 9. Save the optional file.
            if (hasFile)
            {
                var uploadedFile = obj.ServiceFile!;

             

                var extension = Path.GetExtension(uploadedFile.FileName)
                    .ToLowerInvariant();

                var fileName = $"{Guid.NewGuid():N}{extension}";

                physicalFilePath = Path.Combine(fileFolder, fileName);

                await using (var stream = new FileStream(
                    physicalFilePath,
                    FileMode.CreateNew,
                    FileAccess.Write,
                    FileShare.None))
                {
                    await uploadedFile.CopyToAsync(stream);
                }

                relativeFilePath = $"/uploads/media/files/{fileName}";
            }

            // 10. Create the database record.
            var sharedMedia = new SharedMediaModel
            {
                MediaDescription = obj.MediaDescription.Trim(),

                ServicePhoto = relativePhotoPath ?? string.Empty,
                ServiceVideo = relativeVideoPath ?? string.Empty,
                ServiceFile = relativeFilePath ?? string.Empty,

                CreatedAt = DateTime.UtcNow,

                // Never trust a sender ID supplied by the client.
                SenderNumber = senderNumber,

                ReceiverNumber = obj.ReceiverNumber
            };

            await Database.SharedMediaInfos.AddAsync(sharedMedia);

            await Database.SaveChangesAsync();

            // 11. Return the new record ID.
            return StatusCode(
                201,
                new
                {
                    message = "Media shared successfully.",
                    sharedMediaId = sharedMedia.SharedMediaId
                }
            );
        }
        catch (Exception)

        {
            // Clean up uploaded files if saving the operation fails.
            try
            {
                if (!string.IsNullOrWhiteSpace(physicalPhotoPath) &&
                    System.IO.File.Exists(physicalPhotoPath))
                {
                    System.IO.File.Delete(physicalPhotoPath);
                }

                if (!string.IsNullOrWhiteSpace(physicalVideoPath) &&
                    System.IO.File.Exists(physicalVideoPath))
                {
                    System.IO.File.Delete(physicalVideoPath);
                }

                if (!string.IsNullOrWhiteSpace(physicalFilePath) &&
                    System.IO.File.Exists(physicalFilePath))
                {
                    System.IO.File.Delete(physicalFilePath);
                }
            }
            catch
            {
                  
            }

            return StatusCode(
                500,
                "An error occurred while sharing media. Please try again."
            );


        }


    }

        [Authorize(Policy = "RequireProviderUserRole")]
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

                if (userExists==null)
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
                    .Where(x =>
                        x.SenderNumber == UserNumber ||
                        x.ReceiverNumber == UserNumber)
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
    .FirstOrDefault() ?? string.Empty,

                        SenderPhoto = Database.UserInfos
    .Where(u => u.UserNumber == x.SenderNumber)
    .Select(u => (u.Photo))
    .FirstOrDefault() ?? string.Empty,

                        ReceiverPhoto = Database.UserInfos
    .Where(u => u.UserNumber == x.ReceiverNumber)
    .Select(u => (u.Photo))
    .FirstOrDefault() ?? string.Empty,
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

        [Authorize(Policy = "RequireProviderUserRole")]
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

                // 6. Only the sender can delete the shared media
                if (SharedMedia.SenderNumber != UserNumber)
                {
                    return StatusCode(
                        403,
                        "You are not authorized to delete this shared media."
                    );
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


        [Authorize(Policy = "RequireProviderRole")]
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
                            x.ProviderServiceResourcesId == obj.ProviderServiceResourcesId &&
                            x.UserNumber == userNumber);

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
                        x.ProviderServiceId == obj.ProviderServiceId &&
                        x.UserNumber == userNumber);

                if (serviceData == null)
                    return StatusCode(404, "Registered service is not present.");

                var serviceResources = await Database.ProviderServiceResourcesInfo
                    .Where(x => x.ProviderServiceId == obj.ProviderServiceId &&
                                x.UserNumber == userNumber)
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

        [Authorize(Policy = "RequireProviderRole")]
        [HttpPut]
        [Route("changestatus")]
        public async Task<IActionResult> ChangeStatus()
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

                // Toggle the current status.
                user.Status = user.Status == true ? false : true;

                await Database.SaveChangesAsync();

                return Ok();
            }
            catch (Exception)
            {
                return StatusCode(
                    500,
                    "An error occurred while updating your status.");
            }
        }











    }

}
