using application.Data;
using application.Models;
using application.Models.DTOModels;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
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
                var user_data = await Database.UserInfos.FirstOrDefaultAsync(x => x.Email == obj.Email);
                if (user_data != null)
                {
                    Console.WriteLine("console emssage");
                    return Ok(user_data);

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


                // =========================================================
                // 2. Find user
                // =========================================================

                var userData = await Database.UserInfos
                    .FirstOrDefaultAsync(x => x.Email == obj.Email);

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

                return StatusCode(
                    200,
                    new
                    {
                        Message = "Profile photo updated successfully.",
                        Email = userData.Email,
                        Photo = userData.Photo
                    }
                );
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
    [FromForm] ProviderServices obj)
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
                            x.Email == obj.Email &&
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


                //Finding user
                var User_Data = await Database.UserInfos.FirstOrDefaultAsync(x => x.Email == obj.Email);



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

                        Email =
                            obj.Email.Trim(),

                        UserNumber=User_Data.UserNumber
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


                // =========================================================
                // 18. Success
                // =========================================================

                //return StatusCode(
                //    200,
                //    new
                //    {
                //        Message =
                //            "Service added successfully.",

                //        ProviderServiceId =
                //            service.ProviderServiceId,

                //        ServiceName =
                //            service.ServiceName,

                //        ServiceDocument =
                //            service.ServiceDocument,

                //        Email =
                //            service.Email
                //    }
                //);

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
                var user_data = await Database.UserInfos.FirstOrDefaultAsync(x => x.Email == obj.Email);
                if (user_data != null)
                {
                    var Service_Data = await Database.ServiceInfos.OrderBy(x => x.ServiceName).ToListAsync();
                    return Ok(Service_Data);

                }
                return StatusCode(500, "No user found.");
            }
            catch (Exception ex)
            {
                return StatusCode(501, ex.Message);
            }
        }



[Authorize(Policy = "RequireProviderRole")]
[HttpPost]
[RequestSizeLimit(2_147_483_648)]
[RequestFormLimits(MultipartBodyLengthLimit = 2_147_483_648)]
[Route("addserviceresources")]
public async Task<IActionResult> AddServiceResources(
    [FromForm] ProviderServiceResources obj)
        {
            string? physicalPhotoPath = null;
            string? physicalVideoPath = null;

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
                // 4. Validate Photo
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
                // 5. Validate Video
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
                // 6. Validate Photo Extension
                // =========================================================

                if (string.IsNullOrWhiteSpace(obj.PhotoExtension))
                {
                    return StatusCode(
                        400,
                        "Photo extension is required."
                    );
                }

                var photoExtension =
                    obj.PhotoExtension
                        .Trim()
                        .ToLowerInvariant()
                        .TrimStart('.');


                // =========================================================
                // 7. Validate Video Extension
                // =========================================================

                if (string.IsNullOrWhiteSpace(obj.VideoExtension))
                {
                    return StatusCode(
                        400,
                        "Video extension is required."
                    );
                }

                var videoExtension =
                    obj.VideoExtension
                        .Trim()
                        .ToLowerInvariant()
                        .TrimStart('.');


                // =========================================================
                // 8. Allowed Photo Extensions
                // =========================================================

                var allowedPhotoExtensions =
                    new HashSet<string>(
                        StringComparer.OrdinalIgnoreCase)
                    {
                "jpg",
                "jpeg",
                "png"
                    };


                if (!allowedPhotoExtensions.Contains(
                    photoExtension))
                {
                    return StatusCode(
                        400,
                        "Invalid photo format. Only JPG, JPEG and PNG are allowed."
                    );
                }


                // =========================================================
                // 9. Allowed Video Extensions
                // =========================================================

                var allowedVideoExtensions =
                    new HashSet<string>(
                        StringComparer.OrdinalIgnoreCase)
                    {
                "mp4"
                    };


                if (!allowedVideoExtensions.Contains(
                    videoExtension))
                {
                    return StatusCode(
                        400,
                        "Invalid video format. Only MP4 is allowed."
                    );
                }


                // =========================================================
                // 10. Validate Uploaded Photo Filename
                // =========================================================

                var uploadedPhotoExtension =
                    Path.GetExtension(
                        obj.ServicePhoto.FileName)
                    .TrimStart('.')
                    .ToLowerInvariant();


                if (!string.Equals(
                        uploadedPhotoExtension,
                        photoExtension,
                        StringComparison.OrdinalIgnoreCase))
                {
                    return StatusCode(
                        400,
                        "Photo extension does not match the uploaded photo."
                    );
                }


                // =========================================================
                // 11. Validate Uploaded Video Filename
                // =========================================================

                var uploadedVideoExtension =
                    Path.GetExtension(
                        obj.ServiceVideo.FileName)
                    .TrimStart('.')
                    .ToLowerInvariant();


                if (!string.Equals(
                        uploadedVideoExtension,
                        videoExtension,
                        StringComparison.OrdinalIgnoreCase))
                {
                    return StatusCode(
                        400,
                        "Video extension does not match the uploaded video."
                    );
                }


                // =========================================================
                // 12. Check Service
                // =========================================================

                var serviceData =
                    await Database.ProviderServiceInfo
                        .FirstOrDefaultAsync(x =>
                            x.ProviderServiceId ==
                                obj.ProviderServiceId
                            &&
                            x.Email == obj.Email
                        );


                if (serviceData == null)
                {
                    return StatusCode(
                        404,
                        "Service not present with that ID or current user service ID mismatch."
                    );
                }


                // =========================================================
                // 13. Main Folder
                // =========================================================

                const string resourceFolder =
                    "uploads/service-resources";


                // =========================================================
                // 14. Photo Folder
                // =========================================================

                const string photoFolder =
                    "uploads/service-resources/photos";


                // =========================================================
                // 15. Video Folder
                // =========================================================

                const string videoFolder =
                    "uploads/service-resources/videos";


                // =========================================================
                // 16. Get wwwroot
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
                // 17. Physical Photo Folder
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
                // 18. Physical Video Folder
                // =========================================================

                var physicalVideoFolderPath =
                    Path.Combine(
                        webRootPath,
                        videoFolder.Replace(
                            '/',
                            Path.DirectorySeparatorChar
                        )
                    );


                // =========================================================
                // 19. Create Photo Folder
                // =========================================================

                if (!Directory.Exists(
                    physicalPhotoFolderPath))
                {
                    Directory.CreateDirectory(
                        physicalPhotoFolderPath
                    );
                }


                // =========================================================
                // 20. Create Video Folder
                // =========================================================

                if (!Directory.Exists(
                    physicalVideoFolderPath))
                {
                    Directory.CreateDirectory(
                        physicalVideoFolderPath
                    );
                }


                // =========================================================
                // 21. Generate Unique Photo Filename
                // =========================================================

                var photoFileName =
                    $"{Guid.NewGuid():N}.{photoExtension}";


                // =========================================================
                // 22. Generate Unique Video Filename
                // =========================================================

                var videoFileName =
                    $"{Guid.NewGuid():N}.{videoExtension}";


                // =========================================================
                // 23. Physical Photo Path
                // =========================================================

                physicalPhotoPath =
                    Path.Combine(
                        physicalPhotoFolderPath,
                        photoFileName
                    );


                // =========================================================
                // 24. Physical Video Path
                // =========================================================

                physicalVideoPath =
                    Path.Combine(
                        physicalVideoFolderPath,
                        videoFileName
                    );


                // =========================================================
                // 25. Save Photo
                // =========================================================

                await using (
                    var photoStream =
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
                // 26. Save Video
                // =========================================================

                try
                {
                    await using (
                        var videoStream =
                            new FileStream(
                                physicalVideoPath,
                                FileMode.CreateNew,
                                FileAccess.Write,
                                FileShare.None))
                    {
                        await obj.ServiceVideo
                            .CopyToAsync(videoStream);
                    }
                }
                catch
                {
                    // Delete photo if video saving fails.

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
                // 27. Database Photo Path
                // =========================================================

                var relativePhotoPath =
                    $"/{photoFolder}/{photoFileName}";


                // =========================================================
                // 28. Database Video Path
                // =========================================================

                var relativeVideoPath =
                    $"/{videoFolder}/{videoFileName}";



                //Finding user
                var User_Data = await Database.UserInfos.FirstOrDefaultAsync(x => x.Email == obj.Email);


                // =========================================================
                // 29. Create Entity
                // =========================================================



                var serviceResource =
                    new ProviderRegisterServiceResources
                    {
                        ServicePhoto =
                            relativePhotoPath,

                        ServiceVideo =
                            relativeVideoPath,

                        ProviderServiceId =
                            obj.ProviderServiceId,

                        Email =
                            obj.Email,

                        UserNumber=User_Data.UserNumber
                    };


                // =========================================================
                // 30. Add Entity
                // =========================================================

                await Database
                    .ProviderServiceResourcesInfo
                    .AddAsync(serviceResource);


                // =========================================================
                // 31. Save Database
                // =========================================================

                try
                {
                    await Database.SaveChangesAsync();
                }
                catch
                {
                    // Delete photo.

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


                    // Delete video.

                    try
                    {
                        if (System.IO.File.Exists(
                            physicalVideoPath))
                        {
                            System.IO.File.Delete(
                                physicalVideoPath
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
                // 32. Success
                // =========================================================

                //return StatusCode(
                //    200,
                //    new
                //    {
                //        Message =
                //            "Service resources added successfully.",

                //        ProviderServiceResourcesId =
                //            serviceResource
                //                .ProviderServiceResourcesId,

                //        ProviderServiceId =
                //            serviceResource
                //                .ProviderServiceId,

                //        ServicePhoto =
                //            serviceResource
                //                .ServicePhoto,

                //        ServiceVideo =
                //            serviceResource
                //                .ServiceVideo,

                //        PhotoExtension =
                //            photoExtension,

                //        VideoExtension =
                //            videoExtension,

                //        Email =
                //            serviceResource.Email
                //    }
                //);

                return Ok();
            }
            catch (Exception ex)
            {
                // =========================================================
                // 33. Cleanup Unexpected Error
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


                try
                {
                    if (!string.IsNullOrWhiteSpace(
                            physicalVideoPath) &&
                        System.IO.File.Exists(
                            physicalVideoPath))
                    {
                        System.IO.File.Delete(
                            physicalVideoPath
                        );
                    }
                }
                catch
                {
                    // Ignore cleanup failure.
                }


                // =========================================================
                // 34. Server Error
                // =========================================================

                return StatusCode(
                    500,
                    $"An error occurred while adding service resources: {ex.Message}"
                );
            }
        }



        private string HashPasswordUpdate(string password)
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

        [Authorize(Policy = "RequireProviderUserRole")]
        [HttpPut]
        [Route("updatepassword")]
        public async Task<IActionResult> UpdatePassword([FromBody] LoginModel obj)
        {

            try
            {
                var user_data = await Database.UserInfos.FirstOrDefaultAsync(x => x.Email == obj.Email);
                if (user_data != null)
                {

                    user_data.Password = HashPasswordUpdate(obj.Password);
                    await Database.SaveChangesAsync();
                    return Ok();

                }
                return StatusCode(500, "Database error while getting user info for profile screen using username.");
            }
            catch (Exception ex)
            {
                return StatusCode(501, ex.Message);
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

                var userData = await Database.UserInfos
                    .FirstOrDefaultAsync(x =>
                        x.Email == obj.Email);

                if (userData == null)
                {
                    return StatusCode(
                        404,
                        "User not found."
                    );
                }

                // =========================================================
                // 4. Check service belongs to this user
                // =========================================================

                var serviceData =
                    await Database.ProviderServiceInfo
                        .FirstOrDefaultAsync(x =>
                            x.Email == obj.Email &&
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
                        x.Email == obj.Email);

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
                            x.Email == obj.Email);

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
                // 6. Check user
                // =========================================================

                var userData = await Database.UserInfos
                    .FirstOrDefaultAsync(x =>
                        x.Email == obj.Email);

                if (userData == null)
                {
                    return StatusCode(
                        404,
                        "User not found."
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
                            x.Email == obj.Email
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

                // =========================================================
                // 4. Check user
                // =========================================================

                var userData = await Database.UserInfos
                    .FirstOrDefaultAsync(
                        x => x.Email == obj.Email
                    );

                if (userData == null)
                {
                    return StatusCode(
                        404,
                        "No user found."
                    );
                }

                // =========================================================
                // 5. Get service resources
                // =========================================================

                var servicePhotos =
                    await Database.ProviderServiceInfo
                        .Where(x =>
                            x.Email == obj.Email &&
                            x.ServiceName == obj.ServiceName
                        )
                        .SelectMany(
                            service => service.ProviderServicesResources,
                            (service, resource) =>
                                new SendServicePhoto
                                {
                                    ServiceName =
                                        service.ServiceName,

                                    ProviderServiceResourcesId =
                                        resource.ProviderServiceResourcesId,

                                    ServicePhoto =
                                        resource.ServicePhoto,

                                    ProviderServiceId =
                                        resource.ProviderServiceId
                                }
                        )
                        .ToListAsync();

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
           [Route("getproviderregisterserviceinfo")]
           public async Task<IActionResult> GetProviderServiceInfo(
               [FromBody] UserEmailInfoModel obj)
           {
               try
               {
                   var user_data = await Database.UserInfos
                       .FirstOrDefaultAsync(x => x.Email == obj.Email);

                   if (user_data == null)
                   {
                       return NotFound("No user found.");
                   }

                   var Service_Data = await Database.ProviderServiceInfo
                       .Where(x => x.Email == obj.Email)
                       .Select(x => new
                       {
                           ServiceName = x.ServiceName
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

                // ============================================================
                // 4. CHECK USER
                // ============================================================

                var userData = await Database.UserInfos
                    .FirstOrDefaultAsync(
                        x => x.Email == obj.Email
                    );

                if (userData == null)
                {
                    return StatusCode(
                        404,
                        "No user found."
                    );
                }

                // ============================================================
                // 5. GET SERVICE FILE
                // ============================================================

                var serviceFiles = await Database.ProviderServiceInfo
                    .Where(x =>
                        x.Email == obj.Email &&
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

                // =========================================================
                // 4. Check user
                // =========================================================

                var userData = await Database.UserInfos
                    .FirstOrDefaultAsync(
                        x => x.Email == obj.Email
                    );

                if (userData == null)
                {
                    return StatusCode(
                        404,
                        "No user found."
                    );
                }

                // =========================================================
                // 5. Get service videos
                // =========================================================

                var serviceVideos =
                    await Database.ProviderServiceInfo
                        .Where(x =>
                            x.Email == obj.Email &&
                            x.ServiceName == obj.ServiceName
                        )
                        .SelectMany(
                            service => service.ProviderServicesResources,
                            (service, resource) =>
                                new SendResVideoDTO
                                {
                                    ServiceName =
                                        service.ServiceName,

                                    ProviderServiceResourcesId =
                                        resource.ProviderServiceResourcesId,

                                    ServiceVideo =
                                        resource.ServiceVideo,

                                    ProviderServiceId =
                                        resource.ProviderServiceId
                                }
                        )
                        .ToListAsync();

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

                var User_Data = await Database.UserInfos.FirstOrDefaultAsync(x=>x.Email==obj.OldEmail);
                if (User_Data != null)
                {
                    User_Data.Email = obj.NewEmail;
                    await Database.SaveChangesAsync();
                    return Ok("Update success.");
                }
                else {
                    return StatusCode(502,"User doesn't exist.Old email doesn't match.");
                }

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

                var User_Data = await Database.UserInfos.FirstOrDefaultAsync(x => x.Email == obj.Email);
                if (User_Data != null)
                {
                    User_Data.Latitude = obj.Latitude;
                    User_Data.Longitude = obj.Longitude;
                    await Database.SaveChangesAsync();
                    return Ok("Location Update success.");
                }
                else
                {
                    return StatusCode(502, "User doesn't exist.Email doesn't match.");
                }

            }
            catch (Exception e)
            {

                return StatusCode(500, "Exception caught while updating email.");
            }
        }








    }
}
