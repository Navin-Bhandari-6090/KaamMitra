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
                            obj.Email.Trim()
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
                            obj.Email
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

        //   [Authorize(Policy = "RequireProviderRole")]
        //   [HttpPut]
        //   [Route("updateservicedocument")]
        //   public async Task<IActionResult> UpdateServiceFile(
        //[FromBody] UpdateServiceFile obj)
        //   {
        //       try
        //       {
        //           if (!ModelState.IsValid)
        //           {
        //               return BadRequest("Data are not in correct format.");
        //           }

        //           // Check user
        //           var userData = await Database.UserInfos
        //               .FirstOrDefaultAsync(x => x.Email == obj.Email);

        //           if (userData == null)
        //           {
        //               return NotFound("User not found.");
        //           }

        //           // Check service belongs to this user
        //           var serviceData = await Database.ProviderServiceInfo
        //               .FirstOrDefaultAsync(x =>
        //                   x.Email == obj.Email &&
        //                   x.ProviderServiceId == obj.ProviderServiceId);

        //           if (serviceData == null)
        //           {
        //               return NotFound("No service available.");
        //           }

        //           // -----------------------------------------
        //           // Base64 string -> byte[]
        //           // -----------------------------------------

        //           byte[] documentBytes;

        //           try
        //           {
        //               documentBytes = Convert.FromBase64String(
        //                   obj.ServiceDocument
        //               );
        //           }
        //           catch (FormatException)
        //           {
        //               return BadRequest(
        //                   "ServiceDocument is not a valid Base64 string."
        //               );
        //           }

        //           // -----------------------------------------
        //           // Update byte[] column
        //           // -----------------------------------------

        //           serviceData.ServiceDocument = documentBytes;

        //           await Database.SaveChangesAsync();

        //           // -----------------------------------------
        //           // byte[] -> Base64 string for response
        //           // -----------------------------------------

        //           //var response = new UpdateServiceFile
        //           //{
        //           //    ProviderServiceId = serviceData.ProviderServiceId,
        //           //    ServiceDocument =
        //           //        Convert.ToBase64String(serviceData.ServiceDocument),
        //           //    Email = serviceData.Email
        //           //};

        //           return Ok();
        //       }
        //       catch (Exception ex)
        //       {
        //           return StatusCode(500, ex.Message);
        //       }
        //   }

        //   [Authorize(Policy = "RequireProviderRole")]
        //   [HttpPut]
        //   [Route("updateserviceresources")]
        //   public async Task<IActionResult> UpdateServiceResources(
        // [FromBody] UpdateServiceResources obj)
        //   {
        //       try
        //       {
        //           if (!ModelState.IsValid)
        //           {
        //               return BadRequest("Data are not in correct format.");
        //           }

        //           // Check user
        //           var userData = await Database.UserInfos
        //               .FirstOrDefaultAsync(x => x.Email == obj.Email);

        //           if (userData == null)
        //           {
        //               return NotFound("User not found.");
        //           }

        //           // Find current user's service resource
        //           var serviceData = await Database.ProviderServiceResourcesInfo
        //               .FirstOrDefaultAsync(x =>
        //                   x.Email == obj.Email &&
        //                   x.ProviderServiceResourcesId ==
        //                       obj.ProviderServiceResourcesId);

        //           if (serviceData == null)
        //           {
        //               return NotFound(
        //                   "No service registered for the current user.");
        //           }

        //           // -----------------------------------------
        //           // Base64 string -> byte[] for photo
        //           // -----------------------------------------

        //           byte[] photoBytes;

        //           try
        //           {
        //               photoBytes = Convert.FromBase64String(
        //                   obj.ServicePhoto
        //               );
        //           }
        //           catch (FormatException)
        //           {
        //               return BadRequest(
        //                   "ServicePhoto is not a valid Base64 string."
        //               );
        //           }

        //           // -----------------------------------------
        //           // Base64 string -> byte[] for video
        //           // -----------------------------------------

        //           byte[] videoBytes;

        //           try
        //           {
        //               videoBytes = Convert.FromBase64String(
        //                   obj.ServiceVideo
        //               );
        //           }
        //           catch (FormatException)
        //           {
        //               return BadRequest(
        //                   "ServiceVideo is not a valid Base64 string."
        //               );
        //           }

        //           // -----------------------------------------
        //           // Update database byte[] columns
        //           // -----------------------------------------

        //           serviceData.ServicePhoto = photoBytes;
        //           serviceData.ServiceVideo = videoBytes;

        //           await Database.SaveChangesAsync();

        //           // -----------------------------------------
        //           // Return updated data
        //           // byte[] -> Base64 string
        //           // -----------------------------------------

        //           //var response = new UpdateServiceResources
        //           //{
        //           //    ProviderServiceResourcesId =
        //           //        serviceData.ProviderServiceResourcesId,

        //           //    ServicePhoto =
        //           //        Convert.ToBase64String(serviceData.ServicePhoto),

        //           //    ServiceVideo =
        //           //        Convert.ToBase64String(serviceData.ServiceVideo),

        //           //    ProviderServiceId =
        //           //        serviceData.ProviderServiceId,

        //           //    Email =
        //           //        serviceData.Email
        //           //};

        //           return Ok();
        //       }
        //       catch (Exception ex)
        //       {
        //           return StatusCode(500, ex.Message);
        //       }
        //   }





        //   [Authorize(Policy = "RequireProviderUserRole")]
        //   [HttpPost]
        //   [Route("getservicephotoinfo")]
        //   public async Task<IActionResult> GetServicePhotoInfo(
        //[FromBody] ProviderServiceEmailServiceNameModel obj)
        //   {
        //       try
        //       {
        //           // 1. Check whether user exists
        //           var userData = await Database.UserInfos
        //               .FirstOrDefaultAsync(x => x.Email == obj.Email);

        //           if (userData == null)
        //           {
        //               return NotFound("No user found.");
        //           }

        //           // 2. Get service + resource information
        //           var servicePhotos = await Database.ProviderServiceInfo
        //               .Where(x =>
        //                   x.Email == obj.Email &&
        //                   x.ServiceName == obj.ServiceName)
        //               .SelectMany(
        //                   service => service.ProviderServicesResources,
        //                   (service, resource) => new SendServicePhoto
        //                   {
        //                       ServiceName = service.ServiceName,

        //                       ProviderServiceResourcesId =
        //                           resource.ProviderServiceResourcesId,

        //                       // byte[] -> Base64 string
        //                       ServicePhoto =
        //                           Convert.ToBase64String(resource.ServicePhoto),

        //                       ProviderServiceId =
        //                           resource.ProviderServiceId
        //                   })
        //               .ToListAsync();

        //           // 3. Check whether resources exist
        //           if (servicePhotos.Count == 0)
        //           {
        //               return NotFound(
        //                   "No service resources found for the current user.");
        //           }

        //           // 4. Return Base64 strings
        //           return Ok(servicePhotos);
        //       }
        //       catch (Exception ex)
        //       {
        //           return StatusCode(500, ex.Message);
        //       }
        //   }


        //   [Authorize(Policy = "RequireProviderUserRole")]
        //   [HttpPost]
        //   [Route("getproviderregisterserviceinfo")]
        //   public async Task<IActionResult> GetProviderServiceInfo(
        //       [FromBody] UserEmailInfoModel obj)
        //   {
        //       try
        //       {
        //           var user_data = await Database.UserInfos
        //               .FirstOrDefaultAsync(x => x.Email == obj.Email);

        //           if (user_data == null)
        //           {
        //               return NotFound("No user found.");
        //           }

        //           var Service_Data = await Database.ProviderServiceInfo
        //               .Where(x => x.Email == obj.Email)
        //               .Select(x => new
        //               {
        //                   ServiceName = x.ServiceName
        //               })
        //               .OrderBy(x => x.ServiceName)
        //               .ToListAsync();

        //           if (Service_Data.Count > 0)
        //           {
        //               return Ok(Service_Data);
        //           }
        //           else
        //           {
        //               return NotFound("No service registered for current user.");
        //           }
        //       }
        //       catch (Exception ex)
        //       {
        //           return StatusCode(500, ex.Message);
        //       }
        //   }


        //   [Authorize(Policy = "RequireProviderUserRole")]
        //   [HttpPost]
        //   [Route("getservicefileinfo")]
        //   public async Task<IActionResult> GetServiceFileInfo(
        //  [FromBody] ProviderServiceEmailServiceNameModel obj)
        //   {
        //       try
        //       {
        //           // 1. Validate request
        //           if (!ModelState.IsValid)
        //           {
        //               return BadRequest(
        //                   "The provided data is not in correct format.");
        //           }

        //           // 2. Check whether user exists
        //           var userData = await Database.UserInfos
        //               .FirstOrDefaultAsync(x => x.Email == obj.Email);

        //           if (userData == null)
        //           {
        //               return NotFound("No user found.");
        //           }

        //           // 3. Get service information
        //           var serviceFiles = await Database.ProviderServiceInfo
        //               .Where(x =>
        //                   x.Email == obj.Email &&
        //                   x.ServiceName == obj.ServiceName)
        //               .Select(x => new
        //               {
        //                   x.ProviderServiceId,
        //                   x.ServiceName,
        //                   x.ServiceDocument
        //               })
        //               .ToListAsync();

        //           // 4. Check whether service exists
        //           if (serviceFiles.Count == 0)
        //           {
        //               return NotFound(
        //                   "No service found for the current user.");
        //           }

        //           // 5. Convert byte[] -> Base64 string
        //           var response = serviceFiles
        //               .Select(x => new ProviderServices
        //               {
        //                   ProviderServiceId = x.ProviderServiceId,
        //                   ServiceName = x.ServiceName,

        //                   ServiceDocument =
        //                       x.ServiceDocument != null &&
        //                       x.ServiceDocument.Length > 0
        //                           ? Convert.ToBase64String(x.ServiceDocument)
        //                           : string.Empty,

        //                   Email = obj.Email
        //               })
        //               .ToList();

        //           // 6. Return Base64 string
        //           return Ok(response);
        //       }
        //       catch (Exception ex)
        //       {
        //           return StatusCode(500, ex.Message);
        //       }
        //   }





    }
}
