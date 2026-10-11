using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace application.Migrations
{
    /// <inheritdoc />
    public partial class up23 : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_BookingInfos_UserInfos_UserNumber",
                table: "BookingInfos");

            migrationBuilder.DropForeignKey(
                name: "FK_ProviderServiceInfo_UserInfos_UserNumber",
                table: "ProviderServiceInfo");

            migrationBuilder.DropForeignKey(
                name: "FK_ProviderServiceResourcesInfo_ProviderServiceInfo_ProviderSe~",
                table: "ProviderServiceResourcesInfo");

            migrationBuilder.DropForeignKey(
                name: "FK_ProviderServiceResourcesInfo_UserInfos_UserNumber",
                table: "ProviderServiceResourcesInfo");

            migrationBuilder.DropIndex(
                name: "IX_ProviderServiceResourcesInfo_ProviderServiceId",
                table: "ProviderServiceResourcesInfo");

            migrationBuilder.DropIndex(
                name: "IX_ProviderServiceResourcesInfo_UserNumber",
                table: "ProviderServiceResourcesInfo");

            migrationBuilder.DropIndex(
                name: "IX_ProviderServiceInfo_UserNumber",
                table: "ProviderServiceInfo");

            migrationBuilder.DropIndex(
                name: "IX_BookingInfos_UserNumber",
                table: "BookingInfos");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateIndex(
                name: "IX_ProviderServiceResourcesInfo_ProviderServiceId",
                table: "ProviderServiceResourcesInfo",
                column: "ProviderServiceId");

            migrationBuilder.CreateIndex(
                name: "IX_ProviderServiceResourcesInfo_UserNumber",
                table: "ProviderServiceResourcesInfo",
                column: "UserNumber");

            migrationBuilder.CreateIndex(
                name: "IX_ProviderServiceInfo_UserNumber",
                table: "ProviderServiceInfo",
                column: "UserNumber");

            migrationBuilder.CreateIndex(
                name: "IX_BookingInfos_UserNumber",
                table: "BookingInfos",
                column: "UserNumber");

            migrationBuilder.AddForeignKey(
                name: "FK_BookingInfos_UserInfos_UserNumber",
                table: "BookingInfos",
                column: "UserNumber",
                principalTable: "UserInfos",
                principalColumn: "UserNumber",
                onDelete: ReferentialAction.Cascade);

            migrationBuilder.AddForeignKey(
                name: "FK_ProviderServiceInfo_UserInfos_UserNumber",
                table: "ProviderServiceInfo",
                column: "UserNumber",
                principalTable: "UserInfos",
                principalColumn: "UserNumber",
                onDelete: ReferentialAction.Cascade);

            migrationBuilder.AddForeignKey(
                name: "FK_ProviderServiceResourcesInfo_ProviderServiceInfo_ProviderSe~",
                table: "ProviderServiceResourcesInfo",
                column: "ProviderServiceId",
                principalTable: "ProviderServiceInfo",
                principalColumn: "ProviderServiceId",
                onDelete: ReferentialAction.Cascade);

            migrationBuilder.AddForeignKey(
                name: "FK_ProviderServiceResourcesInfo_UserInfos_UserNumber",
                table: "ProviderServiceResourcesInfo",
                column: "UserNumber",
                principalTable: "UserInfos",
                principalColumn: "UserNumber",
                onDelete: ReferentialAction.Cascade);
        }
    }
}
